local U = require("nazoplug.util")
local S = require("nazoplug.spec")
local SS = require("nazoplug.spec_state")
local L = require("nazoplug.lock")
local loader = require("nazoplug.loader")
local triggers = require("nazoplug.triggers")
local SC = require("nazoplug.spec_cache")

local M = {}

-- Apply user overrides to copies: the spec cache must contain original specs,
-- not settings from a previous launch.
function M.apply_startup(specs, by_name, startup)
	local overrides = type(startup) == "table" and startup.plugins or {}
	if type(overrides) ~= "table" then
		U.warn("startup.plugins must be a table")
		return specs, by_name
	end
	local result, map = {}, {}
	for _, spec in ipairs(specs) do
		local timing = overrides[spec.name]
		local copy = spec
		if timing ~= nil then
			local event = type(timing) == "string" and timing:match("^(%w+)") or nil
			local valid = timing == "startup"
				or timing == "on_demand"
				or (event and vim.fn.exists("##" .. event) == 1 and (timing == event or timing:match("^%w+%s+%S.*$")))
			if valid then
				copy = vim.tbl_extend("force", {}, spec)
				copy._ = vim.tbl_extend("force", {}, spec._)
				copy.lazy = timing ~= "startup"
				if timing == "startup" or timing == "on_demand" then
					copy.event = nil
				else
					copy.event = { timing }
				end
			elseif timing == "VeryLazy" then
				copy = vim.tbl_extend("force", {}, spec)
				copy._ = vim.tbl_extend("force", {}, spec._)
				copy.lazy = true
				copy.event = { timing }
			else
				U.warn(string.format("invalid startup timing for %s: %s", spec.name, tostring(timing)))
			end
		end
		result[#result + 1] = copy
		map[copy.name] = copy
	end
	for name in pairs(overrides) do
		if not by_name[name] then
			U.warn(string.format("unknown plugin in startup.plugins: %s", tostring(name)))
		end
	end
	return result, map
end

local function manager_root()
	local source = debug.getinfo(1, "S").source
	local path = source:sub(1, 1) == "@" and source:sub(2) or source
	return vim.fn.fnamemodify(path, ":h:h:h")
end

function M.default_disabled()
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

local function collect_specs(input, opts)
	local ok, list, map, err = pcall(S.collect, input, {
		pack_dir = opts.pack_dir,
		defaults = opts.defaults,
		source = opts.source,
	})
	if not ok then
		return nil, nil, tostring(list)
	end
	if not list then
		return nil, nil, tostring(err or map)
	end
	return list, map
end

-- Acquire the startup specs: spec cache when available, with a collect
-- fallback and per-spec hydration when cached data is stale or partial.
function M.acquire_specs(input, opts)
	local use_cache = SC.enabled(input, opts)
	local specs, by_name
	local from_cache = false
	if use_cache then
		specs, by_name = SC.load()
		from_cache = specs ~= nil
	end
	if not specs then
		local collect_err
		specs, by_name, collect_err = collect_specs(input, opts)
		if not specs then
			return nil, nil, collect_err
		end
	end
	if from_cache then
		local cached_ok = true
		for _, spec in ipairs(specs) do
			if SS.needs_startup_hydrate(spec) then
				local hydrated, hydrate_err = SS.hydrate(spec, { pack_dir = opts.pack_dir })
				if not hydrated then
					U.warn(string.format("failed to hydrate %s from spec cache: %s", spec.name, tostring(hydrate_err)))
					cached_ok = false
					break
				end
			end
		end
		if not cached_ok then
			local collect_err
			specs, by_name, collect_err = collect_specs(input, opts)
			if not specs then
				return nil, nil, collect_err
			end
			from_cache = false
		end
	end
	if use_cache and not from_cache then
		vim.schedule(function()
			SC.save(specs)
		end)
	end
	return specs, by_name, nil
end

function M.validate_specs(specs)
	for _, spec in ipairs(specs) do
		local errors, warnings = S.validate(spec)
		for _, err in ipairs(errors) do
			U.warn(string.format("%s: %s", spec.name, err))
		end
		for _, warning in ipairs(warnings) do
			U.warn(string.format("%s: %s", spec.name, warning))
		end
	end
end

-- Run the full startup sequence and return the plugin-manager state table.
function M.run(opts)
	opts = opts or {}
	if opts.startup ~= nil and type(opts.startup) ~= "table" then
		U.warn("startup must be a table")
		opts.startup = nil
	end
	local data = vim.fn.stdpath("data")
	local root = manager_root()
	local pack_dir = opts.pack_dir or U.join(data, "site/pack/nazoplug/opt")
	local lock_path, config_lock, lock = L.resolve_startup(opts)
	local defaults = opts.defaults or { lazy = true }
	local disabled = opts.disabled_plugins or M.default_disabled()

	vim.go.loadplugins = false

	local input = opts.spec or "plugins"
	if type(input) == "string" then
		input = { import = input }
	end

	local specs, by_name, collect_err = M.acquire_specs(input, {
		pack_dir = pack_dir,
		defaults = defaults,
		source = opts.source,
	})
	if not specs then
		U.error("failed to collect plugin specs: " .. tostring(collect_err))
		return nil
	end
	specs, by_name = M.apply_startup(specs, by_name, opts.startup)
	M.validate_specs(specs)

	loader.setup({
		pack_dir = pack_dir,
		by_name = by_name,
		disabled_plugins = disabled,
	})
	triggers.setup(specs, { loader = loader, startup = opts.startup })
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
		concurrency = opts.concurrency,
	})
	require("nazoplug.health").setup({
		specs = specs,
		lock = lock,
		lock_path = lock_path,
		config_lock = config_lock,
		pack_dir = pack_dir,
	})

	return {
		specs = specs,
		by_name = by_name,
		lock = lock,
		lock_path = lock_path,
		config_lock = config_lock,
		pack_dir = pack_dir,
		disabled_plugins = disabled,
	}
end

return M
