local M = {}
local branches, pending, diagnostics = {}, {}, {}
local modes = {
	n = "NORMAL",
	i = "INSERT",
	v = "VISUAL",
	V = "V-LINE",
	["\22"] = "V-BLOCK",
	c = "COMMAND",
	R = "REPLACE",
	t = "TERMINAL",
	s = "SELECT",
}

local function escape(value)
	return tostring(value):gsub("[\r\n]", " "):gsub("%%", "%%%%")
end

local function refresh_branch()
	local buf = vim.api.nvim_get_current_buf()
	if not require("nazovim.ui").normal(buf) or vim.fn.executable("git") == 0 then
		return
	end
	local name = vim.api.nvim_buf_get_name(buf)
	local dir = name == "" and vim.fn.getcwd() or vim.fs.dirname(name)
	vim.b[buf].nazovim_git_dir = dir
	if pending[dir] then
		return
	end
	pending[dir] = true
	vim.system({ "git", "-C", dir, "rev-parse", "--abbrev-ref", "HEAD" }, { text = true }, function(result)
		vim.schedule(function()
			pending[dir] = nil
			branches[dir] = result.code == 0 and vim.trim(result.stdout) or ""
			vim.cmd.redrawstatus()
		end)
	end)
end

---Render a statusline using cached metadata; never perform I/O during redraw.
function M.render()
	local buf = vim.api.nvim_get_current_buf()
	local mode = modes[vim.api.nvim_get_mode().mode:sub(1, 1)] or "NORMAL"
	local branch = vim.b[buf].gitsigns_head or branches[vim.b[buf].nazovim_git_dir] or ""
	local diff = vim.b[buf].gitsigns_status or ""
	local counts = diagnostics[buf] or {}
	local diag = {}
	for severity, label in ipairs({ "E", "W", "I", "H" }) do
		if (counts[severity] or 0) > 0 then
			diag[#diag + 1] = label .. counts[severity]
		end
	end
	return "%#StatusLine# "
		.. mode
		.. (branch ~= "" and " │ " .. escape(branch) or "")
		.. (diff ~= "" and " " .. escape(diff) or "")
		.. " │ %<%f %m%r "
		.. table.concat(diag, " ")
		.. "%= "
		.. escape(vim.bo[buf].fileencoding ~= "" and vim.bo[buf].fileencoding or vim.o.encoding)
		.. " │ "
		.. escape(vim.bo[buf].fileformat)
		.. " │ %y │ %p%% │ %l:%c "
end

---Enable the global statusline and event-driven metadata updates.
function M.setup()
	vim.o.laststatus = 3
	vim.o.statusline = "%!v:lua.require'nazovim.statusline'.render()"
	local group = vim.api.nvim_create_augroup("NazoStatusline", { clear = true })
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "FocusGained", "TermClose", "DirChanged" }, {
		group = group,
		callback = require("nazovim.ui").throttle(100, refresh_branch),
	})
	vim.api.nvim_create_autocmd("DiagnosticChanged", {
		group = group,
		callback = function(args)
			diagnostics[args.buf] = vim.diagnostic.count(args.buf)
			vim.cmd.redrawstatus()
		end,
	})
	vim.api.nvim_create_autocmd("BufWipeout", {
		group = group,
		callback = function(args)
			diagnostics[args.buf] = nil
		end,
	})
	vim.api.nvim_create_autocmd("ModeChanged", {
		group = group,
		callback = function()
			vim.cmd.redrawstatus()
		end,
	})
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		diagnostics[buf] = vim.diagnostic.count(buf)
	end
	refresh_branch()
end

return M
