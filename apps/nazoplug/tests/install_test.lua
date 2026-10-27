local U = require("nazoplug.util")
local S = require("nazoplug.spec")
local L = require("nazoplug.lock")
local G = require("nazoplug.git")
local I = require("nazoplug.install")

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

local function git(cwd, args)
	local out, err = G.output(args, { cwd = cwd })
	if not out then
		error(string.format("git %s failed: %s", table.concat(args, " "), err))
	end
	return out
end

local function commit(repo, message)
	vim.fn.writefile({ message }, U.join(repo, "file.txt"))
	truthy(G.run({ "add", "." }, { cwd = repo }))
	truthy(G.run({ "commit", "-m", message }, { cwd = repo }))
	return truthy(G.head(repo))
end

local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, "p")
local origin = U.join(tmp, "origin")
local pack_dir = U.join(tmp, "pack")
vim.fn.mkdir(origin, "p")
truthy(G.run({ "init", "-b", "main" }, { cwd = origin }))
truthy(G.run({ "config", "user.email", "test@example.com" }, { cwd = origin }))
truthy(G.run({ "config", "user.name", "Test" }, { cwd = origin }))
local first = commit(origin, "one")
truthy(G.run({ "tag", "v1.0.0" }, { cwd = origin }))
truthy(G.run({ "branch", "v3.x" }, { cwd = origin }))
local second = commit(origin, "two")
truthy(G.run({ "tag", "v1.1.0" }, { cwd = origin }))

local function spec(extra)
	local values = { url = origin, name = "demo.nvim" }
	for key, value in pairs(extra or {}) do
		values[key] = value
	end
	local _, by_name = S.collect({ values }, { pack_dir = pack_dir })
	return by_name[values.name]
end

test("git clone and version checkout", function()
	local s = spec({ version = "^1.0" })
	local entry, err = I.ensure(s, {})
	truthy(entry, err)
	eq(entry.commit, second)
	eq(G.head(s.dir), second)
	eq(G.current_branch(s.dir), nil)
end)

test("git branch checkout and update", function()
	local s = spec({ branch = "v3.x" })
	local entry, err = I.ensure(s, {})
	truthy(entry, err)
	eq(entry.commit, first)
	eq(entry.branch, "v3.x")
	eq(G.current_branch(s.dir), "v3.x")
end)

test("sync restores the locked commit and branch", function()
	local s = spec({ branch = "v3.x" })
	local entry = truthy(I.ensure(s, {}))
	eq(entry.commit, first)
	commit(origin, "four")
	local ok, results, failed = I.sync({ s }, { [s.name] = entry }, {})
	truthy(ok, vim.inspect(failed))
	eq(G.head(s.dir), first)
	eq(G.current_branch(s.dir), "v3.x")
end)

test("git update to new default commit", function()
	local s = spec({})
	truthy(I.ensure(s, {}))
	local third = commit(origin, "three")
	local entry, err = I.ensure(s, { update = true })
	truthy(entry, err)
	eq(entry.commit, third)
	eq(G.head(s.dir), third)
	truthy(I.check(s, { [s.name] = entry }))
end)

test("installer installs dependency before parent", function()
	local child = spec({ name = "child.nvim" })
	local parent = spec({ name = "parent.nvim", dependencies = { { url = origin, name = "child.nvim" } } })
	local lock = {}
	local ok, results = I.install({ parent, child }, lock, { update = false })
	truthy(ok, results)
	truthy(U.is_dir(child.dir))
	truthy(U.is_dir(parent.dir))
	truthy(lock["child.nvim"])
	truthy(lock["parent.nvim"])
end)

test("installer resolves dependencies from by_name for a subset", function()
	local child = spec({ name = "subset-child.nvim" })
	local parent =
		spec({ name = "subset-parent.nvim", dependencies = { { url = origin, name = "subset-child.nvim" } } })
	local by_name = { [child.name] = child, [parent.name] = parent }
	local lock = {}
	local ok, results = I.install({ parent }, lock, { update = false, by_name = by_name })
	truthy(ok, results)
	truthy(U.is_dir(child.dir))
	truthy(U.is_dir(parent.dir))
end)

test("installer can install a dependency selected directly", function()
	local _, by_name = S.collect({
		{
			name = "direct-parent.nvim",
			url = origin,
			dependencies = { { url = origin, name = "direct-child.nvim" } },
		},
	}, { pack_dir = pack_dir })
	local child = by_name["direct-child.nvim"]
	eq(child._.top, false)
	local ok, results = I.install({ child }, {}, { update = false, by_name = by_name })
	truthy(ok, results)
	truthy(U.is_dir(child.dir))
end)

test("build shell hook runs in plugin dir", function()
	local s = spec({ name = "build.nvim", build = "printf built > built.txt" })
	local entry, err = I.ensure(s, {})
	truthy(entry, err)
	eq(U.read_file(U.join(s.dir, "built.txt")), "built")
end)

test("build reruns on update", function()
	local s = spec({ name = "rebuild.nvim", build = "printf x >> built.txt" })
	truthy(I.ensure(s, {}))
	eq(U.read_file(U.join(s.dir, "built.txt")), "x")
	truthy(I.ensure(s, { update = true }))
	eq(U.read_file(U.join(s.dir, "built.txt")), "xx")
end)

test("build failure leaves plugin installed and reports error", function()
	local s = spec({ name = "badbuild.nvim", build = "exit 7" })
	local entry, err = I.ensure(s, {})
	truthy(entry)
	truthy(err)
	eq(G.is_repo(s.dir), true)
end)

test("migrate preserves lock entries for missing plugins", function()
	local installed = spec({ name = "migrated.nvim" })
	truthy(I.ensure(installed, {}))
	local missing = spec({ name = "missing.nvim" })
	local path = U.join(tmp, "migrate-lock.json")
	truthy(L.save(path, { ["missing.nvim"] = { branch = "main", commit = first } }))
	local lock, migrated = I.migrate({ installed, missing }, { lock_path = path })
	truthy(lock, migrated)
	eq(lock["missing.nvim"].commit, first)
	truthy(lock["migrated.nvim"])
	truthy(vim.tbl_contains(migrated, "migrated.nvim") == false)
end)

test("lock save keeps install entries", function()
	local lock = {}
	local s = spec({ name = "lock.nvim" })
	local entry = truthy(I.ensure(s, {}))
	lock[s.name] = entry
	local path = U.join(tmp, "lock.json")
	truthy(L.save(path, lock))
	local loaded = truthy(L.load(path))
	eq(loaded[s.name].commit, entry.commit)
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
