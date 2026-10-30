return {
	"nvim-neo-tree/neo-tree.nvim",
	event = "VeryLazy",
	cmd = "Neotree",
	keys = {
		{ "<leader>n", "<cmd>Neotree filesystem reveal right<cr>", desc = "NeoTree filesystem" },
		{ "<leader>bf", "<cmd>Neotree buffers reveal float<cr>", desc = "NeoTree buffers" },
	},
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		vim.keymap.set("n", "<leader>n", ":Neotree filesystem reveal right<CR>", { desc = "NeoTree filesystem" })
		vim.keymap.set("n", "<leader>bf", ":Neotree buffers reveal float<CR>", { desc = "NeoTree buffers" })
	end,
}
