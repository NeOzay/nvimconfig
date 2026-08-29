---Recherche des répertoires-listes sous les chemins configurés.
---
---Un répertoire-liste se reconnaît à son `.list/contract.toml` : c'est la seule
---marque que le contrat de `list-dir` garantit.

local config = require("listdir.config")
local contract = require("listdir.contract")

---@class Ozay.ListDir.Entry
---@field path string chemin absolu du répertoire-liste
---@field name string nom déclaré au contrat
---@field description string
---@field fields Ozay.ListDir.Field[]

---@class Ozay.ListDir.Discover
local M = {}

---@param dir string
---@param out Ozay.ListDir.Entry[]
---@param seen table<string, true>
local function collect(dir, out, seen)
	local abs = vim.fs.abspath(dir)
	if seen[abs] then
		return
	end
	local found = contract.read(abs)
	if found then
		seen[abs] = true
		out[#out + 1] = {
			path = abs,
			name = found.name,
			description = found.description,
			fields = found.fields,
		}
	end
end

---@param paths? string[] défaut : les chemins de la configuration
---@param depth? integer défaut : `depth` de la configuration
---@return Ozay.ListDir.Entry[]
---@nodiscard
function M.find(paths, depth)
	paths = paths or config.paths()
	depth = depth or config.options.depth

	---@type Ozay.ListDir.Entry[]
	local out = {}
	---@type table<string, true>
	local seen = {}

	---@type table<string, true>
	local ignored = {}
	for _, name in ipairs(config.options.ignore) do
		ignored[name] = true
	end
	---`vim.fs.dir` cesse de descendre quand `skip` rend `false`.
	---@param name string
	---@return boolean
	local function skip(name)
		return not ignored[name]
	end

	for _, root in ipairs(paths) do
		local stat = vim.uv.fs_stat(root)
		if stat and stat.type == "directory" then
			-- La racine elle-même peut être un répertoire-liste : `vim.fs.dir` ne
			-- rend que son contenu, jamais elle.
			collect(root, out, seen)
			for name, kind in vim.fs.dir(root, { depth = depth, skip = skip }) do
				if kind == "directory" and vim.fs.basename(name) == ".list" then
					collect(vim.fs.dirname(vim.fs.joinpath(root, name)), out, seen)
				end
			end
		end
	end

	table.sort(out, function(a, b)
		return a.name < b.name
	end)
	return out
end

return M
