---@type LazySpec
return {
	"esmuellert/codediff.nvim",
	dependencies = { "MunifTanjim/nui.nvim" },
	cmd = "CodeDiff",
	keys = {
		{ "<leader>gd", "<cmd>CodeDiff<cr>", desc = "Open CodeDiff" },
		{ "<leader>gh", "<cmd>CodeDiff history HEAD~50 %<cr>", desc = "File History (current)" },
		{ "<leader>gH", "<cmd>CodeDiff history<cr>", desc = "File History (all)" },
	},
	opts = {
		disable_inlay_hints = true,
		cycle_next_hunk = true,
		original_position = "left",
		explorer = {
			position = "left",
			width = 35,
			view_mode = "tree",
			initial_focus = "explorer",
		},
		history = {
			position = "bottom",
			height = 16,
		},
		keymaps = {
			view = {
				close = "q",
				toggle_explorer = "<leader>b",
				next_hunk = "]c",
				prev_hunk = "[c",
				next_file = "]f",
				prev_file = "[f",
				diffget = "do",
				diffput = "dp",
				goto_file = "gf",
				stage_toggle = "-",
			},
			explorer = {
				open = "<CR>",
				preview = "K",
				refresh = "R",
				toggle_view = "i",
				stage_all = "S",
				unstage_all = "U",
				discard = "X",
			},
			history = {
				select = "<CR>",
				toggle_view = "i",
			},
			conflict = {
				accept_ours = "<leader>co",
				accept_theirs = "<leader>ct",
				accept_both = "<leader>cb",
				discard_both = "<leader>cx",
				next_conflict = "]x",
				prev_conflict = "[x",
				diffget_incoming = "2do",
				diffget_current = "3do",
			},
		},
	},
}
