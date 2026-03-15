-- =========================================================
-- Bootstrap lazy.nvim
-- =========================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

-- =========================================================
-- Basic UI options
-- =========================================================
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true

-- Insert モード中は relative number を無効化
vim.api.nvim_create_autocmd("InsertEnter", {
	callback = function()
		vim.opt.relativenumber = false
	end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
	callback = function()
		vim.opt.relativenumber = true
	end,
})

-- =========================================================
-- Load configs
-- =========================================================
require("vim-options")
require("lazy").setup("plugins")

-- =========================================================
-- Keymaps
-- =========================================================
local map = vim.keymap.set

-- ---------------------------------------------------------
-- UI / Toggle
-- ---------------------------------------------------------
map("n", "<leader>t", ":ToggleTerm<CR>", {})
map("n", "<leader>c", ":Oil ~/ghq/github.com/nazozokc/dotfiles/<CR>", {})
map("n", "<leader>so", ":SymbolsOutline<CR>")
map("n", "<F2>", ":Twilight<CR>", {})
map("n", "<leader>e", ":TroubleToggle<CR>")

-- ---------------------------------------------------------
-- LSP (Lspsaga / Actions)
-- ---------------------------------------------------------
map("n", "ga", "<cmd>Lspsaga code_action<CR>")
map("n", "gd", "<cmd>Lspsaga goto_definition<CR>")

map("n", "<leader>ca", function()
	require("actions-preview").code_actions()
end, { desc = "Code Action (preview)" })

-- ---------------------------------------------------------
-- Substitute.nvim
-- ---------------------------------------------------------
map("n", "s", require("substitute").operator, { noremap = true })
map("n", "ss", require("substitute").line, { noremap = true })
map("n", "S", require("substitute").eol, { noremap = true })
map("x", "s", require("substitute").visual, { noremap = true })

-- ---------------------------------------------------------
-- Snacks.nvim (Picker / Zen)
-- ---------------------------------------------------------
map("n", "<leader><leader>", function()
	require("snacks.picker").files()
end, { desc = "Files" })

map("n", "<leader>g", function()
	require("snacks.picker").grep()
end, { desc = "Live Grep" })

map("n", "<leader>b", function()
	require("snacks.picker").buffers()
end, { desc = "Buffers" })

map("n", "<leader>r", function()
	require("snacks.picker").recent()
end, { desc = "Recent Files" })

map("n", "<leader>z", function()
	require("snacks").zen.toggle()
end, { desc = "Zen Mode" })

-- ---------------------------------------------------------
-- Dropbar.nvim
-- ---------------------------------------------------------
map("n", "<leader>;", function()
	require("dropbar.api").pick()
end, { desc = "Dropbar pick symbol" })

map("n", "gp", function()
	require("dropbar.api").open()
end, { desc = "Dropbar open" })

-- DAP キーマップ
vim.keymap.set("n", "<F5>", function()
	require("dap").continue()
end)
vim.keymap.set("n", "<F10>", function()
	require("dap").step_over()
end)
vim.keymap.set("n", "<F11>", function()
	require("dap").step_into()
end)
vim.keymap.set("n", "<F12>", function()
	require("dap").step_out()
end)

vim.keymap.set("n", "<leader>db", function()
	require("dap").toggle_breakpoint()
end, { desc = "Toggle Breakpoint" })
vim.keymap.set("n", "<leader>B", function()
	require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end)
