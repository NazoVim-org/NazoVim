-- =========================================================
-- Enable bytecode cache (ryoppippi pattern)
-- =========================================================
vim.loader.enable()

-- =========================================================
-- Load configs
-- =========================================================
require("config.options")
require("config.keymaps")
require("config.autocmds")

local lazy_disabled_plugins = {
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

if vim.env.NAZOVIM_PLUGIN_MANAGER ~= "lazy" then
	if vim.env.NAZOVIM_NAZOPLUG_PATH and vim.env.NAZOVIM_NAZOPLUG_PATH ~= "" then
		vim.opt.rtp:prepend(vim.env.NAZOVIM_NAZOPLUG_PATH)
	end
	local ok, nazoplug = pcall(require, "nazoplug")
	if ok then
		local initialized = nazoplug.setup("plugins", {
			defaults = {
				lazy = true,
			},
			install = {
				colorscheme = { "kanagawa" },
				missing = vim.env.NAZOVIM_AUTO_INSTALL == "1",
			},
			migrate = vim.env.NAZOVIM_MIGRATE ~= "0",
			performance = {
				rtp = {
					disabled_plugins = lazy_disabled_plugins,
				},
			},
		})
		if not initialized then
			error("nazoplug setup failed")
		end
		return
	end
	vim.notify("nazoplug not found; falling back to lazy.nvim", vim.log.levels.WARN)
end

-- =========================================================
-- Bootstrap lazy.nvim
-- =========================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--single-branch",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {
	defaults = {
		lazy = true,
	},
	lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json",
	rocks = {
		enabled = false,
	},
	install = {
		colorscheme = { "kanagawa" },
	},
	concurrency = 64,
	performance = {
		cache = {
			enabled = true,
		},
		reset_packpath = true,
		rtp = {
			reset = true,
			disabled_plugins = lazy_disabled_plugins,
		},
	},
})
