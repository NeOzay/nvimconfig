---@diagnostic disable:missing-fields
---@type LazyPluginSpec
return {
	"saghen/blink.cmp",
	event = "InsertEnter",
	version = "*",
	dependencies = {
		"L3MON4D3/LuaSnip",
		"rafamadriz/friendly-snippets",
		"fang2hou/blink-copilot",
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
				function(cmp)
					if vim.b[vim.api.nvim_get_current_buf()].nes_state then
						return (
							require("copilot-lsp.nes").apply_pending_nes()
							and require("copilot-lsp.nes").walk_cursor_end_edit()
						)
					end
				end,
				"fallback",
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
			default = { "lsp", "copilot", "snippets", "path", "path_cwd", "buffer" },
			per_filetype = {
				AvanteInput = { "avante_commands", "avante_mentions", "avante_files", "avante_shortcuts" },
				codecompanion = { "codecompanion" },
			},
			---@type table<string, blink.cmp.SourceProviderConfig>
			providers = {
				copilot = {
					name = "copilot",
					module = "blink-copilot",
					score_offset = -3,
					async = true,
					timeout_ms = 2000,
					opts = {
						kind_hl = "BlinkCmpKindCopilot",
					},
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
