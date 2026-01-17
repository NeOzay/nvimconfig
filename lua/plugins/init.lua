---@type LazySpec[]
return {
	{
		"stevearc/conform.nvim",
		event = "BufWritePre", -- uncomment for format on save
		opts = require("configs.conform"),
	},

	-- These are some examples, uncomment them if you want to see them work!
	{
		"neovim/nvim-lspconfig",
		config = function()
			require("configs.lspconfig")
		end,
	},
	{
		"j-hui/fidget.nvim",
		lazy = false,
		opts = {
			-- options
		},
	},
	{ "b0o/schemastore.nvim" },

	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		opts = require("configs.trouble").opts,
		config = require("configs.trouble").setup,
		keys = require("configs.trouble").keys,
	},
	{
		"lewis6991/gitsigns.nvim",
		event = "User FilePost",
		opts = require("configs.gitsigns"),
	},
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewFileHistory" },
		opts = require("configs.diffview"),
		keys = {
			{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview" },
			{ "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
			{ "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History (current)" },
			{ "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "File History (all)" },
		},
	},
	{
		"NeogitOrg/neogit",
		lazy = true,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
			"nvim-telescope/telescope.nvim",
		},
		cmd = "Neogit",
		opts = require("configs.neogit"),
		keys = {
			{ "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit Status" },
			{ "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Neogit Commit" },
			{ "<leader>gp", "<cmd>Neogit push<cr>", desc = "Neogit Push" },
			{ "<leader>gl", "<cmd>Neogit pull<cr>", desc = "Neogit Pull" },
			{ "<leader>gb", "<cmd>Neogit branch<cr>", desc = "Neogit Branch" },
		},
	},
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		opts = function() end,
		config = function()
			require("nvim-treesitter").setup()
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		event = "BufEnter",
		branch = "main",
		init = require("configs.ts-textojects").init,
		opts = require("configs.ts-textojects").opts,
		keys = require("configs.ts-textojects").keys,
	},
	{
		"nvim-tree/nvim-tree.lua",
		-- cmd = { "NvimTreeToggle", "NvimTreeFocus" },
		lazy = true,
		enabled = false,
		opts = function()
			return require("configs.nvim-tree")
		end,
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons", -- optional, but recommended
		},
		lazy = false, -- neo-tree will lazily load itself
		opts = require("configs.neo-tree"),
	},
	{
		"hrsh7th/nvim-cmp",
		opts = require("configs.nvim-cmp").opts,
	},

	-- GitHub Copilot
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup()
			local cmp = require("cmp")
			cmp.event:on("menu_opened", function()
				vim.b.copilot_suggestion_hidden = true
			end)

			cmp.event:on("menu_closed", function()
				vim.b.copilot_suggestion_hidden = false
			end)
		end,
	},
	{
		"zbirenbaum/copilot-cmp",
		dependencies = { "zbirenbaum/copilot.lua" },
		event = "InsertEnter",
		config = function()
			require("copilot_cmp").setup()
		end,
	},

	-- vim-illuminate: highlight other uses of the word under cursor
	{
		"RRethy/vim-illuminate",
		event = { "BufReadPost", "BufNewFile" },
		opts = require("configs.illuminate"),
		config = function(_, opts)
			require("illuminate").configure(opts)
		end,
		keys = {
			{
				"]]",
				function()
					require("illuminate").goto_next_reference(false)
				end,
				desc = "Next Reference",
			},
			{
				"[[",
				function()
					require("illuminate").goto_prev_reference(false)
				end,
				desc = "Prev Reference",
			},
		},
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		event = "User FilePost",
		opts = require("configs.indent-blankline").opts,
		config = require("configs.indent-blankline").config,
	},

	-- test new blink
	-- { import = "nvchad.blink.lazyspec" },

	-- {
	-- 	"nvim-treesitter/nvim-treesitter",
	-- 	opts = {
	-- 		ensure_installed = {
	-- 			"vim", "lua", "vimdoc",
	--      "html", "css"
	-- 		},
	-- 	},
	-- },
}
