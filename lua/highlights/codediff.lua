-- CodeDiff highlights for Sonokai theme

return function()
	local colors = require("base46").get_theme_tb("base_30") ---@as Base30Table
	local tool = require("base46.colors")

	local highlights = {
		-- Diff: line-level
		CodeDiffLineInsert = { bg = tool.mix(colors.green, colors.black, 90) },
		CodeDiffLineDelete = { bg = tool.mix(colors.red, colors.black, 90) },

		-- Diff: character-level (brighter)
		CodeDiffCharInsert = { bg = tool.mix(colors.green, colors.black, 80) },
		CodeDiffCharDelete = { bg = tool.mix(colors.red, colors.black, 80) },

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

	for group, opts in pairs(highlights) do
		vim.api.nvim_set_hl(0, group, opts)
	end
end
