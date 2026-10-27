local U = require("nazoplug.util")
local S = require("nazoplug.spec")
local L = require("nazoplug.lock")
local I = require("nazoplug.install")
local loader = require("nazoplug.loader")
local triggers = require("nazoplug.triggers")

local M = {}

local function manager_root()
	local source = debug.getinfo(1, "S").source
	local path = source:sub(1, 1) == "@" and source:sub(2) or source
	return vim.fn.fnamemodify(path, ":h:h:h")
end

local function default_disabled()
	return {
		"gzip",
		"matchit",
		"matchparen",
		"netrwPlugin",
		"netrw",
		"tarPlugin",
		"tar",
		"tohtml",
		"tutor",
		"zipPlugin",
		"zip",
		"osc52",
		"rplugin",
		"man",
		"shada",
		"spellfile",
		"editorconfig",
	}
end

local function resolve_lock(opts)
	local data = vim.fn.stdpath("data")
	local config = vim.fn.stdpath("config")
	local lock_path = opts.lockfile or U.join(data, "nazoplug-lock.json")
	local config_lock = opts.config_lock or U.join(config, "nazoplug-lock.json")

	if not U.is_file(config_lock) then
		local legacy_config = U.join(config, "lazy-lock.json")
		if U.is_file(legacy_config) then
			config_lock = legacy_config
		end
	end
	if not U.is_file(lock_path) then
		local legacy_data = U.join(data, "lazy-lock.json")
		if not U.is_file(legacy_data) then
			local fallback = U.join(vim.fn.fnamemodify(data, ":h"), "nvim/lazy-lock.json")
			if U.is_file(fallback) then
				legacy_data = fallback
			end
		end
		if U.is_file(legacy_data) then
			local copied, err = L.ensure_runtime_copy(legacy_data, lock_path)
			if not copied then
				U.warn("failed to copy legacy lock: " .. tostring(err))
			end
		elseif U.is_file(config_lock) then
			local copied, err = L.ensure_runtime_copy(config_lock, lock_path)
			if not copied then
				U.warn("failed to copy config lock: " .. tostring(err))
			end
		end
	end

	local lock, err = L.load(lock_path)
	if not lock then
		U.error("failed to load lock: " .. tostring(err))
		lock = {}
	end
	return lock_path, config_lock, lock
end

local function is_spec_input(value)
	if type(value) == "string" then
		return true
	end
	return type(value) == "table" and (U.is_list(value) or value.name ~= nil or value.import ~= nil or value[1] ~= nil)
end

function M.setup(opts, extra)
	if extra ~= nil then
		opts = vim.tbl_deep_extend("force", extra, { spec = opts })
	elseif is_spec_input(opts) and not (type(opts) == "table" and opts.spec ~= nil) then
		opts = { spec = opts }
	end
	opts = opts or {}
	local data = vim.fn.stdpath("data")
	local root = manager_root()
	local pack_dir = opts.pack_dir or U.join(data, "site/pack/nazoplug/opt")
	local old_pack_dir = opts.old_pack_dir
	if not old_pack_dir then
		old_pack_dir = U.join(data, "lazy")
		if not U.is_dir(old_pack_dir) then
			local legacy = U.join(vim.fn.fnamemodify(data, ":h"), "nvim/lazy")
			if U.is_dir(legacy) then
				old_pack_dir = legacy
			end
		end
	end
	local lock_path, config_lock, lock = resolve_lock(opts)
	local defaults = opts.defaults or { lazy = true }
	local disabled = opts.disabled_plugins
		or (opts.performance and opts.performance.rtp and opts.performance.rtp.disabled_plugins)
		or default_disabled()

	vim.go.loadplugins = false

	local input = opts.spec or "plugins"
	if type(input) == "string" then
		input = { import = input }
	end
	local ok, specs, by_name, collect_err = pcall(S.collect, input, {
		pack_dir = pack_dir,
		defaults = defaults,
		source = opts.source,
	})
	if not ok or not specs then
		U.error("failed to collect plugin specs: " .. tostring(collect_err or by_name))
		return nil
	end

	for _, spec in ipairs(specs) do
		local errors, warnings = S.validate(spec)
		for _, err in ipairs(errors) do
			U.warn(string.format("%s: %s", spec.name, err))
		end
		for _, warning in ipairs(warnings) do
			U.warn(string.format("%s: %s", spec.name, warning))
		end
	end

	if opts.migrate ~= false and U.is_dir(old_pack_dir) then
		local migrated, migration_err = I.migrate(specs, { old_pack_dir = old_pack_dir, strict = false })
		if not migrated then
			U.warn("migration failed: " .. tostring(migration_err))
		end
	end

	M.specs = specs
	M.by_name = by_name
	M.lock = lock
	M.lock_path = lock_path
	M.config_lock = config_lock
	M.pack_dir = pack_dir
	M.old_pack_dir = old_pack_dir
	M.disabled_plugins = disabled

	loader.setup({
		pack_dir = pack_dir,
		by_name = by_name,
		disabled_plugins = disabled,
	})
	triggers.setup(specs, { loader = loader })
	loader.startup(specs, {
		initialized = true,
		pack_dir = pack_dir,
		by_name = by_name,
		disabled_plugins = disabled,
		keep = {
			root,
			U.join(root, "lua"),
		},
	})

	require("nazoplug.commands").setup({
		specs = specs,
		by_name = by_name,
		lock = lock,
		lock_path = lock_path,
		pack_dir = pack_dir,
		old_pack_dir = old_pack_dir,
	})
	require("nazoplug.health").setup({
		specs = specs,
		lock = lock,
		lock_path = lock_path,
		config_lock = config_lock,
		pack_dir = pack_dir,
	})

	vim.api.nvim_exec_autocmds("User", { pattern = "LazyDone" })

	if opts.install and opts.install.missing then
		vim.schedule(function()
			local install_ok, err = I.install_missing(M.specs, M.lock, {
				lock_path = M.lock_path,
				save = true,
				by_name = M.by_name,
			})
			if not install_ok and err then
				U.error("failed to install missing plugins: " .. tostring(err))
			end
		end)
	end

	return M
end

function M.install_missing()
	if not M.specs then
		return nil, "nazoplug is not initialized"
	end
	return I.install_missing(M.specs, M.lock, { lock_path = M.lock_path, save = true, by_name = M.by_name })
end

function M.check()
	require("nazoplug.health").check()
end

return M
