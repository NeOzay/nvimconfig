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
				---@type table<string, snacks.picker.Action.spec>
				actions = {
					explorer_open_recursive = function(picker, item)
						if not item or not item.dir then
							return
						end
						local Tree = require("snacks.explorer.tree")
						local node = Tree:find(item.file or "")
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
						local dir = Tree:dir(item.file or "")
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
						local list = picker.list
						local current_file = list.items and list.items[list.cursor] and list.items[list.cursor].file

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
						list:set_target()
						require("snacks.explorer.actions").update(picker, { refresh = true, target = current_file })
					end,
					explorer_toggle_recursive = function(picker, item)
						if not item or not item.dir then
							return
						end
						local Tree = require("snacks.explorer.tree")
						local node = Tree:find(item.file or "")
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
					explorer_jump_parent = function(picker, item)
						if not item then
							return
						end
						local list = picker.list
						local items = list.items
						if not items then
							return
						end
						local parent_path = vim.fs.dirname(item.file)
						local pos = list.cursor or 1
						for i = pos - 1, 1, -1 do
							if items[i] and items[i].dir and items[i].file == parent_path then
								list:move(i - pos)
								return
							end
						end
					end,
					explorer_jump_next_parent = function(picker, item)
						if not item then
							return
						end
						local list = picker.list
						local items = list.items
						if not items then
							return
						end
						local parent_depth = select(2, vim.fs.dirname(item.file):gsub("/", ""))
						local pos = list.cursor or 1
						for i = pos + 1, #items do
							if items[i] and items[i].dir then
								local depth = select(2, items[i].file:gsub("/", ""))
								if depth == parent_depth then
									list:move(i - pos)
									return
								end
							end
						end
					end,
					explorer_next_dir = function(picker)
						local list = picker.list
						local items = list.items
						if not items then
							return
						end
						local pos = list.cursor or 1
						for i = pos + 1, #items do
							if items[i] and items[i].dir then
								list:move(i - pos)
								return
							end
						end
					end,
					explorer_prev_dir = function(picker)
						local list = picker.list
						local items = list.items
						if not items then
							return
						end
						local pos = list.cursor or 1
						for i = pos - 1, 1, -1 do
							if items[i] and items[i].dir then
								list:move(i - pos)
								return
							end
						end
					end,
				},
				layout = {
					preview = true,
					preset = require("utils").get_layout_preset,
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
							["<C-Down>"] = "explorer_next_dir",
							["<C-Up>"] = "explorer_prev_dir",
							["<S-C-Up>"] = "explorer_jump_parent",
							["<S-C-Down>"] = "explorer_jump_next_parent",
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
		desc = "Explorer",
	},
	{
		"<leader>ea",
		function()
			Snacks.explorer({ hidden = true, ignored = true })
		end,
		desc = "Explorer (all files)",
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
			local cwd = vim.fs.normalize(vim.uv.cwd() or "")
			local include_paths = {}
			local seen = {}

			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
					local name = vim.api.nvim_buf_get_name(buf)
					if name ~= "" then
						name = vim.fs.normalize(name)
						if vim.startswith(name, cwd .. "/") then
							if not seen[name] then
								seen[name] = true
								table.insert(include_paths, name)
							end
							local dir = vim.fs.dirname(name)
							while dir and not seen[dir] do
								seen[dir] = true
								table.insert(include_paths, dir)
								if dir == cwd then
									break
								end
								dir = vim.fs.dirname(dir)
							end
						end
					end
				end
			end

			Snacks.explorer({
				include = include_paths,
				exclude = { "**" },
			})
		end,
		desc = "Explorer (open buffers only)",
	},
	{
		"<leader>eg",
		function()
			Snacks.picker.git_status()
		end,
		desc = "Explorer (git status)",
	},
}

---@type SnacksSubmodule
return { opts = opts, keys = keys }
