local boot = require("nazoplug.boot")
local triggers = require("nazoplug.triggers")

local function spec(name, lazy, event)
	return { name = name, lazy = lazy, event = event, _ = { loaded = false } }
end

local eager = spec("eager.nvim", false)
local delayed = spec("delayed.nvim", true, { "InsertEnter" })
local specs, map = boot.apply_startup({ eager, delayed }, { [eager.name] = eager, [delayed.name] = delayed }, {
	plugins = { [eager.name] = "VeryLazy", [delayed.name] = "startup" },
})
assert(specs[1].lazy == true and specs[1].event[1] == "VeryLazy")
assert(specs[2].lazy == false and specs[2].event == nil)
assert(map[eager.name] == specs[1] and map[delayed.name] == specs[2])
assert(eager.lazy == false and eager.event == nil)
assert(delayed.lazy == true and delayed.event[1] == "InsertEnter")
local on_demand = boot.apply_startup({ delayed }, { [delayed.name] = delayed }, {
	plugins = { [delayed.name] = "on_demand" },
})
assert(on_demand[1].lazy == true and on_demand[1].event == nil)
specs[1]._.loaded = true
assert(not eager._.loaded, "override must not mutate the cached spec")

local loaded = 0
local target = spec("timer.nvim", true, { "VeryLazy" })
local fake_loader = {
	load = function(s)
		loaded = loaded + 1
		s._.loaded = true
	end,
}
triggers.setup({ target }, { loader = fake_loader, startup = { very_lazy_delay_ms = 100 } })
vim.api.nvim_exec_autocmds("User", { pattern = "LazyDone" })
if vim.v.vim_did_enter == 0 then
	vim.api.nvim_exec_autocmds("UIEnter", {})
end
vim.wait(30)
assert(loaded == 0, "VeryLazy fired before the configured delay")
assert(
	vim.wait(500, function()
		return loaded == 1
	end, 10),
	"VeryLazy did not fire"
)

-- Reconfiguring cancels callbacks scheduled by the previous setup.
target._.loaded = false
loaded = 0
triggers.setup({ target }, { loader = fake_loader, startup = { very_lazy_delay_ms = 100 } })
vim.api.nvim_exec_autocmds("User", { pattern = "LazyDone" })
if vim.v.vim_did_enter == 0 then
	vim.api.nvim_exec_autocmds("UIEnter", {})
end
triggers.setup({}, { loader = fake_loader })
vim.wait(150)
assert(loaded == 0, "stale timer loaded a plugin after setup was replaced")

local config = vim.fn.tempname()
vim.fn.writefile({ 'return { very_lazy_delay_ms = 75, plugins = { ["example.nvim"] = "InsertEnter" } }' }, config)
vim.env.NAZOVIM_STARTUP_CONFIG = config
vim.env.NAZOVIM_VERY_LAZY_DELAY_MS = "125"
local configured = dofile("apps/nvim/lua/config/startup.lua")
assert(configured.very_lazy_delay_ms == 125 and configured.plugins["example.nvim"] == "InsertEnter")
vim.env.NAZOVIM_STARTUP_CONFIG = nil
vim.env.NAZOVIM_VERY_LAZY_DELAY_MS = nil
vim.fn.delete(config)
print("startup timing: overrides, cache isolation, delay and cancellation passed")
vim.cmd("qall!")
