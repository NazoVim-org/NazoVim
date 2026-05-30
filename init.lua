-- =========================================================
-- Enable bytecode cache (ryoppippi pattern)
-- =========================================================
vim.loader.enable()

-- =========================================================
-- Disable built-in plugins at Neovim core level
-- (before rtp loads them)
-- =========================================================
-- gzip: guard uses exists("loaded_gzip") — no g: prefix, can't set from Lua
-- matchit: guard uses exists("g:loaded_matchit")
vim.g.loaded_matchit = 1
-- matchparen: guard uses exists("g:loaded_matchparen")
vim.g.loaded_matchparen = 1
-- netrw: guard uses exists("g:loaded_netrw")
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- tar: guard uses exists("g:loaded_tarPlugin")
vim.g.loaded_tarPlugin = 1
-- zip: guard uses exists("g:loaded_zipPlugin")
vim.g.loaded_zipPlugin = 1
-- tutor: guard uses exists('g:loaded_tutor_mode_plugin')
vim.g.loaded_tutor_mode_plugin = 1
-- tohtml: guard uses vim.g.loaded_2html_plugin ~= nil
vim.g.loaded_2html_plugin = true
-- rplugin: guard uses exists('g:loaded_remote_plugins')
vim.g.loaded_remote_plugins = 1
-- man: guard uses vim.g.loaded_man ~= nil
vim.g.loaded_man = true
-- shada: guard uses vim.g.loaded_shada_plugin
vim.g.loaded_shada_plugin = 1
-- spellfile: guard uses vim.g.loaded_spellfile_plugin ~= nil
vim.g.loaded_spellfile_plugin = true
-- editorconfig: no guard, uses vim.g.editorconfig to enable/disable
vim.g.editorconfig = false
-- osc52: guard uses vim.g.termfeatures.osc52
vim.g.termfeatures = vim.g.termfeatures or {}
vim.g.termfeatures.osc52 = false

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
