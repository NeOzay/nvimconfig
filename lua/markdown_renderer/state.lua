---@namespace Ozay.MarkdownRenderer

---@alias Engine "markview"|"render-markdown"

--- Fichier d'état du moteur de rendu markdown : une ligne, le nom du moteur du prochain démarrage.
---@class State
local M = {}

---@type Engine
M.DEFAULT = "markview"

---@type Engine[]
M.ENGINES = { "markview", "render-markdown" }

--- Chemin du fichier d'état réel.
---@return string
function M.default_path()
	return vim.fs.joinpath(vim.fn.stdpath("state"), "markdown-renderer")
end

---@param value string
---@return boolean
local function is_engine(value)
	return vim.list_contains(M.ENGINES, value)
end

--- Moteur écrit dans le fichier. Absent, illisible ou valeur inconnue → `markview`.
---@param path? string
---@return Engine
function M.read(path)
	local ok, lines = pcall(vim.fn.readfile, path or M.default_path(), "", 1)
	local value = ok and lines[1] and vim.trim(lines[1]) or ""
	if is_engine(value) then
		return value --[[@as Engine]]
	end
	return M.DEFAULT
end

--- Écrit le moteur ; une valeur inconnue lève une erreur et laisse le fichier intact.
---@param engine string
---@param path? string
function M.write(engine, path)
	if not is_engine(engine) then
		error(("moteur inconnu : %s (attendu : %s)"):format(engine, table.concat(M.ENGINES, ", ")), 2)
	end
	path = path or M.default_path()
	vim.fn.mkdir(vim.fs.dirname(path), "p")
	vim.fn.writefile({ engine }, path)
end

return M
