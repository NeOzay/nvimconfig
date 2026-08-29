---Picker de niveau 1 : les répertoires-listes trouvés sous les chemins configurés.
---
---`finder` et `confirm` sont exposés au niveau du module plutôt qu'écrits en closures
---anonymes : c'est ce qui rend l'enchaînement vers le picker de niveau 2 exerçable
---sans ouvrir de fenêtre.

local config = require("listdir.config")
local discover = require("listdir.discover")

---@class Ozay.ListDir.ListItem : snacks.picker.finder.Item
---@field ld_dir string chemin du répertoire-liste
---@field ld_contract Ozay.ListDir.Contract

---@class Ozay.ListDir.ListsPicker
local M = {}

---Aperçu d'une liste : ce qu'elle est, et ce que son contrat exige. Rendu en
---mémoire — ouvrir un fichier pour une information déjà lue serait du gaspillage.
---@param entry Ozay.ListDir.Entry
---@return string
local function preview(entry)
	---@type string[]
	local lines = { "# " .. entry.name, "" }
	if entry.description ~= "" then
		lines[#lines + 1] = entry.description
		lines[#lines + 1] = ""
	end
	lines[#lines + 1] = "`" .. entry.path .. "`"
	lines[#lines + 1] = ""
	local count = 0
	for name, kind in vim.fs.dir(entry.path) do
		if kind == "file" and name:match("%.md$") then
			count = count + 1
		end
	end
	lines[#lines + 1] = ("%d élément%s"):format(count, count > 1 and "s" or "")
	lines[#lines + 1] = ""
	lines[#lines + 1] = "| champ | type | requis |"
	lines[#lines + 1] = "|---|---|---|"
	for _, field in ipairs(entry.fields) do
		lines[#lines + 1] = ("| %s | %s | %s |"):format(field.name, field.type, field.required and "oui" or "")
	end
	return table.concat(lines, "\n")
end

---Les entrées déjà trouvées par `M.open` sont réutilisées : sans cela, une seule
---ouverture de picker scanne deux fois l'arborescence — une fois pour savoir s'il y
---a quelque chose à montrer, une fois pour le montrer.
---@param opts table|{ ld_entries?: Ozay.ListDir.Entry[] }
---@param ctx table
---@return Ozay.ListDir.ListItem[]
function M.finder(opts, ctx)
	---@type Ozay.ListDir.ListItem[]
	local items = {}
	for _, entry in ipairs(opts.ld_entries or discover.find()) do
		items[#items + 1] = {
			text = entry.name,
			ld_dir = entry.path,
			ld_contract = { name = entry.name, description = entry.description, fields = entry.fields },
			preview = { text = preview(entry), ft = "markdown" },
		}
	end
	return ctx.filter:filter(items)
end

---@param item Ozay.ListDir.ListItem
---@param picker snacks.Picker
---@return snacks.picker.Highlight[]
function M.format(item, picker)
	---@type snacks.picker.Highlight[]
	local ret = { { item.text, "SnacksPickerLabel" } }
	local description = item.ld_contract.description
	if description ~= "" then
		ret[#ret + 1] = { "  " }
		ret[#ret + 1] = { description, "Comment" }
	end
	return ret
end

---@param picker snacks.Picker
---@param item? Ozay.ListDir.ListItem
function M.confirm(picker, item)
	if not item then
		return
	end
	picker:close()
	require("listdir.picker.items").open(item.ld_dir, item.ld_contract)
end

function M.open()
	local entries = discover.find()
	if #entries == 0 then
		vim.notify("listdir : aucun répertoire-liste sous " .. table.concat(config.paths(), ", "), vim.log.levels.WARN)
		return
	end

	Snacks.picker.pick(config.picker("lists", {
		title = "Répertoires-listes",
		ld_entries = entries,
		-- Sans `preview = "preview"`, snacks garde le previewer fichier, qui n'a rien à
		-- montrer ici : un répertoire-liste n'est pas un fichier. Ce préréglage est celui
		-- qui affiche `item.preview`.
		preview = "preview",
		finder = M.finder,
		format = M.format,
		confirm = M.confirm,
	}))
end

return M
