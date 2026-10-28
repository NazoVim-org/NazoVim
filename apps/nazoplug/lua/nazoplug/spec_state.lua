local U = require("nazoplug.util")
local S = require("nazoplug.spec")

local M = {}

local hydrated_sources = {}

local function load_source(source)
	if source:match("%.lua$") or source:sub(1, 1) == "/" then
		local chunk, err = loadfile(source)
		if not chunk then
			return nil, err
		end
		local ok, value = pcall(chunk)
		if not ok then
			return nil, value
		end
		return value
	end
	local ok, value = pcall(require, source)
	if not ok then
		return nil, value
	end
	return value
end

function M.hydrate(spec, opts)
	if not spec or not spec._ or spec._.hydrated then
		return true
	end
	local source = spec._.source
	if not source then
		return false, "spec has no source"
	end
	opts = opts or {}
	local pack_dir = opts.pack_dir
	local key = source .. "\0" .. tostring(pack_dir)
	local by_name = hydrated_sources[key]
	if not by_name then
		local value, err = load_source(source)
		if value == nil then
			return false, err
		end
		local ok, _, loaded = pcall(S.collect, value, {
			pack_dir = pack_dir,
			defaults = { lazy = true },
			source = source,
		})
		if not ok then
			return false, loaded
		end
		by_name = loaded
		hydrated_sources[key] = by_name
	end
	local hydrated = by_name[spec.name]
	if not hydrated then
		return false, "spec not found in source"
	end
	for _, field in ipairs({
		"config",
		"init",
		"keys",
		"opts",
		"enabled",
		"cond",
		"build",
		"main",
	}) do
		if hydrated[field] ~= nil then
			spec[field] = hydrated[field]
		end
	end
	spec._.hydrated = true
	spec._.needs_hydrate = false
	spec._.needs_config = false
	return true
end

local function modules_in(dir)
	local lua_dir = U.join(dir, "lua")
	if not U.is_dir(lua_dir) then
		return {}
	end
	local modules = {}
	for _, path in
		ipairs(U.list_files(lua_dir, function(file_path)
			return file_path:match("%.lua$") ~= nil
		end))
	do
		local relative = path:sub(#lua_dir + 2)
		local module = relative:gsub("/", "."):gsub("%.lua$", "")
		if module ~= "init" and module ~= "" then
			module = module:gsub("%.init$", "")
			modules[#modules + 1] = module
		end
	end
	table.sort(modules)
	return modules
end

function M.modules(spec)
	if spec._.modules then
		return spec._.modules
	end
	if not U.is_dir(spec.dir) then
		return {}
	end
	spec._.modules = modules_in(spec.dir)
	return spec._.modules
end

function M.is_enabled(spec)
	if not spec or spec.enabled == false then
		return false
	end
	if type(spec.enabled) == "function" then
		local ok, enabled = pcall(spec.enabled, spec)
		if not ok or enabled == false then
			return false
		end
	end
	if spec.cond ~= nil then
		if type(spec.cond) == "function" then
			local ok, cond = pcall(spec.cond, spec)
			if not ok or cond == false then
				return false
			end
		elseif spec.cond == false then
			return false
		end
	end
	return true
end

function M.resolve_main(spec)
	if spec.main ~= nil then
		return spec.main or nil
	end
	if spec._.main ~= nil then
		return spec._.main or nil
	end
	local modules = M.modules(spec)
	local wanted = U.normname(spec.name)
	for _, module in ipairs(modules) do
		if U.normname(module) == wanted then
			spec._.main = module
			return module
		end
	end
	if #modules == 1 then
		spec._.main = modules[1]
		return modules[1]
	end
	return nil
end

function M.needs_startup_hydrate(spec)
	local m = spec and spec._
	if not m then
		return false
	end
	if m.needs_hydrate then
		return true
	end
	return m.needs_config and (m.rtp_loaded or spec.lazy == false)
end

return M
