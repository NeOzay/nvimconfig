---@diagnostic disable:missing-fields
---@type LazyPluginSpec
return {
	"saghen/blink.cmp",
	event = "InsertEnter",
	version = "*",
	dependencies = {
		"L3MON4D3/LuaSnip",
		"rafamadriz/friendly-snippets",
		"giuxtaposition/blink-cmp-copilot",
		-- { "saghen/blink.compat", opts = {} },
	},

	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		keymap = {
			preset = "default",
			["<Up>"] = { "select_prev", "fallback" },
			["<Down>"] = { "select_next", "fallback" },
			["<S-Tab>"] = { "select_prev", "fallback" },
			["<Tab>"] = { "select_next", "fallback" },
			["<CR>"] = { "accept", "fallback" },
			["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
			["<C-e>"] = { "hide", "fallback" },
		},

		snippets = {
			preset = "luasnip",
		},

		---@type blink.cmp.SourceConfigPartial
		sources = {
			min_keyword_length = function(a)
				return vim.bo.filetype == "markdown" and 2 or 0
			end,
			default = { "lsp", "copilot", "snippets", "path", "buffer" },
			per_filetype = {
				AvanteInput = { "avante_commands", "avante_mentions", "avante_files", "avante_shortcuts" },
				codecompanion = { "codecompanion" },
			},
			---@type table<string, blink.cmp.SourceProviderConfig>
			providers = {
				copilot = {
					name = "copilot",
					module = "blink-cmp-copilot",
					score_offset = -3,
					async = true,
					timeout_ms = 2000,
				},
				buffer = {
					max_items = 5,
					min_keyword_length = 3,
				},
				lsp = {
					timeout_ms = 2000,
				},
				-- avante_commands = {
				-- 	name = "avante_commands",
				-- 	module = "blink.compat.source",
				-- 	score_offset = 90,
				-- 	opts = {},
				-- },
				-- avante_files = {
				-- 	name = "avante_files",
				-- 	module = "blink.compat.source",
				-- 	score_offset = 100,
				-- 	opts = {},
				-- },
				-- avante_mentions = {
				-- 	name = "avante_mentions",
				-- 	module = "blink.compat.source",
				-- 	score_offset = 1000,
				-- 	opts = {},
				-- },
				-- avante_shortcuts = {
				-- 	name = "avante_shortcuts",
				-- 	module = "blink.compat.source",
				-- 	score_offset = 1000,
				-- 	opts = {},
				-- },
			},
		},
		---@type blink.cmp.CompletionConfig
		completion = {
			keyword = { range = "full" },
			accept = {
				auto_brackets = {
					enabled = true,
				},
			},
			menu = {
				draw = {
					columns = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "kind" } },
				},
			},
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 200,
				window = {
					border = "rounded",
				},
			},
			-- Désactivé pour éviter le lag avec copilot
			ghost_text = {
				enabled = false,
			},
		},

		appearance = {
			use_nvim_cmp_as_default = false,
			nerd_font_variant = "mono",
			kind_icons = {
				Text = "󰉿",
				Method = "󰊕",
				Function = "󰊕",
				Constructor = "󰒓",
				Field = "󰜢",
				Variable = "󰆦",
				Property = "󰖷",
				Class = "󱡠",
				Interface = "󱡠",
				Struct = "󱡠",
				Module = "󰅩",
				Unit = "󰪚",
				Value = "󰦨",
				Enum = "󰦨",
				EnumMember = "󰦨",
				Keyword = "󰻾",
				Constant = "󰏿",
				Snippet = "󱄽",
				Color = "󰏘",
				File = "󰈔",
				Reference = "󰬲",
				Folder = "󰉋",
				Event = "󱐋",
				Operator = "󰪚",
				TypeParameter = "󰬛",
				Copilot = "",
			},
		},
		---@type blink.cmp.CmdlineConfigPartial
		cmdline = {
			completion = {
				menu = {
					auto_show = true,
				},
			},
		},
		signature = {
			enabled = false,
			window = {
				border = "rounded",
			},
		},
	},

	config = function(_, opts)
		require("blink.cmp").setup(opts)
	end,
}
