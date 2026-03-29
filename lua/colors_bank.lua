---@namespace Ozay

local api = vim.api
local mix = require("base46.colors").mix
local colors = require("base46").get_theme_tb("base_30") ---@as Base30Table

local M = {}

local hi_cache = {}

---@param fg string @Highlight group name for foreground
---@param bg string @Highlight group name for background
---@param opts? vim.api.keyset.highlight @Optional highlight options to override the default
function M.hi_pathwork(fg, bg, opts)
	local hi_key = fg .. "&" .. bg
	local new_hi = fg .. bg
	if hi_cache[hi_key] then
		return hi_cache[hi_key]
	end
	local main_hi = opts or {}
	main_hi.fg = api.nvim_get_hl(0, { name = fg, link = false }).fg
	main_hi.bg = api.nvim_get_hl(0, { name = bg, link = false }).bg
	api.nvim_set_hl(0, new_hi, main_hi)
	hi_cache[hi_key] = new_hi
	return new_hi
end

Userautocmd("ColorScheme", {
	callback = function()
		for k in pairs(hi_cache) do
			local fg, bg = k:match("^(.*)&(.*)$")
			M.hi_pathwork(fg, bg)
		end
	end,
})

---@param group string @Highlight group name
---@param attr keyof vim.api.keyset.highlight @Highlight attribute to retrieve (e.g., "fg", "bg", "bold", etc.)
function M.get_hi_attr(group, attr)
	local hl = api.nvim_get_hl(0, { name = group, link = false })
	if hl and hl[attr] then
		return hl[attr]
	end
	return "#000000" -- Default to black if attribute is not found
end

local function int_to_hex(n)
	return "#" .. string.format("%06x", n)
end

---@param group1 string @Highlight group name or hex color code
---@param group2 string @Highlight group name or hex color code
---@param strength? number @Strength of the mix (0 to 100, where 0 is all group1 and 100 is all group2)
---@param ground? "fg"|"bg" @Whether to mix foreground or background colors (default: "fg")
---@return string @The RGB color code of the mixed highlight group
function M.mix_colors_group(group1, group2, strength, ground)
	strength = strength or 50
	ground = ground or "fg"

	local color1
	if vim.startswith(group1, "#") then
		color1 = group1
	else
		color1 = api.nvim_get_hl(0, { name = group1, link = false })[ground]
		color1 = int_to_hex(color1 or 0)
	end

	local color2
	if vim.startswith(group2, "#") then
		color2 = group2
	else
		color2 = api.nvim_get_hl(0, { name = group2, link = false })[ground]
		color2 = int_to_hex(color2 or 0)
	end
	vim.schedule(function()
		vim.print(color2)
	end)
	return mix(color1, color2, strength)
end

return M
