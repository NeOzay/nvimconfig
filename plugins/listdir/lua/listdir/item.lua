---Lecture d'un élément : front matter TOML délimité par `+++`, puis le corps.
---
---C'est ici que se joue l'économie d'appels Python : `show` n'est jamais invoqué,
---Neovim lit le fichier lui-même. La lecture et son cache vivent dans le module
---commun `frontmatter` (`lua/frontmatter.lua` de la config), partagé avec les
---commandes de chantier.

local frontmatter = require("frontmatter")

---@alias Ozay.ListDir.ItemData Ozay.Frontmatter.Data

---@class Ozay.ListDir.ItemReader
local M = {}

---@param path string
---@return Ozay.ListDir.ItemData? data
---@return string? err
---@nodiscard
function M.read(path)
	return frontmatter.read(path)
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
	frontmatter.clear()
end

return M
