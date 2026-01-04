return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    opts = {
      ensure_installed = {
        -- LSP
        "basedpyright",
        "html-lsp",
        "css-lsp",

        -- Formatters
        "stylua",
        "ruff",

        -- Linters (optionnel, ruff fait aussi du linting)
      },
    },
  },

  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = require "configs.trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
    {
      'nvim-treesitter/nvim-treesitter',
      branch = "main",
      lazy = false,
      build = ':TSUpdate',
      opts = function() end,
      config = function()
        require("nvim-treesitter").setup()
      end,
    }
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
