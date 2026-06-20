return {
	"mrcjkb/rustaceanvim",
	version = "^5",
	ft = { "rust" },
	init = function()
		vim.g.rustaceanvim = {
			tools = {
				hover_actions = { auto_focus = false },
			},
			server = {
				on_attach = function(_, bufnr)
					vim.keymap.set("n", "K", function()
						vim.cmd.RustLsp({ "hover", "actions" })
					end, { buffer = bufnr, desc = "Rust hover actions" })

					vim.keymap.set("n", "<leader>rr", function()
						vim.cmd.RustLsp("runnables")
					end, { buffer = bufnr, desc = "Rust runnables" })

					vim.keymap.set("n", "<leader>rd", function()
						vim.cmd.RustLsp("debuggables")
					end, { buffer = bufnr, desc = "Rust debuggables" })

					vim.keymap.set("n", "<leader>rh", function()
						vim.cmd.RustLsp({ "hover", "range" })
					end, { buffer = bufnr, desc = "Rust hover range" })

					vim.keymap.set("n", "<leader>ca", function()
						vim.cmd.RustLsp("codeAction")
					end, { buffer = bufnr, desc = "Rust code action" })
				end,
				settings = {
					["rust-analyzer"] = {
						cargo = { allFeatures = true },
						checkOnSave = { command = "clippy" },
					},
				},
			},
		}
	end,
}
