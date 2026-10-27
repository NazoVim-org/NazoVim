local U = require("nazoplug.util")
local S = require("nazoplug.spec")

local M = {}

M.group = nil
M.active = {}
M.created = {}
M.loading = {}

local event_mappings = {
	VeryLazy = { id = "VeryLazy", event = "User", pattern = "VeryLazy" },
}
event_mappings["User VeryLazy"] = event_mappings.VeryLazy

local function load_spec(spec, reason)
	if spec._.loaded or not S.is_enabled(spec) then
		return
	end
	if M.loader then
		M.loader.load(spec, reason)
	end
end

local function parse_event(value)
	if type(value) == "string" then
		local mapping = event_mappings[value]
		if mapping then
			return mapping
		end
		local event, pattern = value:match("^(%w+)%s+(.*)$")
		if event then
			return { id = value, event = event, pattern = pattern }
		end
		return { id = value, event = value }
	end
	if U.is_list(value) then
		return { id = table.concat(value, "|"), event = value }
	end
	if type(value) == "table" then
		local event = value.event or value[1]
		if not event then
			return nil, "event is missing"
		end
		local pattern = value.pattern
		local id = value.id
		if not id then
			id = type(event) == "string" and event or table.concat(event, "|")
			if pattern then
				id = id .. " " .. (type(pattern) == "string" and pattern or table.concat(pattern, ", "))
			end
		end
		return { id = id, event = event, pattern = pattern }
	end
	return nil, "invalid event: " .. vim.inspect(value)
end

local function fire(id)
	local specs = M.active[id]
	if not specs then
		return
	end
	M.active[id] = nil
	for _, spec in ipairs(specs) do
		load_spec(spec, { event = id })
	end
end

local function add_event(id, event, pattern)
	if M.created[id] then
		return
	end
	M.created[id] = true
	vim.api.nvim_create_autocmd(event, {
		group = M.group,
		once = true,
		pattern = pattern,
		callback = function()
			fire(id)
		end,
	})
end

local function add_event_spec(spec, value)
	local event, err = parse_event(value)
	if not event then
		U.warn(string.format("invalid event for %s: %s", spec.name, err))
		return
	end
	M.active[event.id] = M.active[event.id] or {}
	M.active[event.id][#M.active[event.id] + 1] = spec
	add_event(event.id, event.event, event.pattern)
end

local function add_ft_spec(spec)
	if not spec.ft then
		return
	end
	local filetypes = type(spec.ft) == "string" and { spec.ft } or spec.ft
	local id = "FileType " .. table.concat(filetypes, ",")
	M.active[id] = M.active[id] or {}
	M.active[id][#M.active[id] + 1] = spec
	add_event(id, "FileType", filetypes)
end

local function command_exists(name)
	return vim.fn.exists(":" .. name) == 2
end

local function setup_cmd(spec)
	for _, name in ipairs(spec.cmd or {}) do
		if type(name) ~= "string" or name == "" then
			U.warn(string.format("invalid command for %s", spec.name))
		elseif name:find("%s") then
			U.warn(string.format("command %q contains whitespace and cannot be lazy-loaded", name))
		elseif M.created["cmd:" .. name] then
			-- Another spec already owns this lazy command.
		elseif command_exists(name) then
			U.warn(string.format("command %s already exists; not creating a lazy command", name))
		else
			M.created["cmd:" .. name] = spec.name
			local ok, err = pcall(vim.api.nvim_create_user_command, name, function(args)
				pcall(vim.api.nvim_del_user_command, name)
				load_spec(spec, { cmd = name })
				local info = vim.api.nvim_get_commands({})[name] or vim.api.nvim_buf_get_commands(0, {})[name]
				if not info then
					U.warn(string.format("command %s was not defined by %s", name, spec.name))
					return
				end
				local command = {
					cmd = name,
					bang = args.bang or nil,
					mods = args.smods,
					args = args.fargs,
				}
				if args.range == 1 then
					command.range = { args.line1 }
				elseif args.range == 2 then
					command.range = { args.line1, args.line2 }
				elseif args.count >= 0 then
					command.count = args.count
				end
				command.nargs = info.nargs
				if args.args and args.args ~= "" and info.nargs and info.nargs:find("[1?]") then
					command.args = { args.args }
				end
				local cmd_ok, cmd_err = pcall(vim.cmd, command)
				if not cmd_ok then
					U.warn(string.format("command %s failed: %s", name, cmd_err))
				end
			end, {
				bang = true,
				range = true,
				nargs = "*",
				complete = function(_, line)
					pcall(vim.api.nvim_del_user_command, name)
					load_spec(spec, { cmd = name })
					return vim.fn.getcompletion(line, "cmdline")
				end,
			})
			if not ok then
				U.warn(string.format("failed to create command %s: %s", name, err))
			end
		end
	end
end

local function parse_key(value)
	value = type(value) == "string" and { value } or vim.deepcopy(value)
	if type(value) ~= "table" then
		return nil
	end
	local lhs = value[1]
	if type(lhs) ~= "string" or lhs == "" then
		return nil
	end
	local rhs = value[2]
	if rhs == vim.NIL or rhs == false then
		return nil
	end
	local mode = value.mode or "n"
	local modes = type(mode) == "table" and mode or { mode }
	return {
		lhs = lhs,
		rhs = rhs,
		modes = modes,
		ft = value.ft,
		desc = value.desc,
		nowait = value.nowait,
		silent = value.silent,
		remap = value.remap,
	}
end

local function key_opts(keys)
	return {
		desc = keys.desc,
		nowait = keys.nowait,
		silent = keys.silent,
		remap = keys.remap,
	}
end

local function feed_lhs(lhs)
	local termcodes = vim.api.nvim_replace_termcodes("<Ignore>" .. lhs, true, true, true)
	vim.api.nvim_feedkeys(termcodes, "i", false)
end

local function add_key(spec, keys, buf)
	for _, mode in ipairs(keys.modes) do
		local opts = key_opts(keys)
		opts.expr = true
		opts.buffer = buf
		vim.keymap.set(mode, keys.lhs, function()
			pcall(vim.keymap.del, mode, keys.lhs, { buffer = buf })
			load_spec(spec, { keys = keys.lhs })
			if keys.rhs then
				local rhs_opts = key_opts(keys)
				rhs_opts.buffer = buf
				vim.keymap.set(mode, keys.lhs, keys.rhs, rhs_opts)
			end
			feed_lhs(keys.lhs)
		end, opts)
	end
end

local function setup_keys(spec)
	for _, value in ipairs(spec.keys or {}) do
		local keys = parse_key(value)
		if keys then
			if keys.ft then
				local filetypes = type(keys.ft) == "string" and { keys.ft } or keys.ft
				vim.api.nvim_create_autocmd("FileType", {
					group = M.group,
					pattern = filetypes,
					callback = function(args)
						add_key(spec, keys, args.buf)
					end,
				})
				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					if vim.api.nvim_buf_is_loaded(buf) and vim.tbl_contains(filetypes, vim.bo[buf].filetype) then
						add_key(spec, keys, buf)
					end
				end
			else
				add_key(spec, keys, nil)
			end
		end
	end
end

local function schedule_very_lazy()
	if M.very_lazy_scheduled then
		return
	end
	M.very_lazy_scheduled = true
	local function fire_very_lazy()
		if vim.v.exiting ~= vim.NIL then
			return
		end
		vim.schedule(function()
			if vim.v.exiting ~= vim.NIL then
				return
			end
			vim.g.did_very_lazy = true
			vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy", modeline = false })
		end)
	end
	vim.api.nvim_create_autocmd("User", {
		group = M.group,
		pattern = "LazyDone",
		once = true,
		callback = function()
			if vim.v.vim_did_enter == 1 then
				fire_very_lazy()
			else
				vim.api.nvim_create_autocmd("UIEnter", {
					group = M.group,
					once = true,
					callback = fire_very_lazy,
				})
			end
		end,
	})
end

function M.disable(spec)
	for _, name in ipairs(spec.cmd or {}) do
		if type(name) == "string" and not name:find("%s") and M.created["cmd:" .. name] == spec.name then
			pcall(vim.api.nvim_del_user_command, name)
			M.created["cmd:" .. name] = nil
		end
	end
	for _, value in ipairs(spec.keys or {}) do
		local keys = parse_key(value)
		if keys then
			for _, mode in ipairs(keys.modes) do
				if keys.ft then
					local filetypes = type(keys.ft) == "string" and { keys.ft } or keys.ft
					for _, buf in ipairs(vim.api.nvim_list_bufs()) do
						if vim.api.nvim_buf_is_loaded(buf) and vim.tbl_contains(filetypes, vim.bo[buf].filetype) then
							pcall(vim.keymap.del, mode, keys.lhs, { buffer = buf })
						end
					end
				else
					pcall(vim.keymap.del, mode, keys.lhs)
				end
			end
		end
	end
end

function M.setup(specs, opts)
	opts = opts or {}
	M.loader = opts.loader or require("nazoplug.loader")
	M.group = vim.api.nvim_create_augroup("NazoPlug", { clear = true })
	M.active = {}
	M.created = {}
	M.loading = {}
	M.very_lazy_scheduled = false
	for _, spec in ipairs(specs) do
		if S.is_enabled(spec) then
			for _, value in ipairs(spec.event or {}) do
				add_event_spec(spec, value)
			end
			add_ft_spec(spec)
			setup_cmd(spec)
			setup_keys(spec)
		end
	end
	schedule_very_lazy()
end

function M.fire(id)
	fire(id)
end

return M
