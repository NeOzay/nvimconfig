-- `:Dettes` : ordre, filtre des pins, compteurs et couleurs, contre la CLI `list-dir` réelle sur
-- un registre de dette temporaire.

local new_set = MiniTest.new_set
local expect = MiniTest.expect

local contract = require("listdir.contract")
local items = require("listdir.picker.items")
local registres = require("registres")

local dir

---@param args string[]
local function list_dir(args)
	local res = vim.system(vim.list_extend({ "list-dir" }, args), { text = true }):wait()
	assert(res.code == 0, res.stderr)
end

---Cinq dettes : `a` et `c` épinglées ; `b`, `d` et `e` de même titre, `b` et `e` de même date.
local DETTES = {
	{ id = "a", title = "A", date = "2026-01-01", severite = "majeur", pin = true },
	{ id = "b", title = "B", date = "2026-03-01", severite = "critique" },
	{ id = "c", title = "C", date = "2026-02-01", severite = "note", pin = true },
	{ id = "d", title = "B", date = "2026-01-15", severite = "majeur" },
	{ id = "e", title = "B", date = "2026-03-01", severite = "note" },
}

local ctx = { filter = { filter = function(_, list) return list end } }

---@param opts Ozay.ListDir.ItemsOpts
---@return Ozay.ListDir.ItemsState
local function state(opts)
	return items.state(dir, assert(contract.read(dir)), opts)
end

---@param s Ozay.ListDir.ItemsState
---@return string[]
local function order(s)
	return vim.tbl_map(function(entry)
		return entry.ld_id
	end, items.finder(s, ctx))
end

local T = new_set({
	hooks = {
		pre_once = function()
			dir = vim.fn.tempname()
			list_dir({ "init", "--def", "technical-debt", dir })
			for _, dette in ipairs(DETTES) do
				list_dir({ "new", dir, dette.id })
				for _, field in ipairs({ "title", "date", "severite" }) do
					list_dir({ "fill", dir, field, dette[field], "--id", dette.id })
				end
				if dette.pin then
					list_dir({ "toggle", dir, "pin", "--id", dette.id })
				end
			end
		end,
	},
})

T["ordre"] = new_set()

T["ordre"]["pins, puis le cycle, puis -date, puis -severite"] = function()
	expect.equality(order(state((registres.dettes_opts(dir)))), { "a", "c", "b", "e", "d" })
end

T["ordre"]["le cycle sur date : la date n'est pas répétée"] = function()
	local s = state((registres.dettes_opts(dir)))
	s.field = "date"
	expect.equality(items.keys(s), { "-pin", "date", "-severite" })
	expect.equality(order(s), { "a", "c", "d", "b", "e" })
end

T["ordre"]["pin sort du cycle"] = function()
	local names = vim.tbl_map(function(field)
		return field.name
	end, state((registres.dettes_opts(dir))).fields)
	expect.equality(vim.tbl_contains(names, "pin"), false)
end

T["filtre"] = new_set()

T["filtre"]["les pins seuls, et le titre le dit"] = function()
	local opts, filter = registres.dettes_opts(dir)
	local s = state(opts)
	expect.equality(items.title(s), "technical-debt  ↑ title 5·2 pins")
	filter.pins_only = true
	expect.equality(order(s), { "a", "c" })
	-- Les compteurs portent sur tout le registre, filtre ou non.
	expect.equality(items.title(s), "technical-debt  ↑ title 5·2 [pins]")
end

T["couleurs"] = new_set()

T["couleurs"]["libellé épinglé, sévérité par niveau"] = function()
	local entries = items.finder(state((registres.dettes_opts(dir))), ctx)
	---@type table<string, Ozay.ListDir.Decoration>
	local by_id = {}
	for _, entry in ipairs(entries) do
		by_id[entry.ld_id] = entry.ld_decoration
	end
	expect.equality(by_id.a.label, "ListDirPinned")
	expect.equality(by_id.b.label, nil)
	expect.equality(by_id.a.prefix[1][2], "ListDirSeverityMajeur")
	expect.equality(by_id.b.prefix[1][2], "ListDirSeverityCritique")
	expect.equality(by_id.c.prefix[1][2], "ListDirSeverityNote")
end

T["couleurs"]["le glyphe de sévérité tient 2 colonnes"] = function()
	for _, severite in ipairs({ "inconnue", "note", "avertissement", "majeur", "critique" }) do
		local decoration = registres.decorate({}, { fields = { severite = severite }, body = "" })
		expect.equality(vim.api.nvim_strwidth(decoration.prefix[1][1]), 2)
	end
end

T["couleurs"]["une sévérité au Marqueur est inconnue"] = function()
	local decoration = registres.decorate({}, { fields = { severite = "<À REMPLIR>" }, body = "" })
	expect.equality(decoration.prefix[1][2], "ListDirSeverityInconnue")
end

T["couleurs"]["chaque niveau a son groupe défini"] = function()
	local groups = dofile("lua/highlights/listdir.lua")
	for _, level in ipairs({ "Inconnue", "Note", "Avertissement", "Majeur", "Critique" }) do
		expect.equality(groups["ListDirSeverity" .. level] ~= nil, true)
	end
	expect.equality(groups.ListDirPinned ~= nil, true)
end


T["pin"] = new_set()

---Un registre neuf, à une dette `x`, pour les tests qui écrivent.
---@return string dir
local function scratch()
	local d = vim.fn.tempname()
	list_dir({ "init", "--def", "technical-debt", d })
	list_dir({ "new", d, "x" })
	list_dir({ "fill", d, "title", "X", "--id", "x" })
	return d
end

T["pin"]["toggle ne change que la ligne pin, et revient"] = function()
	local d = scratch()
	local path = vim.fs.joinpath(d, "x.md")
	local before = vim.fn.readfile(path)
	expect.equality(require("listdir.cli").toggle(d, "pin", "x"), true)
	local after = vim.fn.readfile(path)
	expect.equality(#after, #before)
	---@type string[]
	local changed = {}
	for index, line in ipairs(before) do
		if after[index] ~= line then
			changed[#changed + 1] = after[index]
		end
	end
	expect.equality(changed, { "pin = true" })
	require("listdir.cli").toggle(d, "pin", "x")
	expect.equality(vim.fn.readfile(path), before)
end

T["pin"]["un échec est rendu, pas levé"] = function()
	local ok, err = require("listdir.cli").toggle(scratch(), "pin", "absente")
	expect.equality(ok, false)
	expect.equality(type(err), "string")
end

T["pin"]["<A-N> dans le picker : épinglée, en tête, curseur gardé"] = function()
	local child = MiniTest.new_child_neovim()
	child.start({ "-u", "tests/minimal_init.lua" })
	local d = scratch()
	list_dir({ "new", d, "y" })
	list_dir({ "fill", d, "title", "A", "--id", "y" })
	child.lua("_G.dir = ...", { d })
	child.lua([[
		local registres = require("registres")
		local ct = assert(require("listdir.contract").read(_G.dir))
		require("listdir.picker.items").open(_G.dir, ct, (registres.dettes_opts(_G.dir)))
		_G.picker = function() return Snacks.picker.get({ source = "listdir_items" })[1] end
		vim.wait(3000, function() return _G.picker() and not _G.picker():is_active() end, 10)
	]])
	-- y (« A ») avant x (« X ») : le curseur va sur x, la seconde ligne.
	child.lua([[
		_G.picker().list:view(2)
		_G.preview = function()
			return vim.api.nvim_buf_get_lines(_G.picker().preview.win.buf, 0, -1, false)
		end
		-- La preview montre x avant la bascule : sans quoi rien ne dit qu'elle est relue.
		assert(vim.wait(2000, function()
			return vim.tbl_contains(_G.preview(), 'title = "X"') and vim.tbl_contains(_G.preview(), "pin = false")
		end, 10), "preview de x jamais affichée")
	]])
	-- La touche elle-même, depuis l'input du picker : c'est elle que la doc annonce.
	child.type_keys("<A-N>")
	child.lua([[
		vim.wait(3000, function()
			local items = _G.picker():items()
			return items[1] and items[1].ld_id == "x" and not _G.picker():is_active()
		end, 10)
		vim.wait(200)
	]])
	expect.equality(child.lua_get("vim.tbl_map(function(i) return i.ld_id end, _G.picker():items())"), { "x", "y" })
	expect.equality(child.lua_get("_G.picker():current().ld_id"), "x")
	expect.equality(child.lua_get("_G.picker().title"), "technical-debt  ↑ title 2·1 pin")
	-- La preview relit l'entrée réécrite.
	child.lua([[vim.wait(1000, function() return vim.tbl_contains(_G.preview(), "pin = true") end, 10)]])
	local preview = child.lua_get("_G.preview()")
	expect.equality(vim.tbl_contains(preview, "pin = true"), true)
	child.stop()
end

return T
