return {
	"stevearc/conform.nvim",
	event = "BufWritePre",
	opts = {
		format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
		formatters_by_ft = {
			lua = { "stylua" },
			javascript = { "prettier" },
			javascriptreact = { "prettier" },
			typescript = { "prettier" },
			typescriptreact = { "prettier" },
			json = { "prettier" },
			jsonc = { "prettier" },
			html = { "prettier" },
			css = { "prettier" },
			scss = { "prettier" },
			markdown = { "prettier" },
			yaml = { "prettier" },
			python = { "black" },
			c = { "clang-format" },
			cpp = { "clang-format" },
			nix = { "nixfmt" },
			ruby = { "rubocop" },
		},
	},
	keys = {
		{
			"<leader>f",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			desc = "Format buffer",
		},
	},
}
