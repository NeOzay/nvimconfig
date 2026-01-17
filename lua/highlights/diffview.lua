-- Diffview highlights for Sonokai theme

return function()
	local colors = require("base46").get_theme_tb("base_30") ---@type Base30Table

	local highlights = {
		-- File panel
		DiffviewFilePanelTitle = { fg = colors.blue, bold = true },
		DiffviewFilePanelCounter = { fg = colors.purple, bold = true },
		DiffviewFilePanelFileName = { fg = colors.white },
		DiffviewFilePanelPath = { fg = colors.grey_fg },
		DiffviewFilePanelRootPath = { fg = colors.grey_fg },
		DiffviewFilePanelInsertions = { fg = colors.green },
		DiffviewFilePanelDeletions = { fg = colors.red },
		DiffviewFilePanelConflicts = { fg = colors.orange },

		-- Diff highlights
		DiffviewDiffAdd = { bg = "#394634" },
		DiffviewDiffAddText = { bg = "#4a5d42" },
		DiffviewDiffDelete = { bg = "#55393d" },
		DiffviewDiffDeleteText = { bg = "#6e4549" },
		DiffviewDiffChange = { bg = "#354157" },
		DiffviewDiffChangeText = { bg = "#45567a" },

		-- Status
		DiffviewStatusAdded = { fg = colors.green },
		DiffviewStatusModified = { fg = colors.cyan },
		DiffviewStatusRenamed = { fg = colors.blue },
		DiffviewStatusCopied = { fg = colors.blue },
		DiffviewStatusTypeChanged = { fg = colors.purple },
		DiffviewStatusUnmerged = { fg = colors.orange },
		DiffviewStatusUnknown = { fg = colors.grey_fg },
		DiffviewStatusDeleted = { fg = colors.red },
		DiffviewStatusBroken = { fg = colors.red },

		-- Dim text
		DiffviewDim1 = { fg = colors.grey_fg },
		DiffviewReference = { fg = colors.purple },
		DiffviewPrimary = { fg = colors.blue },
		DiffviewSecondary = { fg = colors.cyan },

		-- Normal backgrounds
		DiffviewNormal = { bg = colors.black },
		DiffviewCursorLine = { bg = colors.one_bg2 },
		DiffviewVertSplit = { fg = colors.line },
		DiffviewWinSeparator = { fg = colors.line },
		DiffviewEndOfBuffer = { fg = colors.black },
	}

	for group, opts in pairs(highlights) do
		vim.api.nvim_set_hl(0, group, opts)
	end
end
