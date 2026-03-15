return {
	"vim-test/vim-test",
	event = "VeryLazy",
	dependencies = {
		"preservim/vimux",
	},
	config = function()
		vim.keymap.set("n", "<leader>vt", ":TestNearest<CR>", {})
		vim.keymap.set("n", "<leader>VT", ":TestFile<CR>", {})
		vim.keymap.set("n", "<leader>va", ":TestSuite<CR>", {})
		vim.keymap.set("n", "<leader>vl", ":TestLast<CR>", {})
		vim.keymap.set("n", "<leader>vg", ":TestVisit<CR>", {})
		vim.cmd("let test#strategy = 'vimux'")
	end,
}
