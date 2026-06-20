return {
	"kevinhwang91/nvim-ufo",
	event = "BufReadPost",
	dependencies = "kevinhwang91/promise-async",
	config = function()
		require("ufo").setup({
			provider_selector = function(_, _, _)
				return { "lsp", "indent" }
			end,
		})
		vim.keymap.set("n", "zR", require("ufo").openAllFolds, { desc = "Open all folds" })
		vim.keymap.set("n", "zM", require("ufo").closeAllFolds, { desc = "Close all folds" })
	end,
}
