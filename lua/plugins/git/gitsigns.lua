return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		signs = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
		},
		signcolumn = true,
		watch_gitdir = {
			follow_files = true,
		},
		current_line_blame = false,
		word_diff = true,
		update_debounce = 100,
	},
	keys = {
		{ "<leader>gp", ":Gitsigns preview_hunk<CR>", desc = "Gitsigns preview hunk" },
		{ "<leader>gt", ":Gitsigns toggle_current_line_blame<CR>", desc = "Gitsigns blame toggle" },
	},
}
