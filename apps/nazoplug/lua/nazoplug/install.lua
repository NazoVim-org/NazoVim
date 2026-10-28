local U = require("nazoplug.util")
local G = require("nazoplug.git")
local L = require("nazoplug.lock")

local M = {}

local function as_commands(build)
	if type(build) == "function" or type(build) == "string" then
		return { build }
	end
	if type(build) == "table" and U.is_list(build) then
		return build
	end
	return { build }
end

local function source_plugin(spec)
	local rtp = vim.opt.runtimepath:get()
	if not vim.tbl_contains(rtp, spec.dir) then
		vim.opt.runtimepath:prepend(spec.dir)
	end
	local after_dir = U.join(spec.dir, "after")
	if U.is_dir(after_dir) and not vim.tbl_contains(vim.opt.runtimepath:get(), after_dir) then
		vim.opt.runtimepath:append(after_dir)
	end
	for _, sub in ipairs({ "plugin", "after/plugin" }) do
		local dir = U.join(spec.dir, sub)
		if U.is_dir(dir) then
			for _, file in
				ipairs(U.list_files(dir, function(path)
					return path:match("%.vim$") ~= nil or path:match("%.lua$") ~= nil
				end))
			do
				local ok, err = pcall(vim.cmd, "source " .. vim.fn.fnameescape(file))
				if not ok then
					return nil, err
				end
			end
		end
	end
	return true
end

function M.build(spec, opts)
	if spec.build == nil or spec.build == false then
		return true
	end
	if spec._.build then
		return true
	end
	opts = opts or {}
	for _, command in ipairs(as_commands(spec.build)) do
		if type(command) == "function" then
			local ok, err = pcall(command, spec)
			if not ok then
				return nil, string.format("build failed for %s: %s", spec.name, err)
			end
		elseif type(command) == "string" then
			local cmd = U.trim(command)
			if cmd:sub(1, 1) == ":" then
				local sourced, source_err = source_plugin(spec)
				if not sourced then
					return nil, string.format("build failed for %s: %s", spec.name, source_err)
				end
				local ok, err = pcall(vim.cmd, cmd:sub(2))
				if not ok then
					return nil, string.format("build failed for %s: %s", spec.name, err)
				end
			else
				local shell = vim.o.shell
				local ok, process = pcall(vim.system, { shell, "-c", cmd }, {
					cwd = spec.dir,
					text = true,
					timeout = opts.build_timeout or 300000,
				})
				if not ok then
					return nil, string.format("build failed for %s: %s", spec.name, process)
				end
				local result = process:wait()
				if result.code ~= 0 then
					local message = U.trim(result.stderr)
					if message == "" then
						message = U.trim(result.stdout)
					end
					if message == "" then
						message = string.format("exit code %d", result.code)
					end
					return nil, string.format("build failed for %s: %s", spec.name, message)
				end
			end
		else
			return nil, string.format("invalid build for %s", spec.name)
		end
	end
	spec._.build = true
	return true
end

function M.entry(spec)
	local head, err = G.head(spec.dir)
	if not head then
		return nil, err
	end
	local branch = G.current_branch(spec.dir)
	if not branch and not spec.tag and not spec.version and not spec.commit then
		branch = spec.branch or G.default_branch(spec.dir, spec.url)
	end
	local entry = { commit = head }
	if branch and branch ~= "" then
		entry.branch = branch
	end
	return entry
end

function M.ensure(spec, opts)
	opts = opts or {}
	if not spec._ then
		spec._ = {}
	end
	local installed = G.is_repo(spec.dir)
	local use_lock = spec.pin or opts.use_lock == true or (opts.use_lock == "missing" and not installed)
	local locked = use_lock and opts.lock and opts.lock[spec.name] or nil

	if installed and opts.update == false and not use_lock then
		spec._.installed = true
		local entry, entry_err = M.entry(spec)
		if not entry then
			return nil, string.format("failed to read HEAD for %s: %s", spec.name, entry_err)
		end
		local built, build_err = M.build(spec, opts)
		if not built then
			return entry, build_err
		end
		return entry, nil
	end

	if installed and locked and locked.commit then
		local head = G.head(spec.dir)
		local current_branch = G.current_branch(spec.dir)
		local branch_ok
		if spec.tag or spec.version or spec.commit then
			branch_ok = current_branch == nil
		else
			local expected_branch = spec.branch or locked.branch
			branch_ok = not expected_branch or current_branch == expected_branch
		end
		if head == locked.commit and branch_ok then
			spec._.installed = true
			local entry, entry_err = M.entry(spec)
			if not entry then
				return nil, string.format("failed to read HEAD for %s: %s", spec.name, entry_err)
			end
			local built, build_err = M.build(spec, opts)
			if not built then
				return entry, build_err
			end
			return entry, nil
		end
	end

	local locked_present = installed and locked and locked.commit and G.has_commit(spec.dir, locked.commit)

	if not installed then
		if U.exists(spec.dir) then
			local entries = vim.fn.readdir(spec.dir)
			if #entries > 0 then
				return nil, string.format("%s exists but is not a git repository", spec.dir)
			end
		end
		local clone_branch = nil
		if spec.branch and spec.version == nil and spec.commit == nil and spec.tag == nil then
			clone_branch = spec.branch
		end
		local ok, err = G.clone(spec, {
			branch = clone_branch,
			timeout = opts.timeout,
		})
		if not ok then
			return nil, string.format("clone failed for %s: %s", spec.name, err)
		end
		if locked and locked.commit and not G.has_commit(spec.dir, locked.commit) and not opts.offline then
			local fetched, fetch_err = G.fetch(spec.dir, { timeout = opts.timeout })
			if not fetched then
				return nil, string.format("fetch failed for %s: %s", spec.name, fetch_err)
			end
		end
	elseif not opts.offline and not locked_present and (opts.update ~= false or locked) then
		local ok, err = G.fetch(spec.dir, { timeout = opts.timeout })
		if not ok then
			return nil, string.format("fetch failed for %s: %s", spec.name, err)
		end
	end

	local checkout_branch = nil
	if not spec.tag and not spec.version and not spec.commit then
		checkout_branch = spec.branch or (locked and locked.branch)
	end
	local ok, err
	if locked and locked.commit then
		ok, err = G.checkout(spec.dir, locked.commit, {
			branch = checkout_branch,
			submodules = spec.submodules,
			timeout = opts.timeout,
		})
	else
		ok, err = G.checkout_spec(spec, {
			offline = opts.offline,
			branch = checkout_branch,
			timeout = opts.timeout,
		})
	end
	if not ok then
		return nil, string.format("checkout failed for %s: %s", spec.name, err)
	end

	spec._.installed = true
	local entry, entry_err = M.entry(spec)
	if not entry then
		return nil, string.format("failed to read HEAD for %s: %s", spec.name, entry_err)
	end
	spec._.build = false
	local built, build_err = M.build(spec, opts)
	if not built then
		return entry, build_err
	end
	return entry, nil
end

function M.prefetch(specs, opts)
	opts = opts or {}
	if opts.offline or opts.prefetch == false then
		return true, {}
	end
	local missing = {}
	for _, spec in ipairs(specs) do
		if spec.url and not U.exists(spec.dir) then
			missing[#missing + 1] = spec
		end
	end
	if #missing == 0 then
		return true, {}
	end
	local concurrency = opts.concurrency or 16
	local timeout = opts.timeout or 300000
	local index = 0
	local active = 0
	local done = false
	local aborted = false
	local errors = {}
	local function pump()
		while active < concurrency and index < #missing do
			index = index + 1
			local spec = missing[index]
			local clone_branch = nil
			if spec.branch and spec.version == nil and spec.commit == nil and spec.tag == nil then
				clone_branch = spec.branch
			end
			local function finish(result)
				vim.schedule(function()
					active = active - 1
					if aborted then
						return
					end
					if result.code ~= 0 then
						errors[#errors + 1] =
							string.format("%s: %s", spec.name, U.trim(result.stderr or result.stdout or "clone failed"))
					end
					pump()
				end)
			end
			local ok, process = pcall(vim.system, G.clone_command(spec, { branch = clone_branch }), {
				text = true,
				timeout = timeout,
			}, finish)
			if ok then
				active = active + 1
			else
				errors[#errors + 1] = string.format("%s: %s", spec.name, tostring(process))
			end
		end
		if active == 0 and index >= #missing then
			done = true
		end
	end
	pump()
	if not done then
		local finished = vim.wait(timeout + 1000, function()
			return done
		end, 50)
		if not finished then
			aborted = true
			errors[#errors + 1] = "clone prefetch timed out"
		end
	end
	return #errors == 0, errors
end

function M.install(specs, lock, opts)
	opts = opts or {}
	lock = lock or {}
	M.prefetch(specs, opts)
	local by_name = {}
	if opts.by_name then
		for name, spec in pairs(opts.by_name) do
			by_name[name] = spec
		end
	end
	for _, spec in ipairs(specs) do
		by_name[spec.name] = spec
	end
	local visited = {}
	local visiting = {}
	local results = {}
	local failed = {}

	local function visit(spec)
		if visited[spec.name] then
			return true
		end
		if visiting[spec.name] then
			return nil, "dependency cycle involving " .. spec.name
		end
		visiting[spec.name] = true
		for _, dependency_name in ipairs(spec.dependencies or {}) do
			local dependency = by_name[dependency_name]
			if dependency then
				local ok, err = visit(dependency)
				if not ok then
					visiting[spec.name] = nil
					return nil, err
				end
			end
		end
		if opts.on_progress then
			opts.on_progress(spec, "start")
		end
		local ensure_opts = vim.tbl_extend("force", {}, opts)
		ensure_opts.lock = lock
		local entry, err = M.ensure(spec, ensure_opts)
		visiting[spec.name] = nil
		if not entry then
			failed[#failed + 1] = spec.name
			results[#results + 1] = { name = spec.name, ok = false, err = err }
			if opts.on_progress then
				opts.on_progress(spec, "error", err)
			end
			return nil, err
		end
		local set_ok, set_err = L.set(lock, spec.name, entry)
		if not set_ok then
			failed[#failed + 1] = spec.name
			results[#results + 1] = { name = spec.name, ok = false, err = set_err }
			return nil, set_err
		end
		visited[spec.name] = true
		local build_ok = err == nil
		results[#results + 1] = { name = spec.name, ok = build_ok, err = err }
		if not build_ok then
			failed[#failed + 1] = spec.name
		end
		if opts.on_progress then
			opts.on_progress(spec, build_ok and "done" or "build_error", err)
		end
		return true
	end

	for _, spec in ipairs(specs) do
		local ok, err = visit(spec)
		if not ok and opts.stop_on_error then
			return false, results, failed, err
		end
	end

	if opts.lock_path and opts.save ~= false then
		local ok, err = L.save(opts.lock_path, lock)
		if not ok then
			return false, results, failed, err
		end
	end
	if #failed > 0 then
		return false, results, failed
	end
	return true, results, failed
end

function M.sync(specs, lock, opts)
	opts = vim.tbl_extend("force", { update = true, use_lock = true }, opts or {})
	return M.install(specs, lock, opts)
end

function M.install_missing(specs, lock, opts)
	opts = vim.tbl_extend("force", { update = false, use_lock = "missing" }, opts or {})
	local by_name = opts.by_name or {}
	local missing = {}
	local checked = {}
	local function needs_install(spec)
		if not spec or checked[spec.name] then
			return false
		end
		checked[spec.name] = true
		if not G.is_repo(spec.dir) then
			return true
		end
		for _, dependency_name in ipairs(spec.dependencies or {}) do
			if needs_install(by_name[dependency_name]) then
				return true
			end
		end
		return false
	end
	for _, spec in ipairs(specs) do
		if needs_install(spec) then
			missing[#missing + 1] = spec
		end
	end
	return M.install(missing, lock, opts)
end

function M.check(spec, lock)
	if not G.is_repo(spec.dir) then
		return false, "not installed"
	end
	local head, err = G.head(spec.dir)
	if not head then
		return false, err
	end
	local entry = lock and lock[spec.name]
	if entry and entry.commit and entry.commit ~= head then
		return false, "commit mismatch"
	end
	if not spec.tag and not spec.version and not spec.commit then
		local expected_branch = spec.branch or (entry and entry.branch)
		local current_branch = G.current_branch(spec.dir)
		if expected_branch and current_branch and current_branch ~= expected_branch then
			return false, "branch mismatch"
		end
	end
	return true, head
end

function M.migration_uptodate(old_pack_dir)
	local marker = U.join(old_pack_dir, ".nazoplug-migrated")
	local mstat = vim.uv.fs_stat(marker)
	if not mstat then
		return false
	end
	local dstat = vim.uv.fs_stat(old_pack_dir)
	if not dstat then
		return false
	end
	if
		dstat.mtime.sec > mstat.mtime.sec
		or (dstat.mtime.sec == mstat.mtime.sec and dstat.mtime.nsec > mstat.mtime.nsec)
	then
		return false
	end
	return true
end

function M.mark_migrated(old_pack_dir)
	local marker = U.join(old_pack_dir, ".nazoplug-migrated")
	local ok, err = U.write_atomic(marker, "migrated\n")
	if not ok then
		U.warn("failed to write migration marker: " .. tostring(err))
	end
end

function M.migrate(specs, opts)
	opts = opts or {}
	local lock = {}
	if opts.lock_path then
		local existing, err = L.load(opts.lock_path)
		if existing then
			lock = existing
		elseif opts.strict then
			return nil, err
		end
	end
	local migrated = {}
	for _, spec in ipairs(specs) do
		if not U.exists(spec.dir) and opts.old_pack_dir then
			local old_dir = U.join(opts.old_pack_dir, spec.name)
			if G.is_repo(old_dir) then
				vim.fn.mkdir(U.dirname(spec.dir), "p")
				local ok, err = pcall(vim.uv.fs_symlink, old_dir, spec.dir)
				if not ok then
					return nil, string.format("symlink failed for %s: %s", spec.name, err)
				end
				migrated[#migrated + 1] = spec.name
			end
		end
		if (opts.lock_path or opts.collect) and G.is_repo(spec.dir) then
			local entry, err = M.entry(spec)
			if entry then
				lock[spec.name] = entry
			elseif opts.strict then
				return nil, string.format("failed to read %s: %s", spec.name, err)
			end
		end
	end
	if opts.lock_path then
		local ok, err = L.save(opts.lock_path, lock)
		if not ok then
			return nil, err
		end
	end
	if opts.old_pack_dir then
		M.mark_migrated(opts.old_pack_dir)
	end
	return lock, migrated
end

return M
