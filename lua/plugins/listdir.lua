---@diagnostic disable: param-type-mismatch, missing-fields
---@type LazySpec
return {
	dir = vim.fn.stdpath("config") .. "/plugins/listdir",
	config = function()
		require("listdir").setup({
			depth = 10,
			pickers = {
				items = {
					layout = {
						preset = "ivy_2",
					},
				},
			},
		})
	end,
	cmd = { "ListDir" },
	keys = {
		{ "<leader>fl", "<cmd>ListDir<CR>", mode = "n", desc = "listdir: répertoires-listes" },
	},
}
