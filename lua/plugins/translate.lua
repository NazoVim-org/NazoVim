return {
	{
		"uga-rosa/translate.nvim",
		cmd = { "Translate" },
		config = function()
			require("translate").setup({
				default = {
					command = "google", -- 使用する翻訳サービス
					from = "auto", -- 原文言語
					to = "ja", -- 翻訳先言語
				},
				keymaps = {
					i = "<C-s>", -- 挿入モードで翻訳
					n = "<Leader>t", -- ノーマルモードで翻訳
					v = "<Leader>t", -- ビジュアルモードで翻訳
				},
			})
		end,
	},
}
