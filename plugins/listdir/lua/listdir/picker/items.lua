---Picker de niveau 2 : les éléments d'un répertoire-liste.
---
---`list` donne l'ordre, sens compris ; la valeur du champ trié et le titre sont lus côté
---Lua par `item.read`. Un seul appel Python par run du finder, donc par ouverture et par
---changement de tri — jamais un par élément.
---
---`open` prend des options qui en font un picker de registre (`:Dettes`, `:Roadmap`) sans
---second picker : clés de tri fixes autour du champ du cycle, champs hors cycle, filtres,
---décoration des lignes, titre, actions et touches en plus.

local cli = require("listdir.cli")
local config = require("listdir.config")
local frontmatter = require("frontmatter")
local item = require("listdir.item")

---Vrai pour une valeur qui dit « rien n'est écrit ici » : elle s'affiche en retrait.
---@param value string
---@return boolean
---@nodiscard
local function empty(value)
	return value == "" or frontmatter.is_marker(value)
end

---@alias Ozay.ListDir.ItemsAction fun(picker: snacks.Picker, state: Ozay.ListDir.ItemsState)

---@class Ozay.ListDir.Decoration
---@field prefix? snacks.picker.Highlight[] morceaux affichés avant le libellé
---@field label? string groupe de surbrillance du libellé

---@class Ozay.ListDir.ItemsOpts
---@field before? string[] clés de tri fixes, avant le champ du cycle
---@field after? string[] clés de tri fixes, après le champ du cycle
---@field skip? string[] champs sortis du cycle de tri
---@field where? fun(state: Ozay.ListDir.ItemsState): string[] critères `champ=valeur` de `list`
---@field decorate? fun(entry: Ozay.ListDir.PickerItem, data: Ozay.ListDir.ItemData?): Ozay.ListDir.Decoration?
---@field title? fun(state: Ozay.ListDir.ItemsState): string
---@field actions? table<string, Ozay.ListDir.ItemsAction>
---@field keys? table<string, string|snacks.win.Keys> touche → nom d'action (modes `i` et `n` dans
---l'input), ou spécification Snacks complète, posée telle quelle dans l'input

---@class Ozay.ListDir.ItemsState
---@field dir string
---@field contract Ozay.ListDir.Contract
---@field opts Ozay.ListDir.ItemsOpts
---@field fields Ozay.ListDir.Field[] champs triables : ceux du contrat, `id` compris, dépréciés exclus
---@field index integer rang du champ de tri courant dans `fields`
---@field field string nom du champ de tri courant
---@field reverse boolean

---@class Ozay.ListDir.PickerItem : snacks.picker.finder.Item
---@field ld_id string
---@field ld_value string valeur du champ trié, lue dans le front matter
---@field ld_decoration? Ozay.ListDir.Decoration

---@class Ozay.ListDir.ItemsPicker
local M = {}

---@param state Ozay.ListDir.ItemsState
local function sync_field(state)
	state.field = state.fields[state.index].name
end

---L'état de tri d'un picker. Tous les champs du contrat sont triables, `id` compris, sauf
---les dépréciés : ils ne s'écrivent plus, et trier sur eux rangerait les éléments neufs en
---vrac. Le champ par défaut est `title` s'il est déclaré — c'est celui qui se lit —, sinon le
---premier triable. `opts.skip` sort d'autres champs du cycle.
---@param dir string
---@param ct Ozay.ListDir.Contract
---@param opts? Ozay.ListDir.ItemsOpts
---@return Ozay.ListDir.ItemsState
---@nodiscard
function M.state(dir, ct, opts)
	opts = opts or {}
	local skip = opts.skip or {}
	---@type Ozay.ListDir.Field[]
	local fields = vim.tbl_filter(function(field)
		return not field.deprecated and not vim.tbl_contains(skip, field.name)
	end, ct.fields)
	local index = 1
	for rank, field in ipairs(fields) do
		if field.name == "title" then
			index = rank
			break
		end
	end

	---@type Ozay.ListDir.ItemsState
	local state = { dir = dir, contract = ct, opts = opts, fields = fields, index = index, field = "", reverse = false }
	sync_field(state)
	return state
end

---Les clés de `--sort` : `opts.before`, le champ courant — `-` en tête s'il est inversé —,
---puis `opts.after`. Une clé fixe qui porte le champ courant est omise : il n'est trié qu'une
---fois, dans le sens choisi. Le sens passe par la CLI, qui garde les Marqueurs et les valeurs
---absentes en fin dans les deux sens.
---@param state Ozay.ListDir.ItemsState
---@return string[]
---@nodiscard
function M.keys(state)
	---@param list string[]?
	---@return string[]
	local function others(list)
		return vim.tbl_filter(function(key)
			return key:gsub("^%-", "") ~= state.field
		end, list or {})
	end
	local keys = others(state.opts.before)
	keys[#keys + 1] = (state.reverse and "-" or "") .. state.field
	return vim.list_extend(keys, others(state.opts.after))
end

---Les critères `--where` du tri courant.
---@param state Ozay.ListDir.ItemsState
---@return string[]
---@nodiscard
function M.where(state)
	return state.opts.where and state.opts.where(state) or {}
end

---@param path string
---@param id string
---@param field string
---@return string
local function value_of(path, id, field)
	if field == "id" then
		return id
	end
	local data = item.read(path)
	return data and data.fields[field] or ""
end

---@param state Ozay.ListDir.ItemsState
---@param ctx table
---@return Ozay.ListDir.PickerItem[]
function M.finder(state, ctx)
	local rows, err = cli.list(state.dir, M.keys(state), M.where(state))
	if not rows then
		vim.notify("listdir : " .. tostring(err), vim.log.levels.ERROR)
		return ctx.filter:filter({})
	end

	---@type Ozay.ListDir.PickerItem[]
	local items = {}
	for _, row in ipairs(rows) do
		---@type Ozay.ListDir.PickerItem
		local entry = {
			text = item.title(row.path, row.id),
			file = row.path,
			ld_id = row.id,
			ld_value = value_of(row.path, row.id, state.field),
		}
		if state.opts.decorate then
			entry.ld_decoration = state.opts.decorate(entry, item.read(row.path))
		end
		items[#items + 1] = entry
	end

	-- Le titre peut compter ce que le finder vient de lire : il se recalcule à chaque run.
	local picker = ctx.picker
	if picker then
		vim.schedule(function()
			if not picker.closed then
				picker.title = M.title(state)
				picker:update_titles()
			end
		end)
	end
	return ctx.filter:filter(items)
end

---@param entry Ozay.ListDir.PickerItem
---@param picker snacks.Picker
---@return snacks.picker.Highlight[]
function M.format(entry, picker)
	---@type snacks.picker.Highlight[]
	local decoration = entry.ld_decoration or {}
	---@type snacks.picker.Highlight[]
	local ret = vim.list_extend({}, decoration.prefix or {})
	vim.list_extend(ret, { { entry.ld_id, "Comment" }, { "  " } })
	-- Trier par `title` ou par `id` ferait afficher deux fois la même chaîne.
	if not empty(entry.ld_value) and entry.ld_value ~= entry.text and entry.ld_value ~= entry.ld_id then
		ret[#ret + 1] = { entry.ld_value, "Special" }
		ret[#ret + 1] = { "  " }
	end
	ret[#ret + 1] = { entry.text, decoration.label or "SnacksPickerLabel" }
	return ret
end

---@param picker snacks.Picker
---@param entry? Ozay.ListDir.PickerItem
function M.confirm(picker, entry)
	if not entry then
		return
	end
	picker:close()
	vim.cmd.edit(vim.fn.fnameescape(entry.file))
end

---Ouvre le document concaténé de la liste, dans l ordre du tri courant.
---@param state Ozay.ListDir.ItemsState
---@return integer? bufnr
function M.document(state)
	local rows, err = cli.list(state.dir, M.keys(state), M.where(state))
	if not rows then
		vim.notify("listdir : " .. tostring(err), vim.log.levels.ERROR)
		return nil
	end
	-- `document.open` ouvre le fichier dans la fenêtre courante.
	return require("listdir.document").open(state.dir, state.contract, rows)
end

---Le nom de la liste et l'indicateur de tri : `technical-debt  ↑ title`.
---@param state Ozay.ListDir.ItemsState
---@return string
---@nodiscard
function M.indicator(state)
	return ("%s  %s %s"):format(state.contract.name, state.reverse and "↓" or "↑", state.field)
end

---@param state Ozay.ListDir.ItemsState
---@return string
---@nodiscard
function M.title(state)
	return state.opts.title and state.opts.title(state) or M.indicator(state)
end

---Passe au champ de tri suivant du contrat, en boucle.
---@param state Ozay.ListDir.ItemsState
function M.sort_next(state)
	state.index = state.index % #state.fields + 1
	sync_field(state)
end

---Passe au champ de tri précédent, en boucle.
---@param state Ozay.ListDir.ItemsState
function M.sort_prev(state)
	state.index = (state.index - 2) % #state.fields + 1
	sync_field(state)
end

---Inverse le sens du tri. Le `refresh` qui suit relance `list` avec `-` en tête.
---@param state Ozay.ListDir.ItemsState
function M.sort_reverse(state)
	state.reverse = not state.reverse
end

---@param dir string
---@param ct Ozay.ListDir.Contract
---@param opts? Ozay.ListDir.ItemsOpts
function M.open(dir, ct, opts)
	local state = M.state(dir, ct, opts)

	---Applique un changement de tri : le titre suit, et `refresh` relance le finder
	---— donc exactement un appel `list`.
	---@param change fun(state: Ozay.ListDir.ItemsState)
	---@return snacks.picker.Action.fn
	local function sort_action(change)
		return function(picker)
			change(state)
			picker.title = M.title(state)
			picker:refresh()
		end
	end

	---@type table<string, snacks.picker.Action.fn>
	local actions = {
		ld_sort_next = sort_action(M.sort_next),
		ld_sort_prev = sort_action(M.sort_prev),
		ld_sort_reverse = sort_action(M.sort_reverse),
		ld_document = function(picker)
			picker:close()
			M.document(state)
		end,
	}
	-- `<a-r>` est toggle_regex et `<a-i>` toggle_ignored chez snacks : ne pas les réutiliser.
	---@type table<string, string|snacks.win.Keys>
	local keys = {
		["<A-s>"] = "ld_sort_next",
		["<A-S>"] = "ld_sort_prev",
		["<A-v>"] = "ld_sort_reverse",
		["<A-o>"] = "ld_document",
	}
	for name, action in pairs(state.opts.actions or {}) do
		actions[name] = function(picker)
			action(picker, state)
		end
	end
	keys = vim.tbl_extend("force", keys, state.opts.keys or {})

	---@type table<string, snacks.win.Keys>, table<string, string>
	local input_keys, list_keys = {}, {}
	for key, spec in pairs(keys) do
		if type(spec) == "table" then
			input_keys[key] = spec
			list_keys[key] = spec[1]
		else
			input_keys[key] = { spec, mode = { "i", "n" } }
			list_keys[key] = spec
		end
	end

	Snacks.picker.pick(config.picker("items", {
		source = "listdir_items",
		title = M.title(state),
		-- Une liste vide, ou un filtre qui ne rend rien, laisse le picker ouvert : il dit la liste
		-- et le tri, et un filtre doit pouvoir se défaire.
		show_empty = true,
		-- `resume` rejoue les options de l'ouverture, titre initial compris, alors que `state`
		-- a gardé le tri courant : chaque ouverture recalcule le titre depuis `state`.
		on_show = function(picker)
			picker.title = M.title(state)
			picker:update_titles()
		end,
		finder = function(_, ctx)
			return M.finder(state, ctx)
		end,
		format = M.format,
		confirm = M.confirm,
		actions = actions,
		win = { input = { keys = input_keys }, list = { keys = list_keys } },
	}))
end

return M
