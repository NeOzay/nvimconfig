local function action(name, ...)
	local args = { ... }
	return function()
		require("diffview.actions")[name](unpack(args))
	end
end

local view_keymaps = {
	{ "n", "<tab>", action("select_next_entry"), { desc = "Open the diff for the next file" } },
	{ "n", "<s-tab>", action("select_prev_entry"), { desc = "Open the diff for the previous file" } },
	{ "n", "gf", action("goto_file_edit"), { desc = "Open the file in the previous tabpage" } },
	{ "n", "<leader>e", action("focus_files"), { desc = "Bring focus to the file panel" } },
	{ "n", "<leader>b", action("toggle_files"), { desc = "Toggle the file panel" } },
	{ "n", "g<C-x>", action("cycle_layout"), { desc = "Cycle through available layouts" } },
	{ "n", "<leader>co", action("conflict_choose", "ours"), { desc = "Choose OURS version of a conflict" } },
	{ "n", "<leader>ct", action("conflict_choose", "theirs"), { desc = "Choose THEIRS version of a conflict" } },
	{ "n", "<leader>cb", action("conflict_choose", "base"), { desc = "Choose BASE version of a conflict" } },
	{ "n", "<leader>ca", action("conflict_choose", "all"), { desc = "Choose all versions of a conflict" } },
	{ "n", "dx", action("conflict_choose", "none"), { desc = "Delete the conflict region" } },
	{ "n", "<leader>cO", action("conflict_choose_all", "ours"), { desc = "Choose OURS for all conflicts" } },
	{ "n", "<leader>cT", action("conflict_choose_all", "theirs"), { desc = "Choose THEIRS for all conflicts" } },
	{ "n", "<leader>cB", action("conflict_choose_all", "base"), { desc = "Choose BASE for all conflicts" } },
	{ "n", "<leader>cA", action("conflict_choose_all", "all"), { desc = "Choose all for all conflicts" } },
	{ "n", "dX", action("conflict_choose_all", "none"), { desc = "Delete all conflict regions" } },
}

local diff3_keymaps = {
	{ { "n", "x" }, "2do", action("diffget", "ours"), { desc = "Obtain the diff hunk from OURS" } },
	{ { "n", "x" }, "3do", action("diffget", "theirs"), { desc = "Obtain the diff hunk from THEIRS" } },
}

local diff4_keymaps = {
	{ { "n", "x" }, "1do", action("diffget", "base"), { desc = "Obtain the diff hunk from BASE" } },
	{ { "n", "x" }, "2do", action("diffget", "ours"), { desc = "Obtain the diff hunk from OURS" } },
	{ { "n", "x" }, "3do", action("diffget", "theirs"), { desc = "Obtain the diff hunk from THEIRS" } },
}

local file_panel_keymaps = {
	{ "n", "j", action("next_entry"), { desc = "Bring the cursor to the next file entry" } },
	{ "n", "<down>", action("next_entry"), { desc = "Bring the cursor to the next file entry" } },
	{ "n", "k", action("prev_entry"), { desc = "Bring the cursor to the previous file entry" } },
	{ "n", "<up>", action("prev_entry"), { desc = "Bring the cursor to the previous file entry" } },
	{ "n", "<cr>", action("select_entry"), { desc = "Open the diff for the selected entry" } },
	{ "n", "o", action("select_entry"), { desc = "Open the diff for the selected entry" } },
	{ "n", "l", action("select_entry"), { desc = "Open the diff for the selected entry" } },
	{ "n", "<2-LeftMouse>", action("select_entry"), { desc = "Open the diff for the selected entry" } },
	{ "n", "-", action("toggle_stage_entry"), { desc = "Stage/unstage the selected entry" } },
	{ "n", "s", action("toggle_stage_entry"), { desc = "Stage/unstage the selected entry" } },
	{ "n", "S", action("stage_all"), { desc = "Stage all entries" } },
	{ "n", "U", action("unstage_all"), { desc = "Unstage all entries" } },
	{ "n", "X", action("restore_entry"), { desc = "Restore entry to the state on the left side" } },
	{ "n", "L", action("open_commit_log"), { desc = "Open the commit log panel" } },
	{ "n", "zo", action("open_fold"), { desc = "Expand fold" } },
	{ "n", "h", action("close_fold"), { desc = "Collapse fold" } },
	{ "n", "zc", action("close_fold"), { desc = "Collapse fold" } },
	{ "n", "za", action("toggle_fold"), { desc = "Toggle fold" } },
	{ "n", "zR", action("open_all_folds"), { desc = "Expand all folds" } },
	{ "n", "zM", action("close_all_folds"), { desc = "Collapse all folds" } },
	{ "n", "<c-b>", action("scroll_view", -0.25), { desc = "Scroll the view up" } },
	{ "n", "<c-f>", action("scroll_view", 0.25), { desc = "Scroll the view down" } },
	{ "n", "<tab>", action("select_next_entry"), { desc = "Open the diff for the next file" } },
	{ "n", "<s-tab>", action("select_prev_entry"), { desc = "Open the diff for the previous file" } },
	{ "n", "gf", action("goto_file_edit"), { desc = "Open the file" } },
	{ "n", "<leader>e", action("focus_files"), { desc = "Bring focus to the file panel" } },
	{ "n", "<leader>b", action("toggle_files"), { desc = "Toggle the file panel" } },
	{ "n", "g<C-x>", action("cycle_layout"), { desc = "Cycle layouts" } },
	{ "n", "[x", action("prev_conflict"), { desc = "Go to the previous conflict" } },
	{ "n", "]x", action("next_conflict"), { desc = "Go to the next conflict" } },
	{ "n", "?", action("help", "file_panel"), { desc = "Open the help panel" } },
	{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
}

local file_history_panel_keymaps = {
	{ "n", "g!", action("options"), { desc = "Open the option panel" } },
	{ "n", "<C-A-d>", action("open_in_diffview"), { desc = "Open entry in diffview" } },
	{ "n", "y", action("copy_hash"), { desc = "Copy commit hash" } },
	{ "n", "L", action("open_commit_log"), { desc = "Show commit details" } },
	{ "n", "zR", action("open_all_folds"), { desc = "Expand all folds" } },
	{ "n", "zM", action("close_all_folds"), { desc = "Collapse all folds" } },
	{ "n", "j", action("next_entry"), { desc = "Next entry" } },
	{ "n", "<down>", action("next_entry"), { desc = "Next entry" } },
	{ "n", "k", action("prev_entry"), { desc = "Previous entry" } },
	{ "n", "<up>", action("prev_entry"), { desc = "Previous entry" } },
	{ "n", "<cr>", action("select_entry"), { desc = "Select entry" } },
	{ "n", "o", action("select_entry"), { desc = "Select entry" } },
	{ "n", "l", action("select_entry"), { desc = "Select entry" } },
	{ "n", "<tab>", action("select_next_entry"), { desc = "Next file" } },
	{ "n", "<s-tab>", action("select_prev_entry"), { desc = "Previous file" } },
	{ "n", "gf", action("goto_file_edit"), { desc = "Open file" } },
	{ "n", "<leader>e", action("focus_files"), { desc = "Focus file panel" } },
	{ "n", "<leader>b", action("toggle_files"), { desc = "Toggle file panel" } },
	{ "n", "?", action("help", "file_history_panel"), { desc = "Open help" } },
	{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
}

local option_panel_keymaps = {
	{ "n", "<tab>", action("select_entry"), { desc = "Change option" } },
	{ "n", "q", action("close"), { desc = "Close panel" } },
	{ "n", "?", action("help", "option_panel"), { desc = "Open help" } },
}

local help_panel_keymaps = {
	{ "n", "q", action("close"), { desc = "Close help" } },
}

---@type LazySpec
return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewFileHistory" },
	keys = {
		{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview" },
		{ "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
		{ "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History (current)" },
		{ "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "File History (all)" },
	},
	opts = {
		diff_binaries = false,
		enhanced_diff_hl = true,
		git_cmd = { "git" },
		hg_cmd = { "hg" },
		use_icons = true,
		show_help_hints = true,
		watch_index = true,
		icons = {
			folder_closed = "",
			folder_open = "",
		},
		signs = {
			fold_closed = "",
			fold_open = "",
			done = "✓",
		},
		view = {
			default = {
				layout = "diff2_horizontal",
				disable_diagnostics = false,
				winbar_info = false,
			},
			merge_tool = {
				layout = "diff3_horizontal",
				disable_diagnostics = true,
				winbar_info = true,
			},
			file_history = {
				layout = "diff2_horizontal",
				disable_diagnostics = false,
				winbar_info = false,
			},
		},
		file_panel = {
			listing_style = "tree",
			tree_options = {
				flatten_dirs = true,
				folder_statuses = "only_folded",
			},
			win_config = {
				position = "left",
				width = 35,
				win_opts = {},
			},
		},
		file_history_panel = {
			log_options = {
				git = {
					single_file = {
						diff_merges = "combined",
					},
					multi_file = {
						diff_merges = "first-parent",
					},
				},
			},
			win_config = {
				position = "bottom",
				height = 16,
				win_opts = {},
			},
		},
		commit_log_panel = {
			win_config = {
				win_opts = {},
			},
		},
		default_args = {
			DiffviewOpen = {},
			DiffviewFileHistory = {},
		},
		hooks = {},
		keymaps = {
			disable_defaults = false,
			view = view_keymaps,
			diff1 = {},
			diff2 = {},
			diff3 = diff3_keymaps,
			diff4 = diff4_keymaps,
			file_panel = file_panel_keymaps,
			file_history_panel = file_history_panel_keymaps,
			option_panel = option_panel_keymaps,
			help_panel = help_panel_keymaps,
		},
	},
}
