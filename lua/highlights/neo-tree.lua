-- Neo-tree highlights for Sonokai theme
-- These highlights are loaded via autocmd after ColorScheme

return function()
	local colors = require("base46").get_theme_tb("base_30") ---@as Base30Table

	local highlights = {
		-- Neo-tree UI
		NeoTreeNormal = { bg = colors.black, fg = colors.white },
		NeoTreeNormalNC = { bg = colors.black, fg = colors.white },
		NeoTreeEndOfBuffer = { bg = colors.black },
		NeoTreeVertSplit = { fg = colors.one_bg, bg = colors.one_bg },
		NeoTreeWinSeparator = { fg = colors.one_bg, bg = colors.one_bg },

		-- Borders
		NeoTreeFloatBorder = { fg = colors.line, bg = colors.black },
		NeoTreeFloatTitle = { fg = colors.white, bg = colors.one_bg2, bold = true },

		-- Title & tabs
		NeoTreeTitleBar = { fg = colors.white, bg = colors.one_bg2, bold = true },
		NeoTreeTabActive = { fg = colors.white, bg = colors.black, bold = true },
		NeoTreeTabInactive = { fg = colors.grey_fg, bg = colors.one_bg },
		NeoTreeTabSeparatorActive = { fg = colors.black, bg = colors.black },
		NeoTreeTabSeparatorInactive = { fg = colors.one_bg, bg = colors.one_bg },

		-- Files & Directories
		NeoTreeFileName = { fg = colors.white },
		NeoTreeDirectoryName = { fg = colors.blue },
		NeoTreeDirectoryIcon = { fg = colors.blue },
		NeoTreeRootName = { fg = colors.cyan, bold = true },
		NeoTreeFileIcon = { fg = colors.white },
		NeoTreeFileNameOpened = { fg = colors.green },

		-- Indents
		NeoTreeIndentMarker = { fg = colors.grey },
		NeoTreeExpander = { fg = colors.grey_fg },

		-- Git status
		NeoTreeGitAdded = { fg = colors.green },
		NeoTreeGitConflict = { fg = colors.red },
		NeoTreeGitDeleted = { fg = colors.red },
		NeoTreeGitIgnored = { fg = colors.grey },
		NeoTreeGitModified = { fg = colors.yellow },
		NeoTreeGitUnstaged = { fg = colors.orange },
		NeoTreeGitUntracked = { fg = colors.grey_fg },
		NeoTreeGitStaged = { fg = colors.green },

		-- Symbols & Indicators
		NeoTreeSymbolicLinkTarget = { fg = colors.cyan },
		NeoTreeDotfile = { fg = colors.grey_fg },
		NeoTreeModified = { fg = colors.yellow },

		-- Diagnostics
		NeoTreeDiagnosticError = { fg = colors.red },
		NeoTreeDiagnosticWarn = { fg = colors.yellow },
		NeoTreeDiagnosticInfo = { fg = colors.cyan },
		NeoTreeDiagnosticHint = { fg = colors.green },

		-- Cursor & selection
		NeoTreeCursorLine = { bg = colors.one_bg2 },
		NeoTreeDimText = { fg = colors.grey },

		-- Filter
		NeoTreeFilterTerm = { fg = colors.green, bold = true },

		-- Preview
		NeoTreeFloatNormal = { bg = colors.black },
	}

	-- Apply highlights
	for group, opts in pairs(highlights) do
		vim.api.nvim_set_hl(0, group, opts)
	end
end
