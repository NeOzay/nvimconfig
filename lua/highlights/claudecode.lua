-- ClaudeCode highlights for Sonokai theme

local colors = require("base46").get_theme_tb("base_30") ---@as Base30Table

---@type Base46HLTable
return {
	-- Unified inline diff (diff_opts.layout = "unified")
	ClaudeCodeInlineDiffAdd = { bg = "DiffAdd" },
	ClaudeCodeInlineDiffDelete = { bg = "DiffRemoved" },
	ClaudeCodeInlineDiffAddSign = { fg = colors.green },
	ClaudeCodeInlineDiffDeleteSign = { fg = colors.red },
}
