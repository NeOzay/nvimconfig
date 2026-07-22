-- ClaudeCode highlights for Sonokai theme

local colors = require("base46").get_theme_tb("base_30") ---@as Base30Table

return {
	-- Unified inline diff (diff_opts.layout = "unified")
	ClaudeCodeInlineDiffAdd = { bg = "CodeDiffLineInsert" },
	ClaudeCodeInlineDiffDelete = { bg = "CodeDiffLineDelete", strikethrough = true },
	ClaudeCodeInlineDiffAddSign = { fg = colors.green },
	ClaudeCodeInlineDiffDeleteSign = { fg = colors.red },
}
