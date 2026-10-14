---Appels du skill `list-dir` : `list` pour l'ordre, `toggle` pour basculer un booléen.
---
---SEUL L'ID EST LU, le premier token de chaque ligne. `list` ordonne — tri typé, Marqueurs
---en fin dans les deux sens, plusieurs clés —, mais les colonnes qu'il affiche ne se
---découpent pas : une valeur `text` peut contenir des espaces, et un champ absent rend une
---chaîne vide, ce qui décale toute colonne suivante sans que rien ne le signale. Les valeurs
---affichées viennent du front matter, lu par `item.read`, côté Lua.

local config = require("listdir.config")

---@class Ozay.ListDir.Row
---@field id string
---@field path string chemin absolu du `.md` de l'élément

---@class Ozay.ListDir.Cli
local M = {}

---Lance `list-dir` et attend sa fin.
---@param cmd string[]
---@return vim.SystemCompleted? result
---@return string? err
local function run(cmd)
	local opts = config.options
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
	return result
end

---@param dir string répertoire-liste
---@param keys string[] champs de tri déclarés au contrat, `-` en tête pour décroissant
---@param where? string[] critères `champ=valeur`, cumulés
---@return Ozay.ListDir.Row[]? rows dans l'ordre de `list`
---@return string? err
---@nodiscard
function M.list(dir, keys, where)
	-- `--sort=-champ` collé : séparé, argparse prendrait `-champ` pour une option.
	local cmd = { config.options.cli, "list", dir, "--sort=" .. table.concat(keys, ",") }
	for _, criterion in ipairs(where or {}) do
		vim.list_extend(cmd, { "--where", criterion })
	end

	local result, err = run(cmd)
	if not result then
		return nil, err
	end

	---@type Ozay.ListDir.Row[]
	local rows = {}
	for line in vim.gsplit(result.stdout or "", "\n", { plain = true }) do
		local id = line:match("^(%S+)")
		if id then
			rows[#rows + 1] = { id = id, path = vim.fs.joinpath(dir, id .. ".md") }
		end
	end
	return rows
end

---Inverse un champ `bool` d'un élément, par `list-dir toggle` : seule écriture du plugin, et
---seule la ligne du champ change.
---@param dir string répertoire-liste
---@param field string champ `bool` déclaré au contrat
---@param id string
---@return boolean ok
---@return string? err
function M.toggle(dir, field, id)
	local _, err = run({ config.options.cli, "toggle", dir, field, "--id", id })
	return err == nil, err
end

return M
