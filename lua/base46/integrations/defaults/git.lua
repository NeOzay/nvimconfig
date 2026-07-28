local theme = require("base46").get_theme_tb("base_16")
local colors = require("base46").get_theme_tb("base_30")
local mix = require("base46.colors").mix

---@type Base46HLTable
return {
	GitSignsAdd = { fg = colors.green, bg = colors.one_bg },
	GitSignsChange = { fg = colors.cyan, bg = colors.one_bg },
	GitSignsDelete = { fg = colors.red, bg = colors.one_bg },
	GitSignsChangeInline = { bg = "DiffChangeInline" },
	GitSignsAddInline = { bg = "DiffAddInline" },
	GitSignsDeleteInline = { bg = "DiffDeleteInline" },

	diffOldFile = {
		fg = colors.baby_pink,
	},

	diffNewFile = {
		fg = colors.blue,
	},

	DiffAdd = {
		bg = "DiffAdd",
	},

	DiffAdded = {
		bg = "green",
	},

	DiffChange = {
		bg = "DiffChange",
		-- fg = colors.light_grey,
	},

	DiffChangeDelete = {
		bg = "DiffChangeInline",
	},

	DiffModified = {
		bg = "cyan",
	},

	DiffDelete = {
		bg = "DiffRemoved",
	},

	DiffRemoved = {
		bg = "red",
	},

	DiffText = {
		bg = "DiffChangeInline",
	},

	-- git commits
	gitcommitOverflow = {
		fg = theme.base08,
	},

	gitcommitSummary = {
		fg = theme.base0B,
	},

	gitcommitComment = {
		fg = theme.base03,
	},

	gitcommitUntracked = {
		fg = theme.base03,
	},

	gitcommitDiscarded = {
		fg = theme.base03,
	},

	gitcommitSelected = {
		fg = theme.base03,
	},

	gitcommitHeader = {
		fg = theme.base0E,
	},

	gitcommitSelectedType = {
		fg = theme.base0D,
	},

	gitcommitUnmergedType = {
		fg = theme.base0D,
	},

	gitcommitDiscardedType = {
		fg = theme.base0D,
	},

	gitcommitBranch = {
		fg = theme.base09,
		bold = true,
	},

	gitcommitUntrackedFile = {
		fg = theme.base0A,
	},

	gitcommitUnmergedFile = {
		fg = theme.base08,
		bold = true,
	},

	gitcommitDiscardedFile = {
		fg = theme.base08,
		bold = true,
	},

	gitcommitSelectedFile = {
		fg = theme.base0B,
		bold = true,
	},
}
