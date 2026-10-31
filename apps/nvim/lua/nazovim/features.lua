local M = {}

function M.setup()
	-- Register commands now; load their implementation only when invoked.
	for _, command in ipairs({ "Template", "TemplateProject" }) do
		vim.api.nvim_create_user_command(command, function(args)
			require("nazovim.template").setup()
			vim.api.nvim_cmd({ cmd = command, args = args.fargs }, {})
		end, {
			nargs = "*",
			complete = function(_, line, pos)
				require("nazovim.template").setup()
				return vim.fn.getcompletion(line:sub(1, pos), "cmdline")
			end,
		})
	end
	-- Diagnostics/progress must be ready before the first LspAttach/notification.
	require("nazovim.diagnostics").setup()
	require("nazovim.progress").setup()
	vim.api.nvim_create_user_command("ToggleTerm", function(opts)
		require("nazovim.terminal").toggle(opts.count > 0 and opts.count or 1)
	end, { count = true, desc = "Toggle floating terminal" })
	vim.keymap.set("n", "<Plug>(jumpcursor-jump)", function()
		require("nazovim.jump").jump()
	end, { silent = true })
	vim.api.nvim_create_autocmd("CmdlineEnter", {
		pattern = ":",
		once = true,
		callback = function()
			require("nazovim.peek").setup()
		end,
	})
	vim.api.nvim_create_autocmd("VimEnter", {
		once = true,
		callback = function()
			vim.schedule(function()
				require("nazovim.statusline").setup()
				require("nazovim.search").setup()
				require("nazovim.colors").setup()
				require("nazovim.todo").setup()
				require("nazovim.references").setup()
				require("nazovim.scrollbar").setup()
				require("nazovim.modes").setup()
				require("nazovim.filename").setup()
			end)
		end,
	})
end

return M
