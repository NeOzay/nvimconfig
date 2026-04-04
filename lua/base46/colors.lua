-- Color manipulation utilities for the base46 theme system.
-- Forked from nvchad/base46 (MIT License, Leon Heidelbach).
local api = vim.api

local M = {}

---Convert a hex color value to RGB.
---@param hex string Hex color value (e.g. "#ff0000")
---@return integer? r Red (0-255)
---@return integer? g Green (0-255)
---@return integer? b Blue (0-255)
M.hex2rgb = function(hex)
	local hash = string.sub(hex, 1, 1) == "#"
	if string.len(hex) ~= (7 - (hash and 0 or 1)) then
		return nil
	end

	local r = tonumber(hex:sub(2 - (hash and 0 or 1), 3 - (hash and 0 or 1)), 16)
	local g = tonumber(hex:sub(4 - (hash and 0 or 1), 5 - (hash and 0 or 1)), 16)
	local b = tonumber(hex:sub(6 - (hash and 0 or 1), 7 - (hash and 0 or 1)), 16)
	return r, g, b
end

---Convert an RGB color value to hex.
---@param r number Red (0-255)
---@param g number Green (0-255)
---@param b number Blue (0-255)
---@return string hex Hex color value (e.g. "#ff0000")
M.rgb2hex = function(r, g, b)
	return string.format("#%02x%02x%02x", math.floor(r), math.floor(g), math.floor(b))
end

---Helper for HSL to RGB conversion.
---@param p number
---@param q number
---@param a number
---@return number
M.hsl2rgb_helper = function(p, q, a)
	if a < 0 then
		a = a + 6
	end
	if a >= 6 then
		a = a - 6
	end
	if a < 1 then
		return (q - p) * a + p
	elseif a < 3 then
		return q
	elseif a < 4 then
		return (q - p) * (4 - a) + p
	else
		return p
	end
end

---Convert a HSL color value to RGB.
---@param h number Hue (0-360)
---@param s number Saturation (0-1)
---@param l number Lightness (0-1)
---@return number r Red (0-255)
---@return number g Green (0-255)
---@return number b Blue (0-255)
M.hsl2rgb = function(h, s, l)
	local t1, t2, r, g, b

	h = h / 60
	if l <= 0.5 then
		t2 = l * (s + 1)
	else
		t2 = l + s - (l * s)
	end

	t1 = l * 2 - t2
	r = M.hsl2rgb_helper(t1, t2, h + 2) * 255
	g = M.hsl2rgb_helper(t1, t2, h) * 255
	b = M.hsl2rgb_helper(t1, t2, h - 2) * 255

	return r, g, b
end

---Convert an RGB color value to HSL.
---@param r number Red (0-255)
---@param g number Green (0-255)
---@param b number Blue (0-255)
---@return number h Hue (0-360)
---@return number s Saturation (0-1)
---@return number l Lightness (0-1)
M.rgb2hsl = function(r, g, b)
	local min, max, l, s, maxcolor, h
	r, g, b = r / 255, g / 255, b / 255

	min = math.min(r, g, b)
	max = math.max(r, g, b)
	maxcolor = 1 + (max == b and 2 or (max == g and 1 or 0))

	if maxcolor == 1 then
		h = (g - b) / (max - min)
	elseif maxcolor == 2 then
		h = 2 + (b - r) / (max - min)
	elseif maxcolor == 3 then
		h = 4 + (r - g) / (max - min)
	end

	if not rawequal(type(h), "number") then
		h = 0
	end

	h = h * 60

	if h < 0 then
		h = h + 360
	end

	l = (min + max) / 2

	if min == max then
		s = 0
	else
		if l < 0.5 then
			s = (max - min) / (max + min)
		else
			s = (max - min) / (2 - max - min)
		end
	end

	return h, s, l
end

---Convert a hex color value to HSL.
---@param hex string Hex color value
---@return number h Hue (0-360)
---@return number s Saturation (0-1)
---@return number l Lightness (0-1)
M.hex2hsl = function(hex)
	local r, g, b = M.hex2rgb(hex)
	return M.rgb2hsl(r, g, b)
end

---Convert a HSL color value to hex.
---@param h number Hue (0-360)
---@param s number Saturation (0-1)
---@param l number Lightness (0-1)
---@return string hex Hex color value
M.hsl2hex = function(h, s, l)
	local r, g, b = M.hsl2rgb(h, s, l)
	return M.rgb2hex(r, g, b)
end

---Lighten or darken a color by a given percentage.
---@param hex string Hex color value
---@param percent number Percentage to lighten (+) or darken (-) the color
---@return string hex Modified hex color value
M.change_hex_lightness = function(hex, percent)
	local h, s, l = M.hex2hsl(hex)
	l = l + (percent / 100)
	if l > 1 then
		l = 1
	end
	if l < 0 then
		l = 0
	end
	return M.hsl2hex(h, s, l)
end

---Mix two colors with a given percentage.
---@param first string Primary hex color
---@param second string Hex color to mix into the first
---@param strength? number Percentage of second color (0-100, default 50)
---@return string hex Mixed hex color value
M.mix = function(first, second, strength)
	if strength == nil then
		strength = 0.5
	end

	local s = strength / 100
	local r1, g1, b1 = M.hex2rgb(first)
	local r2, g2, b2 = M.hex2rgb(second)

	if r1 == nil or r2 == nil then
		return first
	end

	if s == 0 then
		return first
	elseif s == 1 then
		return second
	end

	local r3 = r1 * (1 - s) + r2 * s
	local g3 = g1 * (1 - s) + g2 * s
	local b3 = b1 * (1 - s) + b2 * s

	return M.rgb2hex(r3, g3, b3)
end

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
---@param ... keyof vim.api.keyset.highlight @Highlight attributes to retrieve (e.g., "fg", "bg", "bold", etc.)
---@return any... @values of the requested attributes
function M.get_hi_attr(group, ...)
	local hl = api.nvim_get_hl(0, { name = group, link = false })
	local results = {}
	for _, attr in ipairs({ ... }) do
		if not hl or hl[attr] == nil then
			error("Highlight group '" .. group .. "' does not have attribute '" .. attr .. "'")
		end
		results[#results + 1] = hl[attr]
	end
	return unpack(results)
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
	return M.mix(color1, color2, strength)
end

--- Create a new highlight definition by overriding specific attributes of an existing highlight group.
---@param group string
---@param opts vim.api.keyset.highlight
---@return vim.api.keyset.highlight
function M.override_group(group, opts)
	local hl = api.nvim_get_hl(0, { name = group, link = false }) ---@as vim.api.keyset.highlight
	hl = vim.tbl_deep_extend("force", hl, opts)
	return hl
end

return M
