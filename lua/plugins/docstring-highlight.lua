local function opts()
	local mix = require("colors_bank").mix_colors_group
	local attr = require("colors_bank").get_hi_attr
	local colors = require("base46").get_theme_tb("base_30") ---@as Base30Table
	local code_bg = require("colors_bank").bank.code_bg
	---@type docstring-highlight.config
	return {
		hl = {
			DocstringSection = { bold = true, fg = mix(colors.purple, "@comment", 45) },
			DocstringParam = { bold = true, fg = mix("@variable.parameter", "@comment", 45) },
			DocstringCodeBlock = { fg = attr("Comment", "fg"), bg = colors.one_bg2 },
		},
		-- codeblock_blend = 50,
		bg = code_bg,
	}
end

return {
	dir = "~/projects/nvim-plugins/docstring-highlight.nvim",
	ft = "python",
	opts = opts,
}
