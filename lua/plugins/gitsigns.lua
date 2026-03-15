return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		signs = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
		},

		signcolumn = true, -- 左端に常時表示
		watch_gitdir = {
			follow_files = true,
		},

		current_line_blame = false, -- ← 後で有効にする
		word_diff = true, -- 🔥 単語単位差分
		update_debounce = 100,
	},
}
