local function opts(_opts)
	_opts.extensions = {
		aerial = {
			-- Set the width of the first two columns (the second
			-- is relevant only when show_columns is set to 'both')
			col1_width = 4,
			col2_width = 30,
			-- How to format the symbols
			format_symbol = function(symbol_path, filetype)
				if filetype == "json" or filetype == "yaml" then
					return table.concat(symbol_path, ".")
				else
					return symbol_path[#symbol_path]
				end
			end,
			-- Available modes: symbols, lines, both
			show_columns = "both",
		},
	}
end

---@type LazySpec
return {
	"nvim-telescope/telescope.nvim",
	opts = opts,
	keys = {
		{ "<leader>fw", "<cmd>Telescope live_grep<CR>", desc = "telescope live grep" },
		{ "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "telescope find buffers" },
		{ "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "telescope help page" },
		{ "<leader>ma", "<cmd>Telescope marks<CR>", desc = "telescope find marks" },
		{ "<leader>fo", "<cmd>Telescope oldfiles<CR>", desc = "telescope find oldfiles" },
		{ "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "telescope find in current buffer" },
		{ "<leader>cm", "<cmd>Telescope git_commits<CR>", desc = "telescope git commits" },
		{ "<leader>gt", "<cmd>Telescope git_status<CR>", desc = "telescope git status" },
		{ "<leader>pt", "<cmd>Telescope terms<CR>", desc = "telescope pick hidden term" },
		{
			"<leader>th",
			function()
				require("nvchad.themes").open()
			end,
			desc = "telescope nvchad themes",
		},
		{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "telescope find files" },
		{
			"<leader>fa",
			"<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
			desc = "telescope find all files",
		},
		{ "<F3>", "<cmd>Telescope find_files<cr>", desc = "telescope find files" },
		{
			"<leader>fj",
			function()
				require("pickers").jumplist()
			end,
			desc = "Telescope jumplist",
		},
	},
	config = function(_, _opts)
		local telescope = require("telescope")
		telescope.setup(_opts)
		telescope.load_extension("aerial")
	end,
}
