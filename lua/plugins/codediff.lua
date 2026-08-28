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
				vim.cmd("CodeDiff" .. (vim.o.columns < 100 and " --inline" or ""))
			end,
			desc = "Open CodeDiff",
		},
		{
			"<leader>gh",
			function()
				vim.cmd("CodeDiff" .. (vim.o.columns < 100 and " --inline" or "") .. " history HEAD~50 %")
			end,
			desc = "File History (current)",
		},
		{
			"<leader>gH",
			function()
				vim.cmd("CodeDiff" .. (vim.o.columns < 100 and " --inline" or "") .. " history")
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
			focus_on_select = true,
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
			compact_context_lines = 20, -- Number of context lines around hunks in compact mode
			compact_sync_folds = true, -- Sync fold open/close across panes (mirrors Vim diff mode behavior)
			-- compact = true, -- Open diffs in compact mode by default (fold unchanged regions; toggle with gc)

			compute_moves = true,
		},

		keymaps = {
			view = {
				close = "q",
				toggle_explorer = "<leader>E",
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

		-- Ferme automatiquement l'explorer quand un fichier est sélectionné
		-- (pratique sur petit écran/terminal, ex. Neovim sur téléphone).
		Userautocmd("User", {
			pattern = "CodeDiffFileSelect",
			callback = function(args)
				local tabpage = args.data and args.data.tabpage
				if not tabpage then
					return
				end
				vim.defer_fn(function()
					local lifecycle = require("codediff.ui.lifecycle")
					local explorer = lifecycle.get_explorer(tabpage)
					local _, modified_bufnr = lifecycle.get_buffers(tabpage)
					local still_focused = modified_bufnr and modified_bufnr == vim.api.nvim_get_current_buf()
					if explorer and not explorer.is_hidden and still_focused then
						require("codediff.ui.explorer").toggle_visibility(explorer)
					end
				end, 50)
			end,
		})
	end,
}
