---@type LazySpec
return {
	"saghen/blink.cmp",
	event = "InsertEnter",
	version = "*",
	-- enabled = false, -- Désactivé en attendant une meilleure intégration avec NvChad
	dependencies = {
		"L3MON4D3/LuaSnip",
		"rafamadriz/friendly-snippets",
		"giuxtaposition/blink-cmp-copilot",
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

		sources = {
			default = { "lsp", "copilot", "snippets", "path", "buffer" },
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
			},
		},

		completion = {
			accept = {
				auto_brackets = {
					enabled = true,
				},
			},
			menu = {
				draw = {
					columns = { { "kind_icon" }, { "label", "label_description", gap = 1 } },
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

		signature = {
			enabled = true,
			window = {
				border = "rounded",
			},
		},
	},

	config = function(_, opts)
		-- Tenter de charger le thème blink de NvChad base46 si disponible
		pcall(function()
			dofile(vim.g.base46_cache .. "blink_cmp")
		end)

		require("blink.cmp").setup(opts)
	end,
}
