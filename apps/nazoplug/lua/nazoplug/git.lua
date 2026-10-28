local U = require("nazoplug.util")
local A = require("nazoplug.async")

local M = {}

local tag_cache = {}

local function trim(value)
	return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function git_args(cwd, args)
	local command = { "git", "--no-pager" }
	if cwd then
		command[#command + 1] = "-C"
		command[#command + 1] = cwd
	end
	vim.list_extend(command, args)
	return command
end

function M.run(args, opts)
	opts = opts or {}
	local command = git_args(opts.cwd, args)
	local result, err = A.system(command, {
		cwd = opts.cwd,
		text = true,
		timeout = opts.timeout or 60000,
	})
	if err then
		return nil, tostring(err)
	end
	if not result then
		return nil, "git process was aborted"
	end
	if result.code ~= 0 then
		local message = trim(result.stderr)
		if message == "" then
			message = trim(result.stdout)
		end
		if message == "" then
			message = string.format("git exited with code %d", result.code)
		end
		return nil, message
	end
	return result, nil
end

function M.git(args, opts)
	return M.run(args, opts)
end

function M.output(args, opts)
	local result, err = M.run(args, opts)
	if not result then
		return nil, err
	end
	return trim(result.stdout), nil
end

function M.is_repo(dir)
	if not U.is_dir(dir) then
		return false
	end
	local result, err = M.run({ "rev-parse", "--is-inside-work-tree" }, { cwd = dir })
	return result ~= nil and trim(result.stdout) == "true", err
end

function M.head(dir)
	return M.output({ "rev-parse", "HEAD" }, { cwd = dir })
end

function M.current_branch(dir)
	local branch = M.output({ "symbolic-ref", "--short", "-q", "HEAD" }, { cwd = dir })
	if branch and branch ~= "" then
		return branch
	end
	return nil
end

function M.remote_url(dir)
	local url = M.output({ "config", "--get", "remote.origin.url" }, { cwd = dir })
	if url == "" then
		return nil
	end
	return url
end

function M.is_clean(dir)
	local status, err = M.output({ "status", "--porcelain" }, { cwd = dir })
	if not status then
		return nil, err
	end
	return status == ""
end

function M.default_branch(dir, url)
	local branch = M.output({ "symbolic-ref", "--short", "-q", "refs/remotes/origin/HEAD" }, { cwd = dir })
	if branch and branch:match("^origin/") then
		return branch:gsub("^origin/", "")
	end
	local remote_info = M.output({ "remote", "show", "origin" }, { cwd = dir, timeout = 15000 })
	if remote_info then
		local found = remote_info:match("HEAD branch:%s*([^%s]+)")
		if found then
			return found
		end
	end
	if url then
		local symref = M.output({ "ls-remote", "--symref", url, "HEAD" }, { timeout = 15000 })
		if symref then
			local found = symref:match("ref:%s*refs/heads/([^%s]+)")
			if found then
				return found
			end
		end
	end
	return nil
end

function M.remote_head(url)
	local output, err = M.output({ "ls-remote", "--symref", url, "HEAD" }, { timeout = 30000 })
	if not output then
		return nil, err
	end
	local commit = output:match("^([0-9a-fA-F]+)%s+HEAD")
	return commit, nil
end

function M.fetch(dir, opts)
	opts = opts or {}
	if not M.remote_url(dir) then
		return true
	end
	local args = { "fetch", "--tags", "--force", "--prune", "origin" }
	if opts.depth then
		args[#args + 1] = "--depth"
		args[#args + 1] = tostring(opts.depth)
	end
	local result, err = M.run(args, { cwd = dir, timeout = opts.timeout or 120000 })
	return result ~= nil, err
end

function M.has_commit(dir, commit)
	if not commit or commit == "" then
		return false
	end
	local result = M.run({ "cat-file", "-e", commit .. "^{commit}" }, { cwd = dir, timeout = 15000 })
	return result ~= nil
end

function M.fetch_tag(dir, tag, opts)
	opts = opts or {}
	local result, err = M.run({ "fetch", "--force", "--tags", "origin", "refs/tags/" .. tag .. ":refs/tags/" .. tag }, {
		cwd = dir,
		timeout = opts.timeout or 120000,
	})
	return result ~= nil, err
end

function M.tags(dir)
	local output, err = M.output({ "tag", "--list" }, { cwd = dir })
	if not output then
		return {}, err
	end
	local tags = {}
	for tag in output:gmatch("[^\r\n]+") do
		if tag ~= "" then
			tags[#tags + 1] = tag
		end
	end
	table.sort(tags)
	return tags
end

function M.remote_tags(url, opts)
	opts = opts or {}
	if tag_cache[url] and not opts.refresh then
		return tag_cache[url]
	end
	local output, err = M.output({ "ls-remote", "--tags", "--refs", url }, { timeout = opts.timeout or 60000 })
	if not output then
		return nil, err
	end
	local tags = {}
	for line in output:gmatch("[^\r\n]+") do
		local tag = line:match("refs/tags/(.+)$")
		if tag and not tag:match("%^{}$") then
			tags[#tags + 1] = tag
		end
	end
	table.sort(tags)
	tag_cache[url] = tags
	return tags
end

local function parsed_version(tag)
	local value = tag:gsub("^v", "")
	local ok, version = pcall(vim.version.parse, value)
	if not ok or not version then
		return nil
	end
	return version
end

local function version_gt(left, right)
	if left.version ~= right.version then
		return left.version > right.version
	end
	return left.tag > right.tag
end

local function select_version(tags, range_string)
	local range
	if range_string ~= "*" then
		local ok, parsed = pcall(vim.version.range, range_string)
		if not ok or not parsed then
			return nil, "invalid version range: " .. range_string
		end
		range = parsed
	end
	local candidates = {}
	for _, tag in ipairs(tags) do
		local version = parsed_version(tag)
		if version then
			local stable = version.prerelease == nil
			if range_string == "*" then
				if stable then
					candidates[#candidates + 1] = { tag = tag, version = version }
				end
			elseif range:has(version) then
				candidates[#candidates + 1] = { tag = tag, version = version }
			end
		end
	end
	if #candidates == 0 and range_string == "*" then
		for _, tag in ipairs(tags) do
			local version = parsed_version(tag)
			if version then
				candidates[#candidates + 1] = { tag = tag, version = version }
			end
		end
	end
	if #candidates == 0 then
		return nil, "no tag matches version " .. range_string
	end
	table.sort(candidates, version_gt)
	return candidates[1].tag, nil
end

function M.resolve_version(dir, version, opts)
	opts = opts or {}
	local tags = opts.tags
	if not tags then
		if M.is_repo(dir) then
			local err
			tags, err = M.tags(dir)
			if not tags then
				return nil, err
			end
		else
			tags = {}
		end
	end
	local tag, err = select_version(tags, version)
	if tag then
		return tag, nil
	end
	if opts.url and not opts.remote_checked then
		local remote_tags, remote_err = M.remote_tags(opts.url, { refresh = true })
		if remote_tags then
			tag, err = select_version(remote_tags, version)
			if tag then
				return tag, nil, true
			end
		elseif not err then
			err = remote_err
		end
	end
	return nil, err or ("no tag matches version " .. tostring(version))
end

function M.resolve_tag(dir, tag, opts)
	opts = opts or {}
	if type(tag) ~= "string" or tag == "" then
		return nil, "invalid tag"
	end
	if M.is_repo(dir) then
		local tags, err = M.tags(dir)
		if not tags then
			return nil, err
		end
		if vim.tbl_contains(tags, tag) then
			return tag, nil, false
		end
	end
	if opts.url and not opts.remote_checked then
		local remote_tags, remote_err = M.remote_tags(opts.url, { refresh = true })
		if remote_tags then
			if vim.tbl_contains(remote_tags, tag) then
				return tag, nil, true
			end
			return nil, "tag not found: " .. tag
		end
		return nil, remote_err or ("tag not found: " .. tag)
	end
	return nil, "tag not found: " .. tag
end

function M.resolve_ref(spec)
	if spec.commit then
		return { ref = spec.commit, kind = "commit" }
	end
	if spec.tag ~= nil then
		local tag, err, needs_fetch = M.resolve_tag(spec.dir, spec.tag, {
			url = spec.url,
			remote_checked = spec._ and spec._.tag_remote_checked,
		})
		if not tag then
			return nil, err
		end
		return { ref = tag, kind = "tag", needs_fetch = needs_fetch }
	end
	if spec.version ~= nil and spec.version ~= false then
		local tag, err, needs_fetch = M.resolve_version(spec.dir, spec.version, {
			url = spec.url,
			remote_checked = spec._ and spec._.version_remote_checked,
		})
		if not tag then
			return nil, err
		end
		return { ref = tag, kind = "tag", needs_fetch = needs_fetch }
	end
	if spec.branch then
		return { ref = "origin/" .. spec.branch, kind = "branch", branch = spec.branch }
	end
	return { ref = nil, kind = "default" }
end

function M.checkout(dir, ref, opts)
	opts = opts or {}
	if not ref then
		return true
	end
	local args
	if opts.branch then
		args = { "checkout", "--force", "-B", opts.branch, ref }
	else
		args = { "checkout", "--force", "--detach", ref }
	end
	local result, err = M.run(args, { cwd = dir, timeout = opts.timeout or 60000 })
	if not result then
		return nil, err
	end
	if opts.submodules ~= false then
		local sub_result, sub_err = M.run({ "submodule", "update", "--init", "--recursive" }, {
			cwd = dir,
			timeout = opts.timeout or 120000,
		})
		if not sub_result then
			return nil, sub_err
		end
	end
	return true
end

function M.clone_command(spec, opts)
	opts = opts or {}
	local args = { "clone", "--origin", "origin" }
	if opts.branch then
		args[#args + 1] = "--branch"
		args[#args + 1] = opts.branch
	end
	args[#args + 1] = spec.url
	args[#args + 1] = spec.dir
	return args
end

function M.clone(spec, opts)
	opts = opts or {}
	if U.exists(spec.dir) then
		local entries = vim.fn.readdir(spec.dir)
		if #entries > 0 then
			return nil, "destination already exists and is not empty: " .. spec.dir
		end
	end
	local ok, mkdir_err = U.mkdir(U.dirname(spec.dir))
	if not ok then
		return nil, mkdir_err
	end
	local result, err = M.run(M.clone_command(spec, opts), { timeout = opts.timeout or 300000 })
	if not result then
		if U.exists(spec.dir) then
			vim.fn.delete(spec.dir, "rf")
		end
		return nil, err
	end
	return true
end

function M.update_submodules(dir, opts)
	if opts and opts.submodules == false then
		return true
	end
	local result, err = M.run({ "submodule", "update", "--init", "--recursive" }, {
		cwd = dir,
		timeout = 120000,
	})
	return result ~= nil, err
end

function M.checkout_spec(spec, opts)
	local resolved, err = M.resolve_ref(spec)
	if not resolved then
		return nil, err
	end
	if resolved.needs_fetch and not opts.offline then
		local ok, fetch_err = M.fetch_tag(spec.dir, resolved.ref, opts)
		if not ok then
			return nil, fetch_err
		end
	end
	local checkout_opts = {
		branch = resolved.kind == "branch" and resolved.branch or nil,
		submodules = spec.submodules,
		timeout = opts.timeout,
	}
	if resolved.kind == "default" then
		local branch = opts.branch or M.default_branch(spec.dir, spec.url)
		resolved.ref = branch and ("origin/" .. branch) or "HEAD"
		checkout_opts.branch = branch
	end
	return M.checkout(spec.dir, resolved.ref, checkout_opts)
end

return M
