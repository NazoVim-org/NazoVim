local M = {}
local terminals = {}

local function geometry()
	local width = math.max(1, math.floor(vim.o.columns * 0.8))
	local height = math.max(1, math.floor((vim.o.lines - vim.o.cmdheight) * 0.8))
	return {
		relative = "editor",
		style = "minimal",
		border = "rounded",
		width = width,
		height = height,
		row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
		col = math.max(0, math.floor((vim.o.columns - width) / 2)),
	}
end

function M.toggle(id)
	local term = terminals[id] or {}
	terminals[id] = term
	if term.win and vim.api.nvim_win_is_valid(term.win) then
		vim.api.nvim_win_close(term.win, true)
		term.win = nil
		return
	end
	local fresh = not term.buf or not vim.api.nvim_buf_is_valid(term.buf)
	if fresh then
		term.buf = vim.api.nvim_create_buf(false, true)
		vim.bo[term.buf].bufhidden = "hide"
	end
	term.win = vim.api.nvim_open_win(term.buf, true, geometry())
	if fresh then
		vim.fn.termopen(vim.o.shell, {
			on_exit = function()
				vim.schedule(function()
					if term.win and vim.api.nvim_win_is_valid(term.win) then
						vim.api.nvim_win_close(term.win, true)
					end
					if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
						vim.api.nvim_buf_delete(term.buf, { force = true })
					end
					terminals[id] = nil
				end)
			end,
		})
		vim.keymap.set("t", "<leader>t", function()
			M.toggle(id)
		end, { buffer = term.buf, desc = "Toggle terminal" })
	end
	vim.cmd("startinsert")
end

vim.api.nvim_create_autocmd("VimResized", {
	callback = function()
		for _, term in pairs(terminals) do
			if term.win and vim.api.nvim_win_is_valid(term.win) then
				vim.api.nvim_win_set_config(term.win, geometry())
			end
		end
	end,
})

return M
