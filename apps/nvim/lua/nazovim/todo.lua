local M = {}
local ns = vim.api.nvim_create_namespace("NazoTodo")
local kinds = {
	TODO = "Todo",
	FIX = "DiagnosticError",
	FIXME = "DiagnosticError",
	BUG = "DiagnosticError",
	ISSUE = "DiagnosticError",
	FIXIT = "DiagnosticError",
	HACK = "DiagnosticWarn",
	WARN = "DiagnosticWarn",
	WARNING = "DiagnosticWarn",
	XXX = "DiagnosticWarn",
	PERF = "DiagnosticInfo",
	OPTIM = "DiagnosticInfo",
	PERFORMANCE = "DiagnosticInfo",
	OPTIMIZE = "DiagnosticInfo",
	NOTE = "DiagnosticHint",
	INFO = "DiagnosticHint",
	TEST = "DiagnosticInfo",
	TESTING = "DiagnosticInfo",
	PASSED = "DiagnosticHint",
	FAILED = "DiagnosticError",
}
local job

---Extract keyword ranges from a line (byte columns, with a required colon).
function M.matches(line)
	local result = {}
	for first, word, after in line:gmatch("()%f[%w_]([A-Z]+)%f[^%w_]:()") do
		if kinds[word] then
			result[#result + 1] = { first = first - 1, last = after - 1, word = word, hl = kinds[word] }
		end
	end
	return result
end

local function comment(buf, row, col, line)
	local ok, node = pcall(vim.treesitter.get_node, { bufnr = buf, pos = { row, col } })
	if ok and node then
		while node do
			if node:type():find("comment") then
				return true
			end
			node = node:parent()
		end
		return false
	end
	local syntax = vim.api.nvim_buf_call(buf, function()
		return vim.fn.synIDattr(vim.fn.synID(row + 1, col + 1, 1), "name")
	end)
	if syntax:lower():find("comment") then
		return true
	end
	if syntax:lower():find("string") then
		return false
	end
	local prefix = vim.bo[buf].commentstring:match("^(.-)%%s")
	prefix = prefix and vim.trim(prefix)
	if not prefix or prefix == "" then
		return false
	end
	-- Fallback for buffers without parsers/syntax: skip quoted strings before the comment.
	local quote, i = nil, 1
	while i <= col + 1 do
		local char = line:sub(i, i)
		if quote then
			if char == "\\" then
				i = i + 1
			elseif char == quote then
				quote = nil
			end
		elseif line:sub(i, i + #prefix - 1) == prefix then
			return true
		elseif char == '"' or char == "'" or char == "`" then
			quote = char
		end
		i = i + 1
	end
	return false
end

local function render(buf, rows)
	for row in pairs(rows) do
		local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
		if #line <= 4096 then
			for _, item in ipairs(M.matches(line)) do
				if comment(buf, row - 1, item.first, line) then
					vim.api.nvim_buf_set_extmark(
						buf,
						ns,
						row - 1,
						item.first,
						{ end_col = item.last, hl_group = item.hl, priority = 140 }
					)
				end
			end
		end
	end
end

---Search the project asynchronously and publish TODO candidates to quickfix/location list.
function M.search(loclist)
	if vim.fn.executable("rg") == 0 then
		vim.notify("Todo search requires ripgrep (rg)", vim.log.levels.ERROR)
		return
	end
	if job then
		job:kill(15)
	end
	local words = vim.tbl_keys(kinds)
	table.sort(words)
	local cwd, win = vim.fn.getcwd(), vim.api.nvim_get_current_win()
	local current
	current = vim.system(
		{ "rg", "--json", "--glob", "!.git", "--", "\\b(" .. table.concat(words, "|") .. "):", "." },
		{ cwd = cwd, text = true },
		function(result)
			vim.schedule(function()
				if job ~= current then
					return
				end
				job = nil
				if result.code > 1 then
					vim.notify(result.stderr, vim.log.levels.ERROR)
					return
				end
				local items = {}
				for line in result.stdout:gmatch("[^\n]+") do
					local entry = vim.json.decode(line)
					if entry.type == "match" and entry.data.path.text and entry.data.lines.text then
						for _, match in ipairs(entry.data.submatches) do
							items[#items + 1] = {
								filename = cwd .. "/" .. entry.data.path.text,
								lnum = entry.data.line_number,
								col = match.start + 1,
								text = vim.trim(entry.data.lines.text),
							}
						end
					end
				end
				if loclist then
					if vim.api.nvim_win_is_valid(win) then
						vim.fn.setloclist(win, {}, "r", { title = "TODO", items = items })
						vim.api.nvim_win_call(win, function()
							vim.cmd.lopen()
						end)
					end
				else
					vim.fn.setqflist({}, "r", { title = "TODO", items = items })
					vim.cmd.copen()
				end
			end)
		end
	)
	job = current
end

---Highlight comments and expose project-search commands without plugin dependencies.
function M.setup()
	require("nazovim.ui").decorate("NazoTodo", ns, render)
	vim.api.nvim_create_user_command("TodoQuickFix", function()
		M.search(false)
	end, { desc = "Find project TODOs" })
	vim.api.nvim_create_user_command("TodoLocList", function()
		M.search(true)
	end, { desc = "Find project TODOs in a location list" })
	vim.api.nvim_create_user_command("TodoTelescope", function()
		M.search(false)
	end, { desc = "Find project TODOs (quickfix)" })
	vim.api.nvim_create_user_command("TodoTrouble", function()
		M.search(false)
	end, { desc = "Find project TODOs (quickfix)" })
end

return M
