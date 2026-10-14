-- Le picker d'éléments en Neovim enfant, contre la CLI `list-dir` réelle, sur un registre de
-- dette temporaire.

local new_set = MiniTest.new_set
local expect = MiniTest.expect

local child = MiniTest.new_child_neovim()

local dir

---@param args string[]
local function list_dir(args)
	local res = vim.system(vim.list_extend({ "list-dir" }, args), { text = true }):wait()
	assert(res.code == 0, res.stderr)
end

---Attend, dans l'enfant, le picker `listdir_items` ouvert et son finder terminé.
local function wait_picker()
	child.lua([[
		vim.wait(3000, function()
			local picker = Snacks.picker.get({ source = "listdir_items" })[1]
			return picker ~= nil and not picker:is_active()
		end, 10)
	]])
end

local T = new_set({
	hooks = {
		pre_once = function()
			dir = vim.fn.tempname()
			list_dir({ "init", "--def", "technical-debt", dir })
			list_dir({ "new", dir, "une-dette" })
		end,
		pre_case = function()
			child.restart({ "-u", "tests/minimal_init.lua" })
			child.lua("_G.dir = ...", { dir })
		end,
		post_once = child.stop,
	},
})

T["resume"] = new_set()

T["resume"]["l'indicateur suit le tri en cours"] = function()
	child.lua([[
		local items = require("listdir.picker.items")
		items.open(_G.dir, assert(require("listdir.contract").read(_G.dir)))
	]])
	wait_picker()
	local initial = child.lua_get([[Snacks.picker.get({ source = "listdir_items" })[1].title]])

	child.lua([[
		local picker = Snacks.picker.get({ source = "listdir_items" })[1]
		picker:action("ld_sort_next")
	]])
	wait_picker()
	local sorted = child.lua_get([[Snacks.picker.get({ source = "listdir_items" })[1].title]])
	expect.no_equality(sorted, initial)

	child.lua([[
		Snacks.picker.get({ source = "listdir_items" })[1]:close()
		Snacks.picker.resume({ source = "listdir_items" })
	]])
	wait_picker()
	expect.equality(child.lua_get([[Snacks.picker.get({ source = "listdir_items" })[1].title]]), sorted)
end

T["options"] = new_set()

---@param opts Ozay.ListDir.ItemsOpts
---@return Ozay.ListDir.ItemsState
local function state(opts)
	local items = require("listdir.picker.items")
	return items.state(dir, assert(require("listdir.contract").read(dir)), opts)
end

T["options"]["clés fixes autour du champ du cycle"] = function()
	local s = state({ before = { "-pin" }, after = { "-date", "-severite" } })
	expect.equality(require("listdir.picker.items").keys(s), { "-pin", "title", "-date", "-severite" })
end

T["options"]["une clé fixe sur le champ courant est omise"] = function()
	local items = require("listdir.picker.items")
	local s = state({ before = { "-pin" }, after = { "-date", "-severite" } })
	s.field, s.reverse = "date", false
	expect.equality(items.keys(s), { "-pin", "date", "-severite" })
end

T["options"]["skip sort un champ du cycle"] = function()
	local names = vim.tbl_map(function(field)
		return field.name
	end, state({ skip = { "pin" } }).fields)
	expect.equality(vim.tbl_contains(names, "pin"), false)
end

T["options"]["decorate et title"] = function()
	local items = require("listdir.picker.items")
	local s = state({
		decorate = function(entry)
			return { prefix = { { "★ ", "Special" } }, label = "Error" }
		end,
		title = function(st)
			return items.indicator(st) .. "  !"
		end,
	})
	expect.equality(items.title(s), "technical-debt  ↑ title  !")
	local ctx = { filter = { filter = function(_, list) return list end } }
	local entry = items.finder(s, ctx)[1]
	local chunks = items.format(entry, {})
	expect.equality(chunks[1], { "★ ", "Special" })
	expect.equality(chunks[#chunks], { entry.text, "Error" })
end

return T
