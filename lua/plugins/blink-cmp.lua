---@diagnostic disable:missing-fields
---@type LazyPluginSpec
return {
	"saghen/blink.cmp",
	event = "InsertEnter",
	version = "*",
	dependencies = {
		"L3MON4D3/LuaSnip",
		"rafamadriz/friendly-snippets",
		"milanglacier/minuet-ai.nvim",
	},

	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		keymap = {
			preset = "super-tab",
			["<Up>"] = { "select_prev", "fallback" },
			["<Down>"] = { "select_next", "fallback" },
			["<S-Tab>"] = { "select_prev", "fallback" },
			["<Tab>"] = {
				function(cmp)
					if cmp.snippet_active() then
						return cmp.accept()
					else
						return cmp.select_next()
					end
				end,
				"snippet_forward",
				"fallback",
			},
			-- Déclenchement manuel de la complétion IA (minuet / DeepSeek)
			["<A-y>"] = {
				-- équivalent de `require("minuet").make_blink_map()`, sans charger
				-- minuet au démarrage
				function(cmp)
					cmp.show({ providers = { "minuet" } })
				end,
			},
			["<CR>"] = { "accept", "fallback" },
			["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
			["<C-e>"] = { "hide", "fallback" },
			-- ["<esc>"] = { "hide", "fallback" },
		},

		snippets = {
			preset = "luasnip",
		},

		---@type blink.cmp.SourceConfigPartial
		sources = {
			min_keyword_length = function(a)
				return vim.bo.filetype == "markdown" and 2 or 0
			end,
			-- minuet n'est PAS ici : il s'affiche en ghost text (virtualtext).
			-- Il reste invocable manuellement dans le menu via <A-y>.
			default = { "lsp", "snippets", "path", "path_cwd", "buffer" },
			per_filetype = {
				AvanteInput = { "avante_commands", "avante_mentions", "avante_files", "avante_shortcuts" },
				codecompanion = { "codecompanion" },
			},
			---@type table<string, blink.cmp.SourceProviderConfig>
			providers = {
				minuet = {
					name = "minuet",
					module = "minuet.blink",
					score_offset = 50,
					async = true,
					-- minuet gère son propre timeout (request_timeout) ; blink doit
					-- laisser assez de marge pour la réponse du LLM.
					timeout_ms = 3000,
				},
				buffer = {
					max_items = 5,
					min_keyword_length = 3,
				},
				lsp = {
					timeout_ms = 2000,
				},
				path_cwd = {
					name = "Path (cwd)",
					module = "blink.cmp.sources.path",
					opts = {
						get_cwd = function(_ctx)
							return vim.uv.cwd()
						end,
					},
				},
			},
		},
		---@type blink.cmp.CompletionConfig
		completion = {
			keyword = { range = "full" },
			-- Recommandé par minuet : évite de préfetcher la source LLM à l'entrée en insertion.
			trigger = { prefetch_on_insert = false },
			accept = {
				auto_brackets = {
					enabled = true,
				},
			},
			list = {
				selection = {
					preselect = false,
					auto_insert = true,
				},
			},
			menu = {
				auto_show = true,
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
			-- nerd_font_variant = "mono",
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
				list = {
					selection = {
						preselect = false,
						auto_insert = true,
					},
				},
				menu = {
					auto_show = true,
				},
			},
		},
		---@type blink.cmp.SignatureConfig
		signature = {
			enabled = true,
			window = {
				treesitter_highlighting = true,
				border = "rounded",
				show_documentation = true,
			},
		},
	},

	config = function(_, opts)
		require("blink.cmp").setup(opts)
	end,
}
