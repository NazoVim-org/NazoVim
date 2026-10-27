local U = require("nazoplug.util")
local S = require("nazoplug.spec")
local L = require("nazoplug.loader")
local T = require("nazoplug.triggers")

local passed, failed = 0, 0
local failures = {}

local function test(name, fn)
	local ok, err = xpcall(fn, debug.traceback)
	if ok then
		passed = passed + 1
		io.write("ok   " .. name .. "\n")
	else
		failed = failed + 1
		failures[#failures + 1] = { name = name, err = err }
		io.write("FAIL " .. name .. "\n" .. tostring(err) .. "\n")
	end
end

local function eq(actual, expected, label)
	if not vim.deep_equal(actual, expected) then
		error(string.format("%s: expected %s, got %s", label or "value", vim.inspect(expected), vim.inspect(actual)), 2)
	end
end

local function truthy(value, label)
	if not value then
		error((label or "value") .. " is not truthy", 2)
	end
	return value
end

local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, "p")
local pack_dir = U.join(tmp, "pack")

local function plugin_spec(name, init_lua)
	local _, by_name = S.collect(
		{ { name = name, url = "https://example.com/" .. name, dir = U.join(pack_dir, name) } },
		{
			pack_dir = pack_dir,
		}
	)
	local spec = by_name[name]
	truthy(
		U.write_file(
			U.join(spec.dir, "lua/" .. name:gsub("%.nvim$", "") .. ".lua"),
			init_lua or "return { setup = function() end }\n"
		)
	)
	truthy(U.write_file(U.join(spec.dir, "plugin/" .. name:gsub("%.nvim$", "") .. ".lua"), ""))
	spec._.installed = true
	return spec
end

test("loader sources plugin and runs config once", function()
	vim.g.loader_test_config = 0
	vim.g.loader_test_source = 0
	local spec = plugin_spec("loader.nvim", "return { setup = function() end }\n")
	truthy(
		U.write_file(
			U.join(spec.dir, "plugin/loader.lua"),
			"vim.g.loader_test_source = (vim.g.loader_test_source or 0) + 1\n"
		)
	)
	spec.config = function()
		vim.g.loader_test_config = vim.g.loader_test_config + 1
	end
	L.setup({ pack_dir = pack_dir, by_name = { [spec.name] = spec } })
	truthy(L.load(spec, {}))
	eq(vim.g.loader_test_source, 1)
	eq(vim.g.loader_test_config, 1)
	truthy(vim.tbl_contains(vim.opt.rtp:get(), spec.dir))
	truthy(L.load(spec, {}))
	eq(vim.g.loader_test_source, 1)
	eq(vim.g.loader_test_config, 1)
	vim.opt.rtp:remove(spec.dir)
end)

test("loader loads dependencies before parent config", function()
	vim.g.loader_test_order = ""
	local child = plugin_spec("child.nvim")
	child.config = function()
		vim.g.loader_test_order = vim.g.loader_test_order .. "child"
	end
	local parent = plugin_spec("parent.nvim")
	parent.dependencies = { child.name }
	parent.config = function()
		vim.g.loader_test_order = vim.g.loader_test_order .. "parent"
	end
	L.setup({ pack_dir = pack_dir, by_name = { [child.name] = child, [parent.name] = parent } })
	truthy(L.load(parent, {}))
	eq(vim.g.loader_test_order, "childparent")
	vim.opt.rtp:remove(child.dir)
	vim.opt.rtp:remove(parent.dir)
end)

test("cmd trigger loads plugin and preserves args", function()
	vim.g.loader_test_cmd = nil
	local spec = plugin_spec("cmd.nvim")
	truthy(U.write_file(
		U.join(spec.dir, "plugin/cmd.lua"),
		[[
vim.api.nvim_create_user_command("LoaderTestCmd", function(args)
  vim.g.loader_test_cmd = args.args
end, { nargs = "*" })
]]
	))
	spec.cmd = { "LoaderTestCmd" }
	spec.lazy = true
	L.setup({ pack_dir = pack_dir, by_name = { [spec.name] = spec } })
	T.setup({ spec }, { loader = L })
	truthy(vim.fn.exists(":LoaderTestCmd") == 2)
	vim.cmd("LoaderTestCmd hello world")
	eq(vim.g.loader_test_cmd, "hello world")
	truthy(spec._.loaded)
	vim.opt.rtp:remove(spec.dir)
end)

test("event trigger loads plugin once", function()
	local spec = plugin_spec("event.nvim")
	spec.event = { "User LoaderTestEvent" }
	spec.lazy = true
	L.setup({ pack_dir = pack_dir, by_name = { [spec.name] = spec } })
	T.setup({ spec }, { loader = L })
	vim.api.nvim_exec_autocmds("User", { pattern = "LoaderTestEvent" })
	truthy(spec._.loaded)
	vim.opt.rtp:remove(spec.dir)
end)

test("keys trigger creates placeholder and plugin mapping after load", function()
	vim.g.mapleader = " "
	local spec = plugin_spec("keys.nvim")
	truthy(U.write_file(
		U.join(spec.dir, "plugin/keys.lua"),
		[[
vim.keymap.set("n", "<leader>lt", function()
  vim.g.loader_test_key = true
end, { desc = "plugin mapping" })
]]
	))
	spec.keys = { { "<leader>lt", desc = "loader test" } }
	spec.lazy = true
	L.setup({ pack_dir = pack_dir, by_name = { [spec.name] = spec } })
	T.setup({ spec }, { loader = L })
	truthy(vim.fn.maparg("<leader>lt", "n") ~= "")
	truthy(L.load(spec, {}))
	truthy(vim.fn.maparg("<leader>lt", "n") ~= "")
	vim.opt.rtp:remove(spec.dir)
end)

test("keys trigger executes rhs after loading", function()
	vim.g.loader_test_rhs = false
	local spec = plugin_spec("keysrhs.nvim")
	spec.keys = {
		{
			"<F12>",
			function()
				vim.g.loader_test_rhs = true
			end,
		},
	}
	spec.lazy = true
	L.setup({ pack_dir = pack_dir, by_name = { [spec.name] = spec } })
	T.setup({ spec }, { loader = L })
	local key = vim.api.nvim_replace_termcodes("<F12>", true, false, true)
	vim.api.nvim_feedkeys(key, "x", false)
	vim.wait(100, function()
		return vim.g.loader_test_rhs == true
	end, 10)
	eq(vim.g.loader_test_rhs, true)
	vim.opt.rtp:remove(spec.dir)
end)

test("VeryLazy event fires after LazyDone", function()
	local spec = plugin_spec("verylazy.nvim")
	spec.event = { "VeryLazy" }
	spec.lazy = true
	L.setup({ pack_dir = pack_dir, by_name = { [spec.name] = spec } })
	T.setup({ spec }, { loader = L })
	T.fire("VeryLazy")
	truthy(spec._.loaded)
	vim.opt.rtp:remove(spec.dir)
end)

test("build Ex command can use plugin command", function()
	vim.g.loader_test_build = nil
	local spec = plugin_spec("build.nvim")
	truthy(U.write_file(
		U.join(spec.dir, "plugin/build.lua"),
		[[
vim.api.nvim_create_user_command("LoaderTestBuild", function()
  vim.g.loader_test_build = true
end, {})
]]
	))
	spec.build = ":LoaderTestBuild"
	L.setup({ pack_dir = pack_dir, by_name = { [spec.name] = spec } })
	local ok, err = require("nazoplug.install").build(spec, {})
	truthy(ok, err)
	eq(vim.g.loader_test_build, true)
	vim.opt.rtp:remove(spec.dir)
end)

vim.fn.delete(tmp, "rf")
io.write(string.format("\n%d passed, %d failed\n", passed, failed))
if failed > 0 then
	for _, failure in ipairs(failures) do
		io.write("\n" .. failure.name .. "\n" .. failure.err .. "\n")
	end
	vim.cmd("cquit 1")
else
	vim.cmd("qall!")
end
