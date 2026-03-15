return {
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		event = "BufReadPre",
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- ===== 共通 on_attach =====
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					local bufnr = args.buf

					-- ts_ls の semanticTokens を無効化（重い）
					if client and client.name == "ts_ls" then
						client.server_capabilities.semanticTokensProvider = nil
					end

					local opts = { buffer = bufnr }
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, opts)
					vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
				end,
			})

			-- ===== HTML =====
			vim.lsp.config("html", {
				capabilities = capabilities,
			})

			-- ===== Lua =====
			vim.lsp.config("lua_ls", {
				capabilities = capabilities,
				settings = {
					Lua = {
						diagnostics = {
							globals = { "vim" },
						},
					},
				},
			})

			-- ===== Ruby =====
			vim.lsp.config("solargraph", {
				capabilities = capabilities,
			})

			-- ===== JavaScript / TypeScript =====
			vim.lsp.config("ts_ls", {
				capabilities = capabilities,
				cmd = { "typescript-language-server", "--stdio" },
				filetypes = {
					"javascript",
					"javascriptreact",
					"typescript",
					"typescriptreact",
				},
				root_dir = vim.fs.root(0, {
					"package.json",
					"tsconfig.json",
					".git",
				}),
			})

			vim.lsp.config("nixd", {
				capabilities = capabilities,
			})

			vim.lsp.config("efm", {
				capabilities = capabilities,
			})

			vim.lsp.config("clang", {
				capabilities = capabilities,
			})

			-- ===== 有効化 =====

			-- ===== Java =====
			vim.lsp.config("jdtls", {
				capabilities = capabilities,
				cmd = { "jdtls" },
				root_dir = vim.fs.root(0, { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }),
			})

			vim.lsp.enable({
				"html",
				"lua_ls",
				"solargraph",
				"efm",
				"ts_ls",
				"clang",
				"nixd",
				"jdtls",
			})
		end,
	},
}
