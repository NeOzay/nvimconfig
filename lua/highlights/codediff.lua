-- CodeDiff highlights for Sonokai theme

local colors = require("base46").get_theme_tb("base_30") ---@as Base30Table
local bank = require("colors_bank").bank

return {
	-- Diff: line-level
	CodeDiffLineInsert = { bg = "CodeDiffLineInsert" },
	CodeDiffLineDelete = { bg = "CodeDiffLineDelete" },

	-- Diff: character-level (brighter)
	CodeDiffCharInsert = { bg = "CodeDiffCharInsert" },
	CodeDiffCharDelete = { bg = "CodeDiffCharDelete" },

	-- Filler lines
	CodeDiffFiller = { fg = colors.grey_fg },

	-- Explorer
	ExplorerDirectorySmall = { fg = colors.grey_fg },
	CodeDiffExplorerSelected = { bg = colors.one_bg2 },

	-- Conflict signs
	CodeDiffConflictSign = { fg = colors.orange },
	CodeDiffConflictSignResolved = { fg = colors.grey_fg },
	CodeDiffConflictSignAccepted = { fg = colors.green },
	CodeDiffConflictSignRejected = { fg = colors.red },

	-- History
	CodeDiffHistoryTitle = { fg = colors.blue, bold = true },
}
