-- Neogit highlights for Sonokai theme

return function()
	local colors = require("base46").get_theme_tb("base_30") ---@type Base30Table

	local highlights = {
		-- Headers
		NeogitHunkHeader = { fg = colors.blue, bg = colors.one_bg2 },
		NeogitHunkHeaderHighlight = { fg = colors.blue, bg = colors.one_bg3, bold = true },
		NeogitHunkHeaderCursor = { fg = colors.blue, bg = colors.one_bg3, bold = true },

		-- Diff context
		NeogitDiffContext = { bg = colors.black },
		NeogitDiffContextHighlight = { bg = colors.one_bg },
		NeogitDiffContextCursor = { bg = colors.one_bg2 },

		-- Diff add
		NeogitDiffAdd = { fg = colors.green, bg = "#394634" },
		NeogitDiffAddHighlight = { fg = colors.green, bg = "#3f4f38" },
		NeogitDiffAddCursor = { fg = colors.green, bg = "#4a5d42" },

		-- Diff delete
		NeogitDiffDelete = { fg = colors.red, bg = "#55393d" },
		NeogitDiffDeleteHighlight = { fg = colors.red, bg = "#5f4145" },
		NeogitDiffDeleteCursor = { fg = colors.red, bg = "#6e4549" },

		-- Branch
		NeogitBranch = { fg = colors.purple, bold = true },
		NeogitBranchHead = { fg = colors.purple, bold = true, underline = true },
		NeogitRemote = { fg = colors.green, bold = true },

		-- Status sections
		NeogitUnstagedchanges = { fg = colors.red, bold = true },
		NeogitStagedchanges = { fg = colors.green, bold = true },
		NeogitUntrackedfiles = { fg = colors.orange, bold = true },
		NeogitRecentcommits = { fg = colors.blue, bold = true },
		NeogitStashes = { fg = colors.purple, bold = true },
		NeogitUnmergedInto = { fg = colors.cyan, bold = true },
		NeogitUnpulledFrom = { fg = colors.cyan, bold = true },
		NeogitUnpushedTo = { fg = colors.cyan, bold = true },

		-- Change types
		NeogitChangeModified = { fg = colors.cyan, bold = true },
		NeogitChangeAdded = { fg = colors.green, bold = true },
		NeogitChangeDeleted = { fg = colors.red, bold = true },
		NeogitChangeRenamed = { fg = colors.purple, bold = true },
		NeogitChangeUpdated = { fg = colors.orange, bold = true },
		NeogitChangeCopied = { fg = colors.blue, bold = true },
		NeogitChangeUnmerged = { fg = colors.orange, bold = true },
		NeogitChangeNewFile = { fg = colors.green, bold = true },

		-- Sections
		NeogitSectionHeader = { fg = colors.purple, bold = true },
		NeogitSectionHeaderCount = { fg = colors.purple },

		-- Graph colors
		NeogitGraphAuthor = { fg = colors.cyan },
		NeogitGraphRed = { fg = colors.red },
		NeogitGraphWhite = { fg = colors.white },
		NeogitGraphYellow = { fg = colors.yellow },
		NeogitGraphGreen = { fg = colors.green },
		NeogitGraphCyan = { fg = colors.cyan },
		NeogitGraphBlue = { fg = colors.blue },
		NeogitGraphPurple = { fg = colors.purple },
		NeogitGraphGray = { fg = colors.grey_fg },
		NeogitGraphOrange = { fg = colors.orange },
		NeogitGraphBoldRed = { fg = colors.red, bold = true },
		NeogitGraphBoldWhite = { fg = colors.white, bold = true },
		NeogitGraphBoldYellow = { fg = colors.yellow, bold = true },
		NeogitGraphBoldGreen = { fg = colors.green, bold = true },
		NeogitGraphBoldCyan = { fg = colors.cyan, bold = true },
		NeogitGraphBoldBlue = { fg = colors.blue, bold = true },
		NeogitGraphBoldPurple = { fg = colors.purple, bold = true },
		NeogitGraphBoldGray = { fg = colors.grey_fg, bold = true },

		-- Commit view
		NeogitCommitViewHeader = { fg = colors.blue, bg = colors.one_bg2, bold = true },
		NeogitCommitViewDescription = { fg = colors.white },
		NeogitObjectId = { fg = colors.purple },

		-- Signature
		NeogitSignatureGood = { fg = colors.green },
		NeogitSignatureBad = { fg = colors.red },
		NeogitSignatureMissing = { fg = colors.orange },
		NeogitSignatureNone = { fg = colors.grey_fg },
		NeogitSignatureGoodUnknown = { fg = colors.yellow },
		NeogitSignatureGoodExpired = { fg = colors.orange },
		NeogitSignatureGoodExpiredKey = { fg = colors.yellow },
		NeogitSignatureGoodRevokedKey = { fg = colors.red },

		-- Tags
		NeogitTagName = { fg = colors.yellow },
		NeogitTagDistance = { fg = colors.cyan },

		-- Popup
		NeogitPopupSectionTitle = { fg = colors.purple, bold = true },
		NeogitPopupBranchName = { fg = colors.cyan, bold = true },
		NeogitPopupBold = { bold = true },
		NeogitPopupSwitchKey = { fg = colors.purple },
		NeogitPopupSwitchEnabled = { fg = colors.green, bold = true },
		NeogitPopupSwitchDisabled = { fg = colors.grey_fg },
		NeogitPopupOptionKey = { fg = colors.purple },
		NeogitPopupOptionEnabled = { fg = colors.green, bold = true },
		NeogitPopupOptionDisabled = { fg = colors.grey_fg },
		NeogitPopupConfigKey = { fg = colors.purple },
		NeogitPopupConfigEnabled = { fg = colors.green, bold = true },
		NeogitPopupConfigDisabled = { fg = colors.grey_fg },
		NeogitPopupActionKey = { fg = colors.purple },
		NeogitPopupActionDisabled = { fg = colors.grey_fg },

		-- Notification
		NeogitNotificationInfo = { fg = colors.cyan },
		NeogitNotificationWarning = { fg = colors.yellow },
		NeogitNotificationError = { fg = colors.red },

		-- Command history
		NeogitCommandText = { fg = colors.white },
		NeogitCommandTime = { fg = colors.grey_fg },
		NeogitCommandCodeNormal = { fg = colors.green },
		NeogitCommandCodeError = { fg = colors.red },

		-- Floating windows
		NeogitFloatHeader = { fg = colors.blue, bold = true },
		NeogitFloatHeaderHighlight = { fg = colors.blue, bg = colors.one_bg2, bold = true },

		-- Cursor line
		NeogitCursorLine = { bg = colors.one_bg2 },

		-- Fold signs
		NeogitFold = { fg = colors.grey_fg },
	}

	for group, opts in pairs(highlights) do
		vim.api.nvim_set_hl(0, group, opts)
	end
end
