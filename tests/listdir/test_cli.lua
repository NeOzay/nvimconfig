-- `cli.list`, le contrat et l'état de tri, contre la CLI `list-dir` réelle, sur un registre de
-- dette temporaire : c'est la CLI qui trie, et c'est son contrat que ces tests exercent.

local new_set = MiniTest.new_set
local expect = MiniTest.expect

local cli = require("listdir.cli")
local contract = require("listdir.contract")
local items = require("listdir.picker.items")

---Registre `technical-debt` à trois dettes : `ancienne` et `recente` datées, `sans-date` restée
---au Marqueur ; `recente` épinglée.
local dir

---@param args string[]
local function list_dir(args)
	local res = vim.system(vim.list_extend({ "list-dir" }, args), { text = true }):wait()
	assert(res.code == 0, res.stderr)
end

---@param rows Ozay.ListDir.Row[]?
---@return string[]
local function ids(rows)
	return vim.tbl_map(function(row)
		return row.id
	end, assert(rows))
end

local T = new_set({
	hooks = {
		pre_once = function()
			dir = vim.fn.tempname()
			list_dir({ "init", "--def", "technical-debt", dir })
			for _, id in ipairs({ "ancienne", "recente", "sans-date" }) do
				list_dir({ "new", dir, id })
			end
			list_dir({ "fill", dir, "date", "2026-01-01", "--id", "ancienne" })
			list_dir({ "fill", dir, "date", "2026-03-01", "--id", "recente" })
			list_dir({ "toggle", dir, "pin", "--id", "recente" })
		end,
	},
})

T["list"] = new_set()

T["list"]["croissant : le Marqueur en fin"] = function()
	expect.equality(ids(cli.list(dir, { "date" })), { "ancienne", "recente", "sans-date" })
end

T["list"]["décroissant : le Marqueur reste en fin"] = function()
	expect.equality(ids(cli.list(dir, { "-date" })), { "recente", "ancienne", "sans-date" })
end

T["list"]["plusieurs clés"] = function()
	expect.equality(ids(cli.list(dir, { "-pin", "date" })), { "recente", "ancienne", "sans-date" })
end

T["list"]["where filtre"] = function()
	expect.equality(ids(cli.list(dir, { "id" }, { "pin=true" })), { "recente" })
end

T["list"]["un champ inconnu rend une erreur"] = function()
	local rows, err = cli.list(dir, { "inexistant" })
	expect.equality(rows, nil)
	expect.equality(type(err), "string")
end

T["contrat"] = new_set()

T["contrat"]["source est lu comme déprécié"] = function()
	local ct = assert(contract.read(dir))
	local source = vim.iter(ct.fields):find(function(field)
		return field.name == "source"
	end)
	expect.equality(type(source.deprecated), "string")
end

T["état"] = new_set()

T["état"]["source sort du cycle de tri"] = function()
	local state = items.state(dir, assert(contract.read(dir)))
	local names = vim.tbl_map(function(field)
		return field.name
	end, state.fields)
	expect.equality(vim.tbl_contains(names, "source"), false)
	expect.equality(vim.tbl_contains(names, "date"), true)
end

T["état"]["le sens inversé passe à la CLI"] = function()
	local state = items.state(dir, assert(contract.read(dir)))
	state.field, state.reverse = "date", true
	expect.equality(items.keys(state), { "-date" })
end

T["état"]["le finder lit la valeur dans le front matter"] = function()
	local state = items.state(dir, assert(contract.read(dir)))
	state.field, state.reverse = "date", true
	local ctx = { filter = { filter = function(_, list) return list end } }
	local values = vim.tbl_map(function(entry)
		return entry.ld_value
	end, items.finder(state, ctx))
	expect.equality(values[1], "2026-03-01")
	expect.equality(values[2], "2026-01-01")
end

return T
