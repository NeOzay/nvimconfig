-- Markview highlights for Sonokai theme
-- These highlights are loaded via autocmd after ColorScheme

return function()
	local colors = require("base46").get_theme_tb("base_30") ---@as Base30Table
	local mix = require("base46.colors").mix

	local code_bg = mix(colors.one_bg2, colors.black, 15)
	local highlights = {
		-- Palette (background + foreground)
		MarkviewPalette0 = { bg = colors.one_bg2, fg = colors.white },
		MarkviewPalette1 = { bg = colors.red, fg = colors.black },
		MarkviewPalette2 = { bg = colors.orange, fg = colors.black },
		MarkviewPalette3 = { bg = colors.yellow, fg = colors.black },
		MarkviewPalette4 = { bg = colors.green, fg = colors.black },
		MarkviewPalette5 = { bg = colors.blue, fg = colors.black },
		MarkviewPalette6 = { bg = colors.purple, fg = colors.black },

		-- Palette foreground only
		MarkviewPalette0Fg = { fg = colors.white },
		MarkviewPalette1Fg = { fg = colors.red },
		MarkviewPalette2Fg = { fg = colors.orange },
		MarkviewPalette3Fg = { fg = colors.yellow },
		MarkviewPalette4Fg = { fg = colors.green },
		MarkviewPalette5Fg = { fg = colors.blue },
		MarkviewPalette6Fg = { fg = colors.purple },

		-- Headings
		MarkviewHeading1 = { bg = colors.one_bg2, fg = colors.red, bold = true },
		MarkviewHeading2 = { bg = colors.one_bg2, fg = colors.orange, bold = true },
		MarkviewHeading3 = { bg = colors.one_bg2, fg = colors.yellow, bold = true },
		MarkviewHeading4 = { bg = colors.one_bg2, fg = colors.green, bold = true },
		MarkviewHeading5 = { bg = colors.one_bg2, fg = colors.blue, bold = true },
		MarkviewHeading6 = { bg = colors.one_bg2, fg = colors.purple, bold = true },

		MarkviewHeading1Sign = { fg = colors.red },
		MarkviewHeading2Sign = { fg = colors.orange },
		MarkviewHeading3Sign = { fg = colors.yellow },
		MarkviewHeading4Sign = { fg = colors.green },
		MarkviewHeading5Sign = { fg = colors.blue },
		MarkviewHeading6Sign = { fg = colors.purple },

		-- Code blocks
		MarkviewCode = { bg = code_bg },
		MarkviewCodeInfo = { fg = colors.grey_fg, bg = colors.one_bg },
		MarkviewCodeFg = { fg = colors.cyan },
		MarkviewInlineCode = { bg = code_bg, fg = colors.cyan },

		-- Block quotes
		MarkviewBlockQuoteDefault = { fg = colors.grey_fg },
		MarkviewBlockQuoteNote = { fg = colors.blue },
		MarkviewBlockQuoteTip = { fg = colors.green },
		MarkviewBlockQuoteImportant = { fg = colors.purple },
		MarkviewBlockQuoteWarning = { fg = colors.yellow },
		MarkviewBlockQuoteCaution = { fg = colors.red },
		MarkviewBlockQuoteError = { fg = colors.red },

		-- Lists
		MarkviewListItemMinus = { fg = colors.red },
		MarkviewListItemPlus = { fg = colors.green },
		MarkviewListItemStar = { fg = colors.yellow },

		-- Checkboxes
		MarkviewCheckboxChecked = { fg = colors.green },
		MarkviewCheckboxUnchecked = { fg = colors.grey_fg },
		MarkviewCheckboxPending = { fg = colors.yellow },

		-- Tables
		MarkviewTableHeader = { fg = colors.blue, bold = true },
		MarkviewTableBorder = { fg = colors.grey },

		-- Links
		MarkviewHyperlink = { fg = colors.blue, underline = true },
		MarkviewImage = { fg = colors.purple, underline = true },
		MarkviewEmail = { fg = colors.cyan, underline = true },

		-- Gradient
		MarkviewGradient0 = { fg = colors.grey },
		MarkviewGradient1 = { fg = colors.grey_fg },
		MarkviewGradient2 = { fg = colors.grey_fg2 },
		MarkviewGradient3 = { fg = colors.light_grey },
		MarkviewGradient4 = { fg = colors.white },
	}

	for group, opts in pairs(highlights) do
		vim.api.nvim_set_hl(0, group, opts)
	end
end
