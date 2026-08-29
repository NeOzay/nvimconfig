---Picker de niveau 2 : les éléments d'un répertoire-liste.
---
---`list` donne l'ordre et la valeur du champ trié ; le titre est lu côté Lua par
---`item.read`. Un seul appel Python par run du finder, donc par ouverture et par
---changement de tri — jamais un par élément.

local cli = require("listdir.cli")
local config = require("listdir.config")
local item = require("listdir.item")

---Valeurs qui disent « rien n'est écrit ici » : elles s'affichent en retrait.
local EMPTY = { [""] = true, ["<OPTIONNEL>"] = true, ["<À REMPLIR>"] = true }

---@class Ozay.ListDir.ItemsState
---@field dir string
---@field contract Ozay.ListDir.Contract
---@field fields Ozay.ListDir.Field[] champs du contrat, `id` compris
---@field index integer rang du champ de tri courant dans `fields`
---@field field string nom du champ de tri courant
---@field reverse boolean

---@class Ozay.ListDir.PickerItem : snacks.picker.finder.Item
---@field ld_id string
---@field ld_value string valeur du champ trié

---@class Ozay.ListDir.ItemsPicker
local M = {}

---@param state Ozay.ListDir.ItemsState
local function sync_field(state)
	state.field = state.fields[state.index].name
end

---L'état de tri d'un picker. Tous les champs du contrat sont triables, `id`
---compris. Le champ par défaut est `title` s'il est déclaré — c'est celui qui se
---lit —, sinon le premier du contrat.
---@param dir string
---@param ct Ozay.ListDir.Contract
---@return Ozay.ListDir.ItemsState
---@nodiscard
function M.state(dir, ct)
	local fields = ct.fields
	local index = 1
	for rank, field in ipairs(fields) do
		if field.name == "title" then
			index = rank
			break
		end
	end

	---@type Ozay.ListDir.ItemsState
	local state = { dir = dir, contract = ct, fields = fields, index = index, field = "", reverse = false }
	sync_field(state)
	return state
end

---@param state Ozay.ListDir.ItemsState
---@param ctx table
---@return Ozay.ListDir.PickerItem[]
function M.finder(state, ctx)
	local rows, err = cli.list(state.dir, state.field, state.reverse)
	if not rows then
		vim.notify("listdir : " .. tostring(err), vim.log.levels.ERROR)
		return ctx.filter:filter({})
	end

	---@type Ozay.ListDir.PickerItem[]
	local items = {}
	for _, row in ipairs(rows) do
		items[#items + 1] = {
			text = item.title(row.path, row.id),
			file = row.path,
			ld_id = row.id,
			ld_value = row.value,
		}
	end
	return ctx.filter:filter(items)
end

---@param entry Ozay.ListDir.PickerItem
---@param picker snacks.Picker
---@return snacks.picker.Highlight[]
function M.format(entry, picker)
	---@type snacks.picker.Highlight[]
	local ret = { { entry.ld_id, "Comment" }, { "  " } }
	-- Trier par `title` ou par `id` ferait afficher deux fois la même chaîne.
	if not EMPTY[entry.ld_value] and entry.ld_value ~= entry.text and entry.ld_value ~= entry.ld_id then
		ret[#ret + 1] = { entry.ld_value, "Special" }
		ret[#ret + 1] = { "  " }
	end
	ret[#ret + 1] = { entry.text, "SnacksPickerLabel" }
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
	local rows, err = cli.list(state.dir, state.field, state.reverse)
	if not rows then
		vim.notify("listdir : " .. tostring(err), vim.log.levels.ERROR)
		return nil
	end
	-- `document.open` ouvre le fichier dans la fenêtre courante.
	return require("listdir.document").open(state.dir, state.contract, rows)
end

---@param state Ozay.ListDir.ItemsState
---@return string
---@nodiscard
function M.title(state)
	return ("%s  %s %s"):format(state.contract.name, state.reverse and "↓" or "↑", state.field)
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

---Inverse le sens du tri. En Lua : aucun appel supplémentaire à `list`.
---@param state Ozay.ListDir.ItemsState
function M.sort_reverse(state)
	state.reverse = not state.reverse
end

---@param dir string
---@param ct Ozay.ListDir.Contract
function M.open(dir, ct)
	local state = M.state(dir, ct)

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

	Snacks.picker.pick(config.picker("items", {
		title = M.title(state),
		finder = function(_, ctx)
			return M.finder(state, ctx)
		end,
		format = M.format,
		confirm = M.confirm,
		actions = {
			ld_sort_next = sort_action(M.sort_next),
			ld_sort_prev = sort_action(M.sort_prev),
			ld_sort_reverse = sort_action(M.sort_reverse),
			ld_document = function(picker)
				picker:close()
				M.document(state)
			end,
		},
		win = {
			-- `<a-r>` est toggle_regex et `<a-i>` toggle_ignored chez snacks : ne pas
			-- les réutiliser. `<A-s>`, `<A-S>` et `<A-v>` sont libres.
			input = {
				keys = {
					["<A-s>"] = { "ld_sort_next", mode = { "i", "n" } },
					["<A-S>"] = { "ld_sort_prev", mode = { "i", "n" } },
					["<A-v>"] = { "ld_sort_reverse", mode = { "i", "n" } },
					["<A-o>"] = { "ld_document", mode = { "i", "n" } },
				},
			},
			list = {
				keys = {
					["<A-s>"] = "ld_sort_next",
					["<A-S>"] = "ld_sort_prev",
					["<A-v>"] = "ld_sort_reverse",
					["<A-o>"] = "ld_document",
				},
			},
		},
	}))
end

return M
