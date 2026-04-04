local palette = require("base46").get_palette()
local mixcolors = require("base46.colors").mix
local generate_color = require("base46.colors").change_hex_lightness
local colors = require("base46.colors")

local black2_l = generate_color(palette.black2, 6)
local black2_d = generate_color(palette.black2, -6)

local highlights = {
	BlinkCmpMenu = { bg = palette.black },
	BlinkCmpMenuBorder = { fg = palette.grey_fg },
	BlinkCmpMenuSelection = { link = "PmenuSel" },
	BlinkCmpScrollBarThumb = { bg = palette.grey },
	BlinkCmpScrollBarGutter = { bg = palette.black2 },
	BlinkCmpLabel = { fg = palette.white },
	BlinkCmpLabelDeprecated = { fg = palette.red, strikethrough = true },
	BlinkCmpLabelMatch = { fg = palette.blue, bold = true },
	BlinkCmpLabelDetail = { fg = palette.light_grey },
	BlinkCmpLabelDescription = { fg = palette.light_grey },
	BlinkCmpSource = { fg = palette.grey_fg },
	BlinkCmpGhostText = { fg = palette.grey_fg },
	BlinkCmpDoc = { bg = palette.black },
	BlinkCmpDocBorder = { fg = palette.grey_fg },
	BlinkCmpDocSeparator = { fg = palette.grey },
	BlinkCmpDocCursorLine = { bg = palette.one_bg },
	BlinkCmpSignatureHelp = { bg = palette.black },
	BlinkCmpSignatureHelpBorder = { fg = palette.grey_fg },
	BlinkCmpSignatureHelpActiveParameter = { fg = palette.blue, bold = true },
}

-- Kind highlights
local kinds = {
	Constant = "@constant",
	Function = "@function",
	Identifier = palette.red,
	Field = "@variable.member",
	Variable = "@variable",
	Snippet = palette.yellow,
	Text = palette.green,
	Structure = "Structure",
	Type = "@type",
	Keyword = "@keyword",
	Method = "@function.method",
	Constructor = "@constructor",
	Folder = palette.pure_white,
	Module = "@module",
	Property = "@property",
	Enum = "@lsp.type.enum",
	Unit = palette.purple,
	Class = "@lsp.type.class",
	File = palette.pure_white,
	Interface = "@lsp.type.interface",
	Color = palette.white,
	Reference = palette.white,
	EnumMember = "@lsp.type.enumMember",
	Struct = "@lsp.type.struct",
	Value = palette.cyan,
	Event = "@lsp.type.event",
	Operator = "Operator",
	TypeParameter = "@lsp.type.typeParameter",
	Copilot = palette.green,
	Codeium = palette.vibrant_green,
	TabNine = palette.baby_pink,
	SuperMaven = palette.yellow,
}

for kind, color in pairs(kinds) do
	if vim.startswith(color, "#") then
		highlights["BlinkCmpKind" .. kind] = { fg = color, italic = true, bold = false }
	else
		highlights["BlinkCmpKind" .. kind] = colors.override_group(color, { italic = true, bold = false })
	end
end

-- style-specific overrides
-- local cmp_ui = require("nvconfig").ui.cmp

local styles = {
	default = {
		BlinkCmpMenuBorder = { fg = palette.grey_fg },
	},

	atom = {
		BlinkCmpMenu = { bg = palette.black2 },
		BlinkCmpDoc = { bg = palette.darker_black },
		BlinkCmpDocBorder = { fg = palette.darker_black, bg = palette.darker_black },
	},

	atom_colored = {
		BlinkCmpMenu = { bg = palette.black2 },
		BlinkCmpDoc = { bg = palette.darker_black },
		BlinkCmpDocBorder = { fg = palette.darker_black, bg = palette.darker_black },
	},

	flat_light = {
		BlinkCmpMenu = { bg = palette.black2 },
		BlinkCmpDoc = { bg = palette.darker_black },
		BlinkCmpMenuBorder = { fg = palette.black2, bg = palette.black2 },
		BlinkCmpDocBorder = { fg = palette.darker_black, bg = palette.darker_black },
	},

	flat_dark = {
		BlinkCmpMenu = { bg = palette.darker_black },
		BlinkCmpDoc = { bg = palette.black2 },
		BlinkCmpMenuBorder = { fg = palette.darker_black, bg = palette.darker_black },
		BlinkCmpDocBorder = { fg = palette.black2, bg = palette.black2 },
	},
}

-- -- atom style: add bg to kinds
-- if cmp_ui.style == "atom" then
--   for kind, _ in pairs(kinds) do
--     local hl_name = "BlinkCmpKind" .. kind
--     highlights[hl_name] = vim.tbl_deep_extend("force", highlights[hl_name] or {}, {
--       bg = vim.o.bg == "dark" and black2_l or black2_d,
--     })
--   end
-- end
--
-- -- atom_colored: mix fg with black for bg
-- if cmp_ui.style == "atom_colored" then
--   for kind, _ in pairs(kinds) do
--     local hl_name = "BlinkCmpKind" .. kind
--     local fg = highlights[hl_name] and highlights[hl_name].fg or colors.white
--     highlights[hl_name] = {
--       fg = fg,
--       bg = mixcolors(fg, colors.black, 70),
--     }
--   end
-- end

-- merge style overrides
-- highlights = vim.tbl_deep_extend("force", highlights , styles[cmp_ui.style] or {})

return highlights
