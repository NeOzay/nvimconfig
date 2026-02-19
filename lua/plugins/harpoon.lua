local function gen_keymaps()
	local keys = {
		{
			"<C-a>",
			function()
				local harpoon = require("harpoon")
				local list = harpoon:list()
				for index, item in pairs(list.items) do
					if vim.fs.abspath(item.value) == vim.api.nvim_buf_get_name(0) then
						list:remove_at(index)
						return
					end
				end
				list:add()
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
	local utils = require("utils")
	for i, key in pairs(utils.keys_nb_map) do
		table.insert(keys, {
			("<leader>%s"):format(key),
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
