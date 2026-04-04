-- Résolution des couleurs palette pour les tables de highlights.
-- Module pur : ne dépend d'aucun état global.

local colors = require("base46.colors")
local change_lightness = colors.change_hex_lightness
local mix = colors.mix
local M = {}

---@return table<string, string>
function M.get_palette()
	local base46 = require("base46")
	local palette = vim.tbl_extend(
		"force",
		base46.get_theme_tb("base_30"),
		base46.get_theme_tb("base_16"),
		base46.get_theme_tb("extended_palette") or {}
	)
	for name, color in pairs(base46.config.extended_palette or {}) do
		palette[name] = M.resolve_color(color, palette)
	end
	return palette
end

---@param val Base46MixedColor|Base46ExtendedColors
---@param palette table<string, string>
---@return string
function M.resolve_color(val, palette)
	if type(val) == "string" then
		return palette[val] or val
	end
	---@cast val Base46MixedColor.2
	local v1 = val[1]
	local c1 = M.resolve_color(v1, palette)
	local n = #val
	if n == 2 then
		---@cast val Base46MixedColor.2
		return change_lightness(c1, val[2])
	else
		---@cast val Base46MixedColor.4
		local v2 = val[2]
		local c2 = M.resolve_color(v2, palette)
		local color = mix(c1, c2, val[3])
		if val[4] then
			color = change_lightness(color, val[4])
		end
		return color
	end
end

--- Résout la syntaxe spéciale de couleurs dans une table de highlights.
--- - `"blue"` → valeur hex depuis la palette
--- - `{ "blue", -20 }` → changement de luminosité
--- - `{ "orange", "line", 80 }` → fusion de 2 couleurs
---@param tb Base46HLTable
---@param palette table<string, string> Palette fusionnée (base_30 + base_16)
---@return table<string, vim.api.keyset.highlight>
function M.resolve(tb, palette)
	local color_keys = { "fg", "bg", "sp" }
	local result = {}

	for group, hlgroups in pairs(tb) do
		-- Shallow copy : les valeurs sont scalaires ou des tuples qu'on remplace (jamais mutés)
		local copy = {}
		for k, v in pairs(hlgroups) do
			copy[k] = v
		end

		for i = 1, 3 do
			local key = color_keys[i]
			local val = copy[key]
			if val ~= nil then
				if type(val) == "string" then
					copy[key] = palette[val] or val
				elseif type(val) == "table" then
					copy[key] = M.resolve_color(val, palette)
				end
			end
		end

		result[group] = copy
	end

	return result
end

return M
