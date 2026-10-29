local passed, failed = 0, 0

local function test(name, fn)
	local ok, err = xpcall(fn, debug.traceback)
	if ok then
		passed = passed + 1
		io.write("ok   " .. name .. "\n")
	else
		failed = failed + 1
		io.write("FAIL " .. name .. "\n" .. tostring(err) .. "\n")
	end
end

local function eq(actual, expected, label)
	if not vim.deep_equal(actual, expected) then
		error(string.format("%s: expected %s, got %s", label or "value", vim.inspect(expected), vim.inspect(actual)), 2)
	end
end

local function truthy(value, label)
	if not value then
		error((label or "value") .. " is not truthy", 2)
	end
	return value
end

local P = require("nazoplug.pool")
local A = require("nazoplug.async")
local G = require("nazoplug.git")

test("pool runs sync tasks and collects results", function()
	local results = P.run({
		function()
			return true
		end,
		function()
			return false, "boom"
		end,
		function()
			return true, nil, "extra"
		end,
	})
	eq(#results, 3)
	eq(results[1].ok, true)
	eq(results[2].ok, false)
	eq(results[2].err, "boom")
	eq(results[3].extra, "extra")
end)

test("pool runs async subprocess tasks concurrently", function()
	local order = {}
	local running, peak = 0, 0
	local tasks = {}
	for i = 1, 6 do
		tasks[i] = function()
			running = running + 1
			peak = math.max(peak, running)
			local result, err = A.system({ "sleep", "0.2" }, { timeout = 5000 })
			running = running - 1
			order[#order + 1] = i
			eq(err, nil)
			eq(result.code, 0)
			return true
		end
	end
	local start = vim.uv.hrtime()
	local results = P.run(tasks, { concurrency = 3 })
	local elapsed_ms = (vim.uv.hrtime() - start) / 1e6
	eq(#results, 6)
	for _, result in ipairs(results) do
		eq(result.ok, true)
	end
	eq(peak, 3)
	-- 6 tasks x 0.2s at concurrency 3 = ~400ms, serial would be ~1200ms
	truthy(elapsed_ms < 1000, "pool should run concurrently, elapsed " .. elapsed_ms .. "ms")
	eq(#order, 6)
end)

test("pool reports git failures through async.system", function()
	local results = P.run({
		function()
			local result, err = A.system({ "git", "--no-pager", "rev-parse", "/does/not/exist" }, {})
			if err or not result or result.code ~= 0 then
				return false, (result and result.stderr or err) or "failed"
			end
			return true
		end,
	})
	eq(#results, 1)
	eq(results[1].ok, false)
end)

test("pool on_start and on_result hooks fire", function()
	local starts, results_done = {}, {}
	local results = P.run({
		function()
			return true
		end,
		function()
			return true, nil, "second"
		end,
	}, {
		on_start = function(idx)
			starts[#starts + 1] = idx
		end,
		on_result = function(idx, ok, err, extra)
			results_done[#results_done + 1] = { idx = idx, ok = ok, err = err, extra = extra }
		end,
	})
	eq(#results, 2)
	eq(#starts, 2)
	eq(#results_done, 2)
	eq(results_done[1].idx, 1)
	eq(results_done[1].ok, true)
	eq(results_done[2].idx, 2)
	eq(results_done[2].extra, "second")
end)

test("pool stop_on_error halts new launches", function()
	local launched = 0
	local results = P.run({
		function()
			launched = launched + 1
			return true
		end,
		function()
			launched = launched + 1
			return false, "fail early"
		end,
		function()
			launched = launched + 1
			return true
		end,
	}, { concurrency = 1, stop_on_error = true })
	eq(launched, 2)
	eq(#results, 3)
	eq(results[2].ok, false)
	eq(results[3].ok, false)
	eq(results[3].err, "cancelled")
end)

test("git.run works inside pool workers (async path)", function()
	local results = P.run({
		function()
			local result, err = G.run({ "--version" }, {})
			if err then
				return false, err
			end
			if not (result.stdout or ""):find("git version") then
				return false, "unexpected git output"
			end
			return true
		end,
	})
	eq(#results, 1)
	eq(results[1].ok, true)
end)

test("git.run works outside workers (sync path)", function()
	local result, err = G.run({ "--version" }, {})
	eq(err, nil)
	truthy((result.stdout or ""):find("git version"), "git version output")
end)

test("worker context detection", function()
	eq(A.in_worker(), false)
	local results = P.run({
		function()
			eq(A.in_worker(), true)
			return true
		end,
	})
	eq(results[1].ok, true)
	eq(A.in_worker(), false)
end)

io.write(string.format("\npool: %d passed, %d failed\n", passed, failed))
if failed > 0 then
	os.exit(1)
end
