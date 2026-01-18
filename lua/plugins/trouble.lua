local function config(_, opts)
	dofile(vim.g.base46_cache .. "trouble")
	require("trouble").setup(opts)
end

---@type LazySpec
return {
	"folke/trouble.nvim",
	cmd = "Trouble",
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
	opts = {
		modes = {
			diagnostics = {
				mode = "diagnostics",
				preview = {
					type = "split",
					relative = "win",
					position = "right",
					size = 0.4,
				},
			},
		},
		icons = {
			indent = {
				top = "│ ",
				middle = "├╴",
				last = "└╴",
				fold_open = " ",
				fold_closed = " ",
				ws = "  ",
			},
			folder_closed = " ",
			folder_open = " ",
			kinds = {
				Array = " ",
				Boolean = "󰨙 ",
				Class = " ",
				Constant = "󰏿 ",
				Constructor = " ",
				Enum = " ",
				EnumMember = " ",
				Event = " ",
				Field = " ",
				File = " ",
				Function = "󰊕 ",
				Interface = " ",
				Key = " ",
				Method = "󰊕 ",
				Module = " ",
				Namespace = "󰦮 ",
				Null = " ",
				Number = "󰎠 ",
				Object = " ",
				Operator = " ",
				Package = " ",
				Property = " ",
				String = " ",
				Struct = "󰆼 ",
				TypeParameter = " ",
				Variable = "󰀫 ",
			},
		},
		auto_close = false,
		auto_open = false,
		auto_preview = true,
		auto_refresh = true,
		auto_jump = false,
		focus = true,
		restore = true,
		follow = true,
		indent_guides = true,
		max_items = 200,
		multiline = true,
		pinned = false,
		win = {
			position = "bottom",
			size = {
				height = 10,
			},
		},
		preview = {
			type = "main",
			scratch = true,
		},
		filter = {
			["not"] = {
				severity = vim.diagnostic.severity.HINT,
			},
		},
	},
	config = config,
}
