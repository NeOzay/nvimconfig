local function prefix(ctx)
	local icon, icon_hl = ctx.icon, ctx.icon_hl
	local segments = {
		{ text = ctx.indent, hl = ctx.indent_hl },
	}

	segments[#segments + 1] = {
		text = icon .. " ",
		hl = icon_hl,
	}
	return segments
end

---@type LazyPluginSpec
return {
	"esmuellert/codediff.nvim",
	cmd = "CodeDiff",
	-- dir = vim.fn.stdpath("config") .. "/plugins/codediff.nvim",
	keys = {
		{
			"<leader>gd",
			function()
				vim.cmd("CodeDiff")
			end,
			desc = "Open CodeDiff",
		},
		{
			"<leader>gh",
			function()
				vim.cmd("CodeDiff history HEAD~50 %")
			end,
			desc = "File History (current)",
		},
		{
			"<leader>gH",
			function()
				vim.cmd("CodeDiff history")
			end,
			desc = "File History (all)",
		},
	},
	opts = {
		disable_inlay_hints = true,
		cycle_next_hunk = true,
		original_position = "left",
		explorer = {
			position = "left",
			width = 30,
			view_mode = "tree",
			initial_focus = "explorer",
			auto_open_on_cursor = true,
			formatters = { -- Optional function(ctx) -> line layout callbacks; omit to use the built-ins
				file = function(ctx)
					return {
						left = {
							{ segments = prefix(ctx) },
							{
								segments = { { text = ctx.filename, hl = "Normal" } },
								truncate_priority = 1,
							},
						},
						right = {
							{
								segments = {
									{
										text = ctx.status,
										hl = ctx.status_hl,
									},
									{ text = " ", hl = "Normal" },
								},
							},
						},
						min_gap = 1,
					}
				end, -- File rows
				folder = function(ctx)
					return {
						left = {
							{ segments = prefix(ctx) },
							{
								segments = {
									{
										text = ctx.name,
										hl = "Directory",
									},
								},
								truncate_priority = 1,
							},
						},
						right = {
							{
								segments = {
									{ text = ctx.file_count, hl = "Comment" },
									{ text = " ", hl = "Normal" },
								},
							},
						},
					}
				end,
				group = function(ctx)
					return {
						left = {
							{
								segments = { { text = ctx.label, hl = "CodeDiffExplorerTreeGroup" } },
								truncate_priority = 1,
							},
						},
						right = {
							{
								segments = {
									{ text = "(", hl = "Comment" },
									{ text = ctx.file_count, hl = "Number" },
									{ text = ")", hl = "Comment" },
								},
							},
						},
					}
				end,
			},
		},
		history = {
			position = "bottom",
			height = 16,
		},
		diff = {
			layout = "inline",
			compact_context_lines = 20, -- Number of context lines around hunks in compact mode
			compact_sync_folds = true, -- Sync fold open/close across panes (mirrors Vim diff mode behavior)
			-- compact = true, -- Open diffs in compact mode by default (fold unchanged regions; toggle with gc)

			compute_moves = true,
		},

		keymaps = {
			view = {
				close = "q",
				-- `<leader>e` est posé par plugins.codediff.explorer, seul toggle
				toggle_explorer = false,
				focus_explorer = false,
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
	config = function(_, opts)
		require("codediff").setup(opts)
		require("plugins.codediff.explorer").setup()
	end,
}
