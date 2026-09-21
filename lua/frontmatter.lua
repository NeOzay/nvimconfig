---Lecture d'un document à front matter TOML délimité par `+++`, puis le corps.
---
---Pas de parseur TOML : seules les lignes `clé = valeur` à plat sont lues, ce qui
---suffit aux éléments des répertoires-listes comme aux fichiers de suivi. Le cache,
---invalidé sur `mtime`, évite de relire les fichiers inchangés.

local DELIM = "+++"

---@class Ozay.Frontmatter.Data
---@field fields table<string, string> valeurs du front matter, telles qu'écrites
---@field body string corps du document, front matter retiré

---@class Ozay.Frontmatter
local M = {}

---@class Ozay.Frontmatter.CacheEntry
---@field mtime integer
---@field data Ozay.Frontmatter.Data

---@type table<string, Ozay.Frontmatter.CacheEntry>
local cache = {}

---Retire les guillemets d'une valeur TOML. Les dates et listes sont laissées
---telles quelles : seul l'affichage en a besoin, pas le typage.
---@param value string
---@return string
local function unquote(value)
	value = vim.trim(value)
	local inner = value:match('^"(.*)"$')
	return inner or value
end

---@param lines string[]
---@return Ozay.Frontmatter.Data
local function parse(lines)
	---@type table<string, string>
	local fields = {}
	---@type string[]
	local body = {}

	local first = lines[1] and vim.trim(lines[1]) == DELIM
	local closed = not first
	for index, line in ipairs(lines) do
		if index == 1 and first then
			-- délimiteur ouvrant
		elseif not closed then
			if vim.trim(line) == DELIM then
				closed = true
			else
				local key, value = line:match("^([%w_]+)%s*=%s*(.*)$")
				if key then
					fields[key] = unquote(value)
				end
			end
		else
			body[#body + 1] = line
		end
	end

	return { fields = fields, body = vim.trim(table.concat(body, "\n")) }
end

---@param path string
---@return Ozay.Frontmatter.Data? data
---@return string? err
---@nodiscard
function M.read(path)
	local stat = vim.uv.fs_stat(path)
	if not stat then
		return nil, ("élément introuvable : %s"):format(path)
	end

	local mtime = stat.mtime.sec
	local hit = cache[path]
	if hit and hit.mtime == mtime then
		return hit.data
	end

	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok then
		return nil, ("élément illisible : %s"):format(path)
	end

	local data = parse(lines)
	cache[path] = { mtime = mtime, data = data }
	return data
end

---Vide le cache. Utile en test, et après une modification faite hors de Neovim.
function M.clear()
	cache = {}
end

return M
