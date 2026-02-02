local function gen_keymaps()
	local keys = {
		{
			"<leader>a",
			function()
				require("harpoon"):list():add()
			end,
			mode = "n",
			desc = "Harpoon: ajouter",
		},
		{
			"<C-e>",
			function()
				require("pickers.harpoon")()
			end,
			mode = "n",
			desc = "Harpoon: Telescope",
		},
		{
			"<leader>hm",
			function()
				require("harpoon").ui:toggle_quick_menu(require("harpoon"):list())
			end,
			mode = "n",
			desc = "Harpoon: menu natif",
		},
		{
			"<C-S-N>",
			function()
				require("harpoon"):list():next()
			end,
			mode = "n",
			desc = "Harpoon: fichier suivant",
		},
		{
			"<C-S-P>",
			function()
				require("harpoon"):list():prev()
			end,
			mode = "n",
			desc = "Harpoon: fichier précédent",
		},
	}
	local slot_keys = { "<C-h>", "<C-t>", "<C-n>", "<C-s>" }
	for i, key in ipairs(slot_keys) do
		table.insert(keys, {
			key,
			function()
				require("harpoon"):list():select(i)
			end,
			mode = "n",
		})
	end
	return keys
end

---@type LazySpec
return {
	"NeOzay/harpoon",
	branch = "harpoon2",
	dev = true,
	lazy = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
	},
	config = function()
		local harpoon = require("harpoon")
		harpoon:setup({
			settings = {
				save_on_toggle = true,
				sync_on_ui_close = true,
			},
		} --[[@as HarpoonPartialConfig ]])
	end,
	keys = gen_keymaps(),
}
