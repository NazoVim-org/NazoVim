local M = {}
local ns = vim.api.nvim_create_namespace("NazoColors")
local highlights, highlight_count, variables = {}, 0, {}
local css_names = {
	green = 0x008000,
	gray = 0x808080,
	grey = 0x808080,
	maroon = 0x800000,
	purple = 0x800080,
	rebeccapurple = 0x663399,
}

local function byte(value)
	return math.floor(math.max(0, math.min(255, value)) + 0.5)
end

---Parse hex, CSS rgb()/hsl(), and named colors to an RGB integer.
function M.parse(value)
	value = vim.trim(value):lower()
	local hex = value:match("^#(%x+)$")
	if hex then
		if #hex == 3 or #hex == 4 then
			hex = hex:gsub(".", "%0%0")
		end
		if #hex ~= 6 and #hex ~= 8 then
			return
		end
		return tonumber(hex:sub(1, 6), 16)
	end
	local kind, body = value:match("^(%a+)%((.*)%)$")
	if kind then
		local parts = vim.split(body:gsub(",", " "):gsub("/", " "), "%s+", { trimempty = true })
		if #parts < 3 or #parts > 4 then
			return
		end
		if kind == "rgb" or kind == "rgba" then
			local rgb = {}
			for i = 1, 3 do
				local percent = parts[i]:sub(-1) == "%"
				local number = tonumber(percent and parts[i]:sub(1, -2) or parts[i])
				if not number then
					return
				end
				rgb[i] = byte(number * (percent and 2.55 or 1))
			end
			return rgb[1] * 65536 + rgb[2] * 256 + rgb[3]
		elseif kind == "hsl" or kind == "hsla" then
			local hue = tonumber((parts[1]:gsub("deg$", "")))
			local saturation = tonumber(parts[2]:match("^([%d.]+)%%$"))
			local lightness = tonumber(parts[3]:match("^([%d.]+)%%$"))
			if not hue or not saturation or not lightness then
				return
			end
			hue, saturation, lightness = (hue % 360) / 60, math.min(1, saturation / 100), math.min(1, lightness / 100)
			local c = (1 - math.abs(2 * lightness - 1)) * saturation
			local x, m = c * (1 - math.abs(hue % 2 - 1)), lightness - c / 2
			local values = { { c, x, 0 }, { x, c, 0 }, { 0, c, x }, { 0, x, c }, { x, 0, c }, { c, 0, x } }
			local rgb = values[math.floor(hue) + 1]
			return byte((rgb[1] + m) * 255) * 65536 + byte((rgb[2] + m) * 255) * 256 + byte((rgb[3] + m) * 255)
		end
		return
	end
	if css_names[value] then
		return css_names[value]
	end
	-- Neovim ships a color-name database; no plugin or runtime file scan is needed.
	if not value:match("^[a-z]+$") then
		return
	end
	local color = vim.api.nvim_get_color_by_name(value)
	return color >= 0 and color or nil
end

local function group(color)
	if highlights[color] then
		return highlights[color]
	end
	-- Avoid accumulating unbounded global highlight groups in generated palettes.
	if highlight_count >= 512 then
		return
	end
	local name = string.format("NazoColor%06x", color)
	local r, g, b = math.floor(color / 65536), math.floor(color / 256) % 256, color % 256
	vim.api.nvim_set_hl(0, name, { bg = color, fg = (r * 299 + g * 587 + b * 114) > 128000 and 0x16161d or 0xffffff })
	highlights[color] = name
	highlight_count = highlight_count + 1
	return name
end

local function css_variables(buf)
	local tick = vim.api.nvim_buf_get_changedtick(buf)
	if variables[buf] and variables[buf].tick == tick then
		return variables[buf].values
	end
	local values = {}
	if
		vim.api.nvim_buf_line_count(buf) <= 5000
		and vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf)) <= 200000
	then
		for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
			for name, value in line:gmatch("(%-%-[%w_-]+)%s*:%s*([^;}]+)") do
				values[name] = M.parse(value)
			end
		end
	end
	variables[buf] = { tick = tick, values = values }
	return values
end

local function render(buf, rows)
	local vars = css_variables(buf)
	for row in pairs(rows) do
		local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
		if #line <= 4096 then
			local used = {}
			local function add(first, last, color)
				if not color or used[first] then
					return
				end
				local hl = group(color)
				if not hl then
					return
				end
				for col = first, last do
					used[col] = true
				end
				vim.api.nvim_buf_set_extmark(
					buf,
					ns,
					row - 1,
					first - 1,
					{ end_col = last, hl_group = hl, priority = 130 }
				)
			end
			for first, value, after in line:gmatch("()(#%x+)()") do
				add(first, after - 1, M.parse(value))
			end
			for first, value, after in line:gmatch("()(%a+%b())()") do
				local variable = value:match("^var%(%s*(%-%-[%w_-]+)%s*%)$")
				add(first, after - 1, variable and vars[variable] or M.parse(value))
			end
			for first, value, after in line:gmatch("()%f[%a]([%a]+)%f[^%w_-]()") do
				add(first, after - 1, M.parse(value))
			end
		end
	end
end

---Decorate visible color literals, with bounded CSS-variable and highlight caches.
function M.setup()
	local group_id = vim.api.nvim_create_augroup("NazoColorCache", { clear = true })
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group_id,
		callback = function()
			highlights = {}
			highlight_count = 0
		end,
	})
	vim.api.nvim_create_autocmd("BufWipeout", {
		group = group_id,
		callback = function(args)
			variables[args.buf] = nil
		end,
	})
	require("nazovim.ui").decorate("NazoColors", ns, render)
end

return M
