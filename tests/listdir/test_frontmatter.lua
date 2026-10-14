-- Reconnaissance des Marqueurs, génériques et typés, et leur affichage en retrait dans le picker
-- d'éléments.

local new_set = MiniTest.new_set
local expect = MiniTest.expect

local frontmatter = require("frontmatter")

local T = new_set()

T["is_marker"] = new_set()

local cases = {
	{ "<À REMPLIR>", true },
	{ "<OPTIONNEL>", true },
	{ "<À REMPLIR date>", true },
	{ "<OPTIONNEL date>", true },
	{ "<OPTIONNEL list[str]>", true },
	{ "<OPTIONNELLE>", false },
	{ "<À REMPLIRE>", false },
	{ "2026-10-14", false },
	{ "voir <OPTIONNEL>", false },
	{ "", false },
}

for _, case in ipairs(cases) do
	local value, expected = case[1], case[2]
	T["is_marker"][("%q → %s"):format(value, tostring(expected))] = function()
		expect.equality(frontmatter.is_marker(value), expected)
	end
end

T["is_marker"]["nil → false"] = function()
	expect.equality(frontmatter.is_marker(nil), false)
end

T["format"] = new_set()

---@param value string
---@return string[] texts
local function formatted(value)
	local items = require("listdir.picker.items")
	local entry = { ld_id = "une-dette", ld_value = value, text = "Une dette" }
	return vim.tbl_map(function(chunk)
		return chunk[1]
	end, items.format(entry, {}))
end

T["format"]["un Marqueur typé reste en retrait"] = function()
	expect.equality(formatted("<OPTIONNEL date>"), { "une-dette", "  ", "Une dette" })
end

T["format"]["une valeur écrite s'affiche en colonne"] = function()
	expect.equality(formatted("2026-10-14"), { "une-dette", "  ", "2026-10-14", "  ", "Une dette" })
end

return T
