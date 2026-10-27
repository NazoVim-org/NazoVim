local U = require("nazoplug.util")
local L = require("nazoplug.lock")
local G = require("nazoplug.git")

local M = {}

local state = {}

local function h()
	return vim.health or require("health")
end

local function command_ok(command)
	return vim.fn.executable(command) == 1
end

function M.setup(opts)
	state = opts or {}
end

function M.check()
	local health = h()
	health.start("nazoplug")

	local version = vim.version()
	health.info(
		string.format(
			"Neovim %d.%d.%d (%s)",
			version.major,
			version.minor,
			version.patch,
			version.prerelease or "stable"
		)
	)

	if command_ok("git") then
		local output = vim.fn.system({ "git", "--version" })
		health.ok("git: " .. vim.trim(output))
	else
		health.error("git is not executable")
	end

	if not state.pack_dir then
		health.error("nazoplug is not initialized")
		return
	end

	health.info("plugin directory: " .. state.pack_dir)
	if U.is_dir(state.pack_dir) then
		health.ok("plugin directory exists")
	else
		health.warn("plugin directory does not exist yet")
	end

	if state.lock_path then
		health.info("runtime lock: " .. state.lock_path)
		if U.is_file(state.lock_path) then
			local lock, err = L.load(state.lock_path)
			if lock then
				health.ok(string.format("runtime lock loaded (%d plugins)", L.count(lock)))
			else
				health.error("runtime lock is invalid: " .. tostring(err))
			end
		else
			health.warn("runtime lock does not exist")
		end
	end

	if state.config_lock then
		health.info("config lock: " .. state.config_lock)
		if U.is_file(state.config_lock) then
			health.ok("config lock exists")
		else
			health.warn("config lock does not exist")
		end
	end

	if state.specs and #state.specs > 0 then
		health.ok(string.format("%d plugin specs loaded", #state.specs))
	else
		health.warn("no plugin specs loaded")
	end

	local specs = state.specs or {}
	local lock = state.lock or {}
	local missing, mismatched = {}, {}
	for _, spec in ipairs(specs) do
		if not G.is_repo(spec.dir) then
			missing[#missing + 1] = spec.name
		else
			local entry = lock[spec.name]
			if entry and entry.commit then
				local head = G.head(spec.dir)
				if head and head ~= entry.commit then
					mismatched[#mismatched + 1] = spec.name
				end
			end
		end
	end
	if #missing > 0 then
		health.warn("missing plugins: " .. table.concat(missing, ", "))
		health.info("run :NazoPlug install")
	else
		health.ok("all plugins are installed")
	end
	if #mismatched > 0 then
		health.warn("plugins at a different commit than the lock: " .. table.concat(mismatched, ", "))
		health.info("run :NazoPlug restore or :NazoPlug sync")
	end

	local missing_lines, stale = L.diff(lock, specs)
	if #missing_lines > 0 then
		health.info(string.format("%d spec(s) have no lock entry", #missing_lines))
	end
	if #stale > 0 then
		health.info(string.format("%d stale lock entr(y/ies): %s", #stale, table.concat(stale, ", ")))
	end

	local build_specs = {}
	for _, spec in ipairs(specs) do
		if spec.build then
			build_specs[#build_specs + 1] = spec.name
		end
	end
	if #build_specs > 0 then
		health.info("plugins with build steps: " .. table.concat(build_specs, ", "))
		for _, build in ipairs({ "make", "npm", "tree-sitter" }) do
			if not command_ok(build) then
				health.warn(build .. " is not executable (some build steps may fail)")
			end
		end
	end

	for _, lazy_dir in ipairs({
		U.join(vim.fn.stdpath("data"), "lazy"),
		U.join(vim.fn.fnamemodify(vim.fn.stdpath("data"), ":h"), "nvim/lazy"),
	}) do
		if U.is_dir(lazy_dir) then
			health.info("legacy lazy.nvim directory found: " .. lazy_dir)
		end
	end
end

return M
