local function opts()
	local mix = require("base46.colors").mix_colors_group
	local attr = require("base46.colors").get_hi_attr
	local colors = require("base46").get_palette()
	---@type docstring-highlight.config
	return {
		hl = {
			DocstringSection = { bold = true, fg = mix(colors.purple, "@comment", 0) },
			DocstringParam = { bold = true, fg = mix("@variable.parameter", "@comment", 0) },
			DocstringCodeBlock = { fg = attr("Comment", "fg"), bg = colors.one_bg2 },
		},
		-- codeblock_blend = 50,
		bg = colors.code_bg,
	}
end

return {
	dir = "~/projects/nvim-plugins/docstring-highlight.nvim",
	ft = "python",
	opts = opts,
}
