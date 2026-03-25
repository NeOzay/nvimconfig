---@type snacks.Config
local opts = {
	explorer = {
		replace_netrw = true,
	},
	picker = {
		sources = {
			explorer = {
				-- allow any window to be used as the main window
				hidden = false,
				ignored = false,
				auto_close = true,
				jump = { close = true },
				follow_file = true,
				git_status = true,
				diagnostics = true,
				actions = {
					explorer_open_recursive = function(picker, item)
						if not item or not item.dir then
							return
						end
						local Tree = require("snacks.explorer.tree")
						local node = Tree:find(item.file)
						if not node then
							return
						end
						Tree:walk(node, function(n)
							if n.dir then
								n.open = true
							end
						end, { all = true })
						require("snacks.explorer.actions").update(picker, { refresh = true })
					end,
					explorer_close_recursive = function(picker, item)
						if not item then
							return
						end
						local Tree = require("snacks.explorer.tree")
						local dir = Tree:dir(item.file)
						local node = Tree:find(dir)
						if not node then
							return
						end
						Tree:walk(node, function(n)
							n.open = false
						end, { all = true })
						require("snacks.explorer.actions").update(picker, { refresh = true })
					end,
					explorer_open_all = function(picker)
						local Tree = require("snacks.explorer.tree")
						local cwd = picker:cwd()
						local root = Tree:find(cwd)
						if not root then
							return
						end
						Tree:walk(root, function(n)
							if n.dir then
								n.open = true
							end
						end, { all = true })
						require("snacks.explorer.actions").update(picker, { refresh = true })
					end,
					explorer_toggle_recursive = function(picker, item)
						if not item or not item.dir then
							return
						end
						local Tree = require("snacks.explorer.tree")
						local node = Tree:find(item.file)
						if not node then
							return
						end
						local should_open = not node.open
						Tree:walk(node, function(n)
							if n.dir then
								n.open = should_open
							end
						end, { all = true })
						require("snacks.explorer.actions").update(picker, { refresh = true })
					end,
				},
				layout = {
					preview = true,
					preset = "telescope",
					-- or "vertical" with custom dimensions
					-- layout = {
					-- 	backdrop = false,
					-- 	row = -2,
					-- 	col = -1,
					-- 	width = 40,
					-- 	min_width = 40,
					-- 	height = vim.o.lines - 3,
					-- 	box = "vertical",
					-- 	{
					-- 		win = "input",
					-- 		height = 1,
					-- 		border = true,
					-- 		title = "{title} {live} {flags}",
					-- 		title_pos = "center",
					-- 	},
					-- 	{ win = "list", border = true, title = "Files" },
					-- 	{ win = "preview", title = "{preview}", height = 0.4, border = "top" },
					-- },
				},
				win = {
					list = {
						keys = {
							["za"] = "confirm",
							["zA"] = "explorer_toggle_recursive",
							["zR"] = "explorer_open_all",
							["zM"] = "explorer_close_all",
							["zc"] = "explorer_close",
							["zC"] = "explorer_close_recursive",
							["zo"] = "confirm",
							["zO"] = "explorer_open_recursive",
							["S"] = "edit_split",
							["s"] = "edit_vsplit",
							["t"] = "edit_tab",
							["R"] = "explorer_update",
							["]d"] = "explorer_diagnostic_next",
							["[d"] = "explorer_diagnostic_prev",
						},
					},
				},
				main = { current = true },
				on_show = function(picker)
					local cursor = vim.api.nvim_win_get_cursor(picker.main)
					local info = vim.api.nvim_win_call(picker.main, vim.fn.winsaveview)
					picker.list:view(cursor[1], info.topline)
					picker:show_preview()
				end,
			},
		},
	},
}

---@type LazyKeysSpec[]
local keys = {
	{
		"<leader>ee",
		function()
			Snacks.explorer()
		end,
		desc = "Explorer (float)",
	},
	{
		"<leader>ec",
		function()
			Snacks.explorer.reveal()
		end,
		desc = "Explorer reveal current",
	},
	{
		"<leader>eb",
		function()
			Snacks.picker.buffers()
		end,
		desc = "Buffers (replaces neo-tree buffers)",
	},
	{
		"<leader>eg",
		function()
			Snacks.picker.git_status()
		end,
		desc = "Git status (replaces neo-tree git)",
	},
}

---@type SnacksSubmodule
return { opts = opts, keys = keys }
