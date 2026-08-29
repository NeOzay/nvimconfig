---Appel de la commande `list` du skill `list-dir`.
---
---UNE SEULE COLONNE est demandée à `--sort`, jamais plus. Une valeur `text` peut
---contenir des espaces, et un champ absent du front matter d'un élément est rendu
---par une chaîne vide : dès la deuxième colonne, le découpage positionnel se décale
---sans que rien ne le signale. Avec une colonne, `id` est le premier token et la
---valeur est tout le reste de la ligne — sans ambiguïté possible.
---
---Le titre ne vient donc pas de `list` mais de `item.read`, côté Lua.

local config = require("listdir.config")

---@class Ozay.ListDir.Row
---@field id string
---@field path string chemin absolu du `.md` de l'élément
---@field value string valeur du champ trié, telle que rendue par `list`

---@class Ozay.ListDir.Cli
local M = {}

---@param dir string répertoire-liste
---@param field string champ de tri, déclaré au contrat
---@param reverse boolean inverse l'ordre, en Lua — aucun appel supplémentaire
---@return Ozay.ListDir.Row[]? rows
---@return string? err
---@nodiscard
function M.list(dir, field, reverse)
	local opts = config.options
	local cmd = { opts.python, opts.cli, "list", dir, "--sort", field }

	local ok, result = pcall(function()
		return vim.system(cmd, { text = true }):wait(opts.timeout)
	end)
	if not ok then
		return nil, ("échec de l'appel à list-dir : %s"):format(tostring(result))
	end
	---@cast result vim.SystemCompleted
	if result.code ~= 0 then
		local message = vim.trim(result.stderr or "")
		return nil, message ~= "" and message or ("list-dir a rendu le code %d"):format(result.code)
	end

	---@type Ozay.ListDir.Row[]
	local rows = {}
	for line in vim.gsplit(result.stdout or "", "\n", { plain = true }) do
		if line ~= "" then
			local id, value = line:match("^(%S+)%s?(.*)$")
			if id then
				rows[#rows + 1] = {
					id = id,
					path = vim.fs.joinpath(dir, id .. ".md"),
					value = value or "",
				}
			end
		end
	end

	if reverse then
		---@type Ozay.ListDir.Row[]
		local flipped = {}
		for index = #rows, 1, -1 do
			flipped[#flipped + 1] = rows[index]
		end
		rows = flipped
	end

	return rows
end

return M
