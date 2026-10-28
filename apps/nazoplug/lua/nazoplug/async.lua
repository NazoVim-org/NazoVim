-- Coroutine bridge for subprocess work.
--
-- Pool workers (see pool.lua) register themselves here; helpers detect that
-- context and park the worker coroutine on a vim.system process instead of
-- blocking the event loop. Completion callbacks run through vim.schedule so
-- they are processed while the caller sits in vim.wait.

local M = {}

local workers = {} -- [co] = true
local waiting = {} -- [co] = { proc, done }
local completions = {} -- [co] = fn(success, ...)

function M.attach(co)
	workers[co] = true
end

function M.detach(co)
	workers[co] = nil
end

function M.in_worker()
	local co = coroutine.running()
	return co ~= nil and workers[co] == true
end

-- Run a subprocess and wait for it. Inside a worker coroutine the process is
-- spawned asynchronously and the worker parks until it exits; outside, this
-- blocks with process:wait() like a plain vim.system call.
-- Returns result_table, nil on success or nil, error_message.
function M.system(command, opts)
	opts = opts or {}
	local spawn_opts = {
		cwd = opts.cwd,
		text = true,
		timeout = opts.timeout or 60000,
	}
	if not M.in_worker() then
		local ok, process = pcall(vim.system, command, spawn_opts)
		if not ok then
			return nil, tostring(process)
		end
		return process:wait(), nil
	end
	local co = coroutine.running()
	local waiter = { done = false }
	waiting[co] = waiter
	local ok, proc = pcall(vim.system, command, spawn_opts, function()
		waiter.done = true
		vim.schedule(function()
			M.wake(co)
		end)
	end)
	if not ok then
		waiting[co] = nil
		return nil, tostring(proc)
	end
	waiter.proc = proc
	coroutine.yield()
	waiting[co] = nil
	-- wait() returns immediately once on_exit has fired; result() does not
	-- exist on nvim's Process object in 0.12.
	return proc:wait(), nil
end

-- Resume a parked worker whose process finished; delivers the task's final
-- return values to its registered completion callback.
function M.wake(co)
	local waiter = waiting[co]
	if not waiter or not waiter.done then
		return
	end
	waiting[co] = nil
	local success, r1, r2 = coroutine.resume(co)
	if coroutine.status(co) == "dead" then
		local cb = completions[co]
		completions[co] = nil
		if cb then
			cb(success, r1, r2)
		end
	end
end

function M.on_complete(co, cb)
	completions[co] = cb
end

-- Abort a parked worker: kill its process and let it unwind as an error.
function M.abort(co)
	local waiter = waiting[co]
	if not waiter then
		return
	end
	if waiter.proc then
		pcall(function()
			waiter.proc:kill("term")
		end)
	end
	waiter.done = true
	waiting[co] = nil
	local cb = completions[co]
	completions[co] = nil
	local success, r1, r2 = coroutine.resume(co)
	if coroutine.status(co) == "dead" and cb then
		cb(success, r1, r2)
	end
end

return M
