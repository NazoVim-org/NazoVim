local U = require("nazoplug.util")
local G = require("nazoplug.git")
local S = require("nazoplug.spec")

local M = {}

M.init_done = false
M.did_ftdetect = {}
M.disabled_plugins = {}
M.by_name = {}
M.pack_dir = nil

function M.setup(opts)
	opts = opts or {}
	M.pack_dir = opts.pack_dir
	M.by_name = opts.by_name or {}
	M.disabled_plugins = {}
	for _, name in ipairs(opts.disabled_plugins or {}) do
		M.disabled_plugins[name] = true
	end
	M.init_done = false
	M.did_ftdetect = {}
end

function M.source_file(path)
	local ok, err = pcall(vim.cmd, "source " .. vim.fn.fnameescape(path))
	if not ok then
		U.warn(string.format("failed to source %s: %s", path, err))
	end
	return ok
end

function M.source_runtime(dir, sub)
	local root = U.join(dir, sub)
	if not U.is_dir(root) then
		return
	end
	for _, path in
		ipairs(U.list_files(root, function(file_path)
			return file_path:match("%.vim$") ~= nil or file_path:match("%.lua$") ~= nil
		end))
	do
		local name = U.basename(path):gsub("%.[^.]+$", "")
		if not M.disabled_plugins[name] then
			M.source_file(path)
		end
	end
end

function M.ftdetect(dir)
	if M.did_ftdetect[dir] then
		return
	end
	M.did_ftdetect[dir] = true
	vim.cmd("augroup filetypedetect")
	M.source_runtime(dir, "ftdetect")
	vim.cmd("augroup END")
end

function M.packadd(dir)
	M.source_runtime(dir, "plugin")
	M.ftdetect(dir)
	if M.init_done then
		M.source_runtime(dir, "after/plugin")
	end
end

function M.add_to_rtp(spec)
	local rtp = vim.opt.rtp:get()
	if vim.tbl_contains(rtp, spec.dir) then
		return
	end
	local index = #rtp + 1
	for i, path in ipairs(rtp) do
		if path:sub(-6) == "/after" then
			index = i
			break
		end
	end
	table.insert(rtp, index, spec.dir)
	local after = U.join(spec.dir, "after")
	if U.is_dir(after) and not vim.tbl_contains(rtp, after) then
		table.insert(rtp, index + 1, after)
	end
	vim.opt.rtp = rtp
end

function M.config(spec)
	if spec.config == false then
		return
	end
	if type(spec.config) == "function" then
		local ok, err = pcall(spec.config, spec, spec.opts)
		if not ok then
			U.warn(string.format("config failed for %s: %s", spec.name, err))
			return false
		end
		return true
	end
	if spec.config == nil and spec.opts == nil then
		return true
	end
	local main = S.resolve_main(spec)
	if not main then
		U.warn(string.format("module not found for config of %s", spec.name))
		return false
	end
	local ok, module = pcall(require, main)
	if not ok then
		U.warn(string.format("failed to require %s for %s: %s", main, spec.name, module))
		return false
	end
	if type(module.setup) ~= "function" then
		U.warn(string.format("%s.setup is not a function for %s", main, spec.name))
		return false
	end
	local setup_ok, err = pcall(module.setup, spec.opts or {})
	if not setup_ok then
		U.warn(string.format("setup failed for %s: %s", spec.name, err))
		return false
	end
	return true
end

function M.load(spec, reason)
	if type(spec) == "string" then
		spec = M.by_name[spec]
	end
	if not spec or spec._.loaded then
		return spec and spec._.loaded or false
	end
	if spec._.needs_hydrate or spec._.needs_config then
		local hydrated, err = S.hydrate(spec, { pack_dir = M.pack_dir })
		if not hydrated then
			U.warn(string.format("failed to hydrate %s: %s", spec.name, tostring(err)))
		end
	end
	if not S.is_enabled(spec) then
		return false
	end
	if not spec._.installed then
		spec._.installed = U.is_dir(spec.dir)
	end
	if not spec._.installed then
		U.warn(string.format("plugin %s is not installed", spec.name))
		return false
	end

	spec._.loaded = true
	local triggers_ok, triggers = pcall(require, "nazoplug.triggers")
	if triggers_ok and triggers.disable then
		triggers.disable(spec)
	end
	M.add_to_rtp(spec)
	for _, dependency_name in ipairs(spec.dependencies or {}) do
		local dependency = M.by_name[dependency_name]
		if dependency and not dependency._.loaded then
			M.load(dependency, { plugin = spec.name })
		end
	end
	M.packadd(spec.dir)
	if spec.config or spec.opts or spec._.has_config or spec._.needs_config then
		M.config(spec)
	end
	spec._.loaded_at = vim.uv.hrtime()
	vim.schedule(function()
		vim.api.nvim_exec_autocmds("User", { pattern = "LazyLoad", modeline = false, data = spec.name })
		vim.api.nvim_exec_autocmds("User", { pattern = "LazyRender", modeline = false })
	end)
	return true
end

function M.get_start_specs(specs)
	local start = {}
	for _, spec in ipairs(specs) do
		if not spec._.loaded and S.is_enabled(spec) and (spec._.rtp_loaded or spec.lazy == false) then
			start[#start + 1] = spec
		end
	end
	table.sort(start, function(left, right)
		local left_priority = left.priority or 50
		local right_priority = right.priority or 50
		if left_priority ~= right_priority then
			return left_priority > right_priority
		end
		return left.name < right.name
	end)
	return start
end

function M.reset_rtp(opts)
	opts = opts or {}
	local config = vim.fn.stdpath("config")
	local data = vim.fn.stdpath("data")
	local runtime = vim.env.VIMRUNTIME
	local keep = {}
	local seen = {}
	local function add(path)
		if path and path ~= "" and not seen[path] then
			seen[path] = true
			keep[#keep + 1] = path
		end
	end
	add(config)
	if U.is_dir(U.join(config, "after")) then
		add(U.join(config, "after"))
	end
	add(U.join(data, "site"))
	if U.is_dir(U.join(data, "site/after")) then
		add(U.join(data, "site/after"))
	end
	add(runtime)
	for _, path in ipairs(opts.keep or {}) do
		add(path)
	end
	for _, path in ipairs(vim.opt.rtp:get()) do
		if path:match("/nazoplug$") or path:match("/nazoplug/") then
			add(path)
		end
	end
	vim.opt.rtp = keep
	vim.opt.packpath = { U.join(data, "site"), config }
end

function M.source_original_rtp(original)
	for _, path in ipairs(original) do
		if not path:find("/after/?$") then
			M.did_ftdetect[path] = true
			M.packadd(path)
		end
	end
	for _, path in ipairs(vim.opt.rtp:get()) do
		if path:find("/after/?$") then
			M.source_runtime(path, "plugin")
		end
	end
end

function M.startup(specs, opts)
	opts = opts or {}
	if not opts.initialized then
		M.setup({
			pack_dir = opts.pack_dir,
			by_name = opts.by_name,
			disabled_plugins = opts.disabled_plugins,
		})
	end
	local original = vim.opt.rtp:get()
	local keep = vim.list_extend({}, original)
	vim.list_extend(keep, opts.keep or {})
	vim.go.loadplugins = false
	M.reset_rtp({ keep = keep })
	if vim.env.VIMRUNTIME then
		M.source_file(U.join(vim.env.VIMRUNTIME, "filetype.lua"))
	end
	for _, spec in ipairs(specs) do
		if spec._.needs_hydrate then
			local hydrated, err = S.hydrate(spec, { pack_dir = M.pack_dir })
			if not hydrated then
				U.warn(string.format("failed to hydrate %s: %s", spec.name, tostring(err)))
			end
		end
		if type(spec.init) == "function" then
			local ok, err = pcall(spec.init, spec)
			if not ok then
				U.warn(string.format("init failed for %s: %s", spec.name, err))
			end
		end
	end
	for _, spec in ipairs(M.get_start_specs(specs)) do
		if not spec._.loaded then
			M.load(spec, { start = "start" })
		end
	end
	M.source_original_rtp(original)
	M.init_done = true
end

return M
