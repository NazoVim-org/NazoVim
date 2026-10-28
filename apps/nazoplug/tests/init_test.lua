local U = require("nazoplug.util")

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

local function truthy(value, label)
	if not value then
		error((label or "value") .. " is not truthy", 2)
	end
	return value
end

local function eq(actual, expected, label)
	if not vim.deep_equal(actual, expected) then
		error(string.format("%s: expected %s, got %s", label or "value", vim.inspect(expected), vim.inspect(actual)), 2)
	end
end

local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, "p")
for _, name in ipairs({ "config", "data", "state", "cache", "pack/demo.nvim/lua", "pack/demo.nvim/plugin" }) do
	vim.fn.mkdir(U.join(tmp, name), "p")
end
vim.env.XDG_CONFIG_HOME = U.join(tmp, "config")
vim.env.XDG_DATA_HOME = U.join(tmp, "data")
vim.env.XDG_STATE_HOME = U.join(tmp, "state")
vim.env.XDG_CACHE_HOME = U.join(tmp, "cache")

local plugin = U.join(tmp, "pack/demo.nvim")
U.write_file(
	U.join(plugin, "lua/demo.lua"),
	[[
return {
  setup = function(opts)
    vim.g.nazoplug_demo_setup = opts.value
  end,
}
]]
)
U.write_file(
	U.join(plugin, "plugin/demo.lua"),
	[[
vim.g.nazoplug_demo_loaded = (vim.g.nazoplug_demo_loaded or 0) + 1
vim.api.nvim_create_user_command("NazoPlugDemo", function()
  vim.g.nazoplug_demo_command = true
end, {})
]]
)

test("setup initializes loader, commands, and spec config", function()
	local nazoplug = require("nazoplug")
	local result = nazoplug.setup({
		spec = {
			{
				name = "demo.nvim",
				dir = plugin,
				lazy = false,
				opts = { value = 7 },
			},
		},
		pack_dir = U.join(tmp, "pack"),
		lockfile = U.join(tmp, "runtime-lock.json"),
		config_lock = U.join(tmp, "config-lock.json"),
		migrate = false,
	})
	truthy(result, "setup result")
	eq(vim.g.nazoplug_demo_loaded, 1)
	eq(vim.g.nazoplug_demo_setup, 7)
	eq(vim.fn.exists(":NazoPlug"), 2)
	eq(vim.fn.exists(":NazoPlugDemo"), 2)
	eq(vim.go.loadplugins, false)
	eq(#nazoplug.specs, 1)
end)

vim.fn.delete(tmp, "rf")
io.write(string.format("\n%d passed, %d failed\n", passed, failed))
if failed > 0 then
	vim.cmd("cquit 1")
else
	vim.cmd("qall!")
end
