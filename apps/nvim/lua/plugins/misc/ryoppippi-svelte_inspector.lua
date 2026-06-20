return {
	"ryoppippi/vim-svelte-inspector",
	event = "VeryLazy",
	-- flatten: open files from browser devtools in current Neovim instance
	-- fileline: parse file:line:col format from inspector click and jump there
	dependencies = {
		"willothy/flatten.nvim",
		"lewis6991/fileline.nvim",
		"nvim-lua/plenary.nvim",
	},
	config = true,
}
