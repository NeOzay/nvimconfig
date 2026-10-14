---Pickers des Registres du pipeline (implementation-tracker) : la road-map et la dette.
---
---Les listes vivent sous `.claude/implementation/todo/` à la racine git du cwd. Chaque
---registre ouvre le picker d'éléments de listdir (`listdir.picker.items`), réglé par ses
---options : aucun picker propre.

local frontmatter = require("frontmatter")

---Glyphe Nerd Font de chaque niveau de sévérité ; suivi d'une espace, il tient 2 colonnes.
---@type table<string, string>
local SEVERITY_GLYPHS = {
	critique = "󰈸", -- md-fire
	majeur = "󰀦", -- md-alert
	avertissement = "󰀪", -- md-alert_outline
	note = "󰋽", -- md-information_outline
	inconnue = "󰘥", -- md-help_circle_outline
}

---@class Ozay.Registres
local M = {}

---@param msg string
---@param level? integer
local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.WARN, { title = "Registres" })
end

---Le répertoire d'un Registre dans le dépôt du cwd, ou nil après un message.
---@param name string nom de la liste sous `todo/`
---@return string? dir
---@nodiscard
function M.dir(name)
	local root = vim.fs.root(assert(vim.uv.cwd()), ".git")
	if not root then
		notify("pas de dépôt git dans le cwd")
		return nil
	end
	local dir = vim.fs.joinpath(root, ".claude", "implementation", "todo", name)
	if not vim.uv.fs_stat(vim.fs.joinpath(dir, ".list", "contract.toml")) then
		notify(("pas de registre « %s » dans %s"):format(name, root))
		return nil
	end
	return dir
end

---Ouvre le picker d'éléments sur un Registre.
---@param name string
---@param make_opts? fun(dir: string): Ozay.ListDir.ItemsOpts options du picker, selon le répertoire
local function open(name, make_opts)
	local dir = M.dir(name)
	if not dir then
		return
	end
	local ct, err = require("listdir.contract").read(dir)
	if not ct then
		return notify(tostring(err), vim.log.levels.ERROR)
	end
	require("listdir.picker.items").open(dir, ct, make_opts and make_opts(dir))
end

---Picker de la road-map.
function M.roadmap()
	open("road-map")
end

---@class Ozay.Registres.Counts
---@field total integer
---@field pins integer

---Compte les dettes et les pins de tout le registre, filtre ou non, sur le front matter caché :
---aucun appel à `list-dir`.
---@param dir string
---@return Ozay.Registres.Counts
---@nodiscard
function M.counts(dir)
	---@type Ozay.Registres.Counts
	local counts = { total = 0, pins = 0 }
	for name, kind in vim.fs.dir(dir) do
		if kind == "file" and name:match("%.md$") then
			counts.total = counts.total + 1
			local data = frontmatter.read(vim.fs.joinpath(dir, name))
			if data and data.fields.pin == "true" then
				counts.pins = counts.pins + 1
			end
		end
	end
	return counts
end

---Pin en couleur propre sur le libellé, sévérité en glyphe coloré par niveau devant l'id.
---@param _ Ozay.ListDir.PickerItem
---@param data Ozay.ListDir.ItemData?
---@return Ozay.ListDir.Decoration
---@nodiscard
function M.decorate(_, data)
	local fields = data and data.fields or {}
	local severity = fields.severite
	if not SEVERITY_GLYPHS[severity] then
		severity = "inconnue"
	end
	local group = "ListDirSeverity" .. severity:sub(1, 1):upper() .. severity:sub(2)
	return {
		prefix = { { SEVERITY_GLYPHS[severity] .. " ", group } },
		label = fields.pin == "true" and "ListDirPinned" or nil,
	}
end

---Bascule le pin de la dette sous le curseur par `list-dir toggle` — Neovim n'écrit jamais
---dans l'entrée —, puis rafraîchit le picker et sa preview en gardant le curseur sur elle.
---@param picker snacks.Picker
---@param dir string
function M.toggle_pin(picker, dir)
	local entry = picker:current() --[[@as Ozay.ListDir.PickerItem?]]
	if not entry then
		return
	end
	local ok, err = require("listdir.cli").toggle(dir, "pin", entry.ld_id)
	if not ok then
		return notify(tostring(err), vim.log.levels.ERROR)
	end
	frontmatter.forget(entry.file)

	local id = entry.ld_id
	picker.list:set_selected()
	picker:find({
		refresh = true,
		on_done = function()
			for index, item in ipairs(picker:items()) do
				if item.ld_id == id then
					picker.list:view(index)
					break
				end
			end
			-- Le previewer fichier garde son contenu tant que le chemin ne change pas : l'oublier,
			-- pour qu'il relise l'entrée réécrite.
			picker.preview:refresh(picker)
		end,
	})
end

---Options du picker de la dette. `pins_only` restreint aux dettes épinglées ; il vit dans la
---table rendue, que l'action `ld_pins` bascule.
---@param dir string
---@return Ozay.ListDir.ItemsOpts opts
---@return { pins_only: boolean } filter
---@nodiscard
function M.dettes_opts(dir)
	local items = require("listdir.picker.items")
	local filter = { pins_only = false }

	---@type Ozay.ListDir.ItemsOpts
	local opts = {
		before = { "-pin" },
		after = { "-date", "-severite" },
		skip = { "pin" },
		where = function()
			return filter.pins_only and { "pin=true" } or {}
		end,
		decorate = M.decorate,
		title = function(state)
			local counts = M.counts(dir)
			return ("%s %d·%d %spin%s%s"):format(
				items.indicator(state),
				counts.total,
				counts.pins,
				filter.pins_only and "[" or "",
				counts.pins > 1 and "s" or "",
				filter.pins_only and "]" or ""
			)
		end,
		actions = {
			ld_toggle_pin = function(picker)
				M.toggle_pin(picker, dir)
			end,
			ld_pins = function(picker, state)
				filter.pins_only = not filter.pins_only
				picker.title = items.title(state)
				picker:refresh()
			end,
		},
		keys = {
			["<A-n>"] = { "ld_pins", mode = { "n", "i" } },
			["<A-N>"] = { "ld_toggle_pin", mode = { "n", "i" } },
		},
	}
	return opts, filter
end

---Picker de la dette technique : pins en tête, puis le champ du cycle, puis la date et la
---sévérité décroissantes.
function M.dettes()
	open("technical-debt", function(dir)
		return (M.dettes_opts(dir))
	end)
end

return M
