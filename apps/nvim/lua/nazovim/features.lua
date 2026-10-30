local M = {}

function M.setup()
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
				require("nazovim.modes").setup()
				require("nazovim.filename").setup()
			end)
		end,
	})
end

return M
