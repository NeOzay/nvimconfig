---Lecture d'un élément : front matter TOML délimité par `+++`, puis le corps.
---
---C'est ici que se joue l'économie d'appels Python : `show` n'est jamais invoqué,
---Neovim lit le fichier lui-même. Le cache, invalidé sur `mtime`, évite de relire
---les fichiers inchangés à chaque changement de tri.

local DELIM = "+++"

---@class Ozay.ListDir.ItemData
---@field fields table<string, string> valeurs du front matter, telles qu'écrites
---@field body string corps de l'élément, front matter retiré

---@class Ozay.ListDir.ItemReader
local M = {}

---@class Ozay.ListDir.CacheEntry
---@field mtime integer
---@field data Ozay.ListDir.ItemData

---@type table<string, Ozay.ListDir.CacheEntry>
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
---@return Ozay.ListDir.ItemData
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
---@return Ozay.ListDir.ItemData? data
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

---Le titre d'un élément, ou son id à défaut.
---@param path string
---@param id string
---@return string
---@nodiscard
function M.title(path, id)
	local data = M.read(path)
	local title = data and data.fields.title
	return (title and title ~= "") and title or id
end

---Vide le cache. Utile en test, et après une modification faite hors de Neovim.
function M.clear()
	cache = {}
end

return M
