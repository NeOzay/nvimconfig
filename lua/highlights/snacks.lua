-- Snacks picker highlights for Sonokai theme

local colors = require("base46").get_theme_tb("base_30") ---@as Base30Table
local mix = require("colors_bank").mix_colors_group
local lightness = require("base46.colors").change_hex_lightness
local bank = require("colors_bank").bank

---@type Base46HLTable
return {
	SnacksNormal = { fg = colors.white, bg = colors.black },
	SnacksNormalNC = { fg = colors.white, bg = colors.black },

	-- Picker
	SnacksPicker = { link = "SnacksNormal" },
	SnacksPickerBorder = { fg = colors.line },
	SnacksPickerMatch = { fg = colors.green, bold = true },
	SnacksPickerDir = { fg = mix("comment", "Normal", 60) },
	SnacksPickerListCursorLine = { bg = colors.one_bg3 },
	SnacksPickerPreviewCursorLine = { bg = colors.one_bg3 },

	SnacksPickerInputTitle = { fg = colors.black, bg = colors.red },
	SnacksPickerListTitle = { fg = colors.green, bg = colors.black },
	SnacksPickerPreviewTitle = { fg = colors.black, bg = colors.blue },

	SnacksPickerInputBorder = { fg = colors.one_bg3 },
	SnacksPickerRow = { link = "LineNr" },
	SnacksPickerCol = { fg = lightness(colors.green, -10), bg = colors.lightbg },
	SnacksPickerPrompt = { fg = colors.green, bg = colors.black },
	SnacksPickerTotals = { fg = colors.green },
	SnacksFooter = { link = "none" },
	SnacksFooterDesc = { fg = colors.green, bg = bank.scratch_desc },
	SnacksFooterKey = { fg = colors.green, bg = colors.one_bg3 },

	-- Explorer tree
	SnacksPickerTree = { fg = colors.grey },

	-- Git status dans l'explorer
	SnacksPickerGitStatusAdded = { fg = colors.green },
	SnacksPickerGitStatusModified = { fg = colors.yellow },
	SnacksPickerGitStatusDeleted = { fg = colors.red },
	SnacksPickerGitStatusRenamed = { fg = colors.cyan },
	SnacksPickerGitStatusCopied = { fg = colors.cyan },
	SnacksPickerGitStatusUntracked = { fg = colors.grey_fg },
	SnacksPickerGitStatusStaged = { fg = colors.green },
	SnacksPickerGitStatusUnmerged = { fg = colors.red },

	-- Words
	LspReferenceText = { underline = true },
	LspReferenceRead = { underdotted = true },
	LspReferenceWrite = { underdashed = true },
}
