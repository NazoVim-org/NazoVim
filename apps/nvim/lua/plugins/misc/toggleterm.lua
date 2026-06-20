return {
	"akinsho/toggleterm.nvim",
	cmd = "Toggleterm",
	version = "*",
	config = function()
		require("toggleterm").setup({
			direction = "float",
			float_opts = {
				border = "rounded",
			},
		})
	end,
}
