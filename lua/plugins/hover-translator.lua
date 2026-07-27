---@type LazyPluginSpec
return {
	dir = vim.fn.stdpath("config") .. "/plugins/hover-translator",
	lazy = false,
	---@type Partial<hover-translator.config>
	opts = {
		target_lang = "fr",
	},
	keys = {
		{
			"<leader>K",
			function()
				require("hover-translator").hover_translate()
			end,
			desc = "Hover Translator",
		},
	},
}
