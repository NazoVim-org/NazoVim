-- =========================================================
-- Enable bytecode cache (ryoppippi pattern)
-- =========================================================
vim.loader.enable()

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

-- =========================================================
-- Load configs
-- =========================================================
require("config.options")
require("config.keymaps")
require("config.autocmds")

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
			disabled_plugins = {
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
			},
		},
	},
})
