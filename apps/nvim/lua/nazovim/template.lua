local M = {}

local function root()
	local configured = vim.g.nazovim_template_dir
	if configured then
		return vim.fn.expand(configured)
	end
	local config = vim.fn.stdpath("config") .. "/template"
	if vim.fn.isdirectory(config) == 1 then
		return config
	end
	local source = debug.getinfo(1, "S").source:sub(2)
	return vim.fs.normalize(vim.fs.dirname(source) .. "/../../../../template")
end

local function list(project)
	local base = root() .. (project and "/project" or "")
	local result = {}
	if vim.fn.isdirectory(base) == 0 then
		return result
	end
	for name, kind in vim.fs.dir(base, { depth = project and 1 or 5 }) do
		if (project and kind == "directory") or (not project and kind == "file" and not name:match("^project/")) then
			result[#result + 1] = name
		end
	end
	table.sort(result)
	return result
end

local function resolve(name, project, ft)
	local choices = list(project)
	for _, item in ipairs(choices) do
		if item == name then
			return item
		end
	end
	local matches = {}
	for _, item in ipairs(choices) do
		if vim.fn.fnamemodify(item, ":t:r") == name then
			local item_ft = vim.filetype.match({ filename = item })
			if not ft or ft == "" or item_ft == ft then
				matches[#matches + 1] = item
			end
		end
	end
	if #matches == 1 then
		return matches[1]
	end
	error(#matches > 1 and "Ambiguous template: use its full relative path" or "Template not found: " .. name)
end

---Expand the bundled template placeholders; unknown placeholders remain literal.
function M.expand(lines, filename)
	local stem = vim.fn.fnamemodify(filename, ":t:r")
	local values = {
		file_name = stem,
		upper_file = stem:upper(),
		camel_case_file = (stem:gsub("^%l", string.upper):gsub("[_%-](%w)", string.upper)),
		date = os.date("%Y-%m-%d"),
		author = vim.g.nazovim_template_author or "nazozokc",
		email = vim.g.nazovim_template_email or "",
		cursor = "",
	}
	local output, cursor = {}, nil
	for row, line in ipairs(lines) do
		local expanded = line:gsub("{{_([%w_]+)_}}", function(key)
			return key == "cursor" and "{{_cursor_}}" or values[key]
		end)
		local col = expanded:find("{{_cursor_}}", 1, true)
		if col and not cursor then
			cursor = { row, col - 1 }
		end
		output[row] = expanded:gsub("{{_cursor_}}", "")
	end
	return output, cursor
end

---Insert a template into the current buffer, or open a named destination first.
function M.insert(name, destination)
	local ft = destination and vim.filetype.match({ filename = destination }) or vim.bo.filetype
	local selected = resolve(name, false, ft)
	local lines = vim.fn.readfile(root() .. "/" .. selected)
	if destination then
		vim.cmd.edit({ args = { destination } })
	end
	if not vim.bo.modifiable or vim.bo.buftype ~= "" then
		error("Template requires a modifiable file buffer")
	end
	local expanded, cursor = M.expand(lines, vim.api.nvim_buf_get_name(0))
	local empty = vim.api.nvim_buf_line_count(0) == 1 and vim.api.nvim_get_current_line() == ""
	local start = empty and 0 or vim.api.nvim_win_get_cursor(0)[1]
	vim.api.nvim_buf_set_lines(0, start, empty and 1 or start, false, expanded)
	if cursor then
		vim.api.nvim_win_set_cursor(0, { start + cursor[1], cursor[2] })
	end
end

---Generate a project into a new directory; refuse any existing destination.
function M.project(name, destination)
	local selected = resolve(name, true)
	local source = root() .. "/project/" .. selected
	local target = vim.fs.normalize(vim.fn.fnamemodify(destination, ":p")):gsub("/$", "")
	if vim.uv.fs_lstat(target) then
		error("Project destination already exists: " .. target)
	end
	-- Read and validate everything before creating any files.
	local files = {}
	for path, kind in vim.fs.dir(source, { depth = 20 }) do
		if kind == "link" then
			error("Project templates cannot contain symbolic links: " .. path)
		end
		if kind == "file" then
			files[#files + 1] = { path = path, lines = M.expand(vim.fn.readfile(source .. "/" .. path), path) }
		end
	end
	if #files == 0 then
		error("Project template is empty")
	end
	vim.fn.mkdir(target, "p")
	for _, file in ipairs(files) do
		local path = target .. "/" .. file.path
		vim.fn.mkdir(vim.fs.dirname(path), "p")
		if vim.fn.writefile(file.lines, path) ~= 0 then
			error("Could not write template: " .. path)
		end
	end
	vim.notify("Created project: " .. target)
end

---Register Template [name] / Template destination name and TemplateProject name destination.
function M.setup()
	local function run(callback)
		local ok, err = pcall(callback)
		if not ok then
			vim.notify(tostring(err), vim.log.levels.ERROR, { title = "NazoVim templates" })
		end
	end
	vim.api.nvim_create_user_command("Template", function(args)
		if #args.fargs > 2 then
			vim.notify("Usage: Template [name] or Template destination name", vim.log.levels.ERROR)
			return
		end
		if #args.fargs == 0 then
			local buf = vim.api.nvim_get_current_buf()
			vim.ui.select(list(false), { prompt = "Template:" }, function(name)
				if name and vim.api.nvim_buf_is_valid(buf) then
					run(function()
						vim.api.nvim_set_current_buf(buf)
						M.insert(name)
					end)
				end
			end)
		else
			run(function()
				M.insert(args.fargs[2] or args.fargs[1], args.fargs[2] and args.fargs[1] or nil)
			end)
		end
	end, {
		nargs = "*",
		complete = function()
			return list(false)
		end,
		desc = "Insert a file template",
	})
	vim.api.nvim_create_user_command("TemplateProject", function(args)
		run(function()
			if #args.fargs ~= 2 then
				error("Usage: TemplateProject name destination")
			end
			M.project(args.fargs[1], args.fargs[2])
		end)
	end, {
		nargs = "+",
		complete = function()
			return list(true)
		end,
		desc = "Create a project from a template",
	})
end

return M
