---@type LazyPluginSpec
return {
	dir = "~/project/nvim-plugins/hover-translator",
	lazy = false,
	dev = true,
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
