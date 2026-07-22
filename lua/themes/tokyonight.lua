-- Thème pour `term_theme` — base_30/base_16 adaptés de NvChad/base46 (v3.0) tokyonight ;
-- base_16_terminal (couleurs ANSI) repris tel quel du thème wezterm "tokyonight_night" (folke)
-- de l'utilisateur, pour que le terminal intégré retrouve exactement les couleurs de son terminal
-- externe.
-- https://raw.githubusercontent.com/NvChad/base46/refs/heads/v3.0/lua/base46/themes/tokyonight.lua

---@type Base46Theme
local M = {}

---@type Base30Table
M.base_30 = {
	white = "#c0caf5",
	darker_black = "#16161e",
	black = "#1a1b26",
	black2 = "#1f2336",
	one_bg = "#24283b",
	one_bg2 = "#414868",
	one_bg3 = "#353b45",
	grey = "#40486a",
	grey_fg = "#565f89",
	grey_fg2 = "#4f5779",
	light_grey = "#545c7e",
	red = "#f7768e",
	baby_pink = "#DE8C92",
	pink = "#ff75a0",
	line = "#32333e",
	green = "#9ece6a",
	vibrant_green = "#73daca",
	nord_blue = "#80a8fd",
	blue = "#7aa2f7",
	yellow = "#e0af68",
	sun = "#EBCB8B",
	purple = "#bb9af7",
	dark_purple = "#9d7cd8",
	teal = "#1abc9c",
	orange = "#ff9e64",
	cyan = "#7dcfff",
	statusline_bg = "#1d1e29",
	lightbg = "#32333e",
	pmenu_bg = "#7aa2f7",
	folder_bg = "#7aa2f7",
}

---@type Base16Table
M.base_16 = {
	base00 = "#1a1b26",
	base01 = "#16161e",
	base02 = "#2f3549",
	base03 = "#444b6a",
	base04 = "#787c99",
	base05 = "#a9b1d6",
	base06 = "#cbccd1",
	base07 = "#d5d6db",
	base08 = "#73daca",
	base09 = "#ff9e64",
	base0A = "#0db9d7",
	base0B = "#9ece6a",
	base0C = "#b4f9f8",
	base0D = "#2ac3de",
	base0E = "#bb9af7",
	base0F = "#f7768e",
}

M.type = "dark"

-- Couleurs terminal ANSI — valeurs exactes du thème wezterm "tokyonight_night" de l'utilisateur
-- (colors.ansi / colors.brights), pas une approximation depuis base_30.
---@type Base16TerminalTable
M.base_16_terminal = {
	-- ansi
	[0] = "#15161e",
	[1] = "#f7768e",
	[2] = "#9ece6a",
	[3] = "#e0af68",
	[4] = "#7aa2f7",
	[5] = "#bb9af7",
	[6] = "#7dcfff",
	[7] = "#a9b1d6",
	-- brights
	[8] = "#414868",
	[9] = "#ff899d",
	[10] = "#9fe044",
	[11] = "#faba4a",
	[12] = "#8db0ff",
	[13] = "#c7a9ff",
	[14] = "#a4daff",
	[15] = "#c0caf5",
}

return M
