local M = {}
local ns = vim.api.nvim_create_namespace("nazovim.jump")
local labels = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@[;:],./_-^\\1234567890"

function M.jump()
	local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
	local marks = vim.g.jumpcursor_marks or vim.fn.split(labels, "\\zs")
	local function clear()
		if vim.api.nvim_buf_is_valid(buf) then
			vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
		end
	end
	local function choose(positions)
		local lookup = {}
		for i, pos in ipairs(positions) do
			local label = marks[i]
			if not label then
				break
			end
			lookup[label] = pos
			vim.api.nvim_buf_set_extmark(
				buf,
				ns,
				pos[1] - 1,
				pos[2],
				{ virt_text = { { label, "ErrorMsg" } }, virt_text_pos = "overlay" }
			)
		end
		vim.cmd("redraw")
		local ok, key = pcall(vim.fn.getcharstr)
		clear()
		return ok and lookup[key] or nil
	end
	local rows = {}
	for row = vim.fn.line("w0"), vim.fn.line("w$") do
		local text = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
		local col = text:find("%S")
		if col then
			rows[#rows + 1] = { row, col - 1 }
		end
	end
	local selected = choose(rows)
	if not selected then
		return
	end
	local text = vim.api.nvim_buf_get_lines(buf, selected[1] - 1, selected[1], false)[1] or ""
	local cols = {}
	for _, char in ipairs(vim.fn.split(text, "\\zs")) do
		local offset = (cols._offset or 0)
		if not char:match("%s") then
			cols[#cols + 1] = { selected[1], offset }
		end
		cols._offset = offset + #char
	end
	selected = choose(cols)
	if selected and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_set_cursor(win, selected)
	end
end
return M
