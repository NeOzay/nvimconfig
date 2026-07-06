--- Compte les lignes d'un fichier (nil si illisible)
---@param path string
---@return integer?
local function count_lines(path)
	local fd = io.open(path, "rb")
	if not fd then
		return nil
	end
	local content = fd:read("*a")
	fd:close()
	if not content then
		return 0
	end
	local _, n = content:gsub("\n", "")
	if content ~= "" and content:sub(-1) ~= "\n" then
		n = n + 1
	end
	return n
end

--- Trie les enfants d'un noeud comme le fait l'explorateur natif (dossiers avant
--- fichiers, puis ordre alphabétique), et renvoie la liste triée.
---@param node snacks.picker.explorer.Node
---@return snacks.picker.explorer.Node[]
local function sorted_children(node)
	local children = vim.tbl_values(node.children)
	table.sort(children, function(a, b)
		if a.dir ~= b.dir then
			return a.dir
		end
		return a.name < b.name
	end)
	return children
end

--- Finder explorer filtré : parcourt tout l'arbre récursivement (indépendamment
--- de l'état plié/déplié des dossiers dans l'explorateur normal) et ne garde
--- que les fichiers de plus de `threshold` lignes, ainsi que les dossiers menant
--- à au moins un de ces fichiers. Les autres dossiers sont masqués.
---@param threshold integer
local function big_files_finder(threshold)
	return function(_, ctx)
		local cwd = ctx.filter.cwd
		return function(cb)
			local Tree = require("snacks.explorer.tree")
			Tree:refresh(cwd)
			local filter = Tree:filter({ hidden = false, ignored = false })

			---@param node snacks.picker.explorer.Node
			---@param parent_item table
			---@return table? kept item (with `_children` for dirs), nil if pruned
			local function visit(node, parent_item)
				if not filter(node) then
					return nil
				end
				if node.dir then
					if not node.expanded then
						Tree:expand(node)
					end
					local item = {
						file = node.path,
						dir = true,
						open = true,
						parent = parent_item,
						text = node.path,
						status = node.status,
					}
					local kept = {}
					for _, child in ipairs(sorted_children(node)) do
						local kid = visit(child, item)
						if kid then
							kept[#kept + 1] = kid
						end
					end
					if #kept == 0 then
						return nil
					end
					kept[#kept].last = true
					item._children = kept
					return item
				end

				local n = count_lines(node.path)
				if not n or n <= threshold then
					return nil
				end
				return {
					file = node.path,
					dir = false,
					parent = parent_item,
					text = node.path,
					status = node.status,
					line_count = n,
				}
			end

			local root_node = Tree:find(cwd)
			if not root_node.expanded then
				Tree:expand(root_node)
			end
			local root_item = { file = root_node.path, dir = true, open = true, text = "" }
			local kept = {}
			for _, child in ipairs(sorted_children(root_node)) do
				local kid = visit(child, root_item)
				if kid then
					kept[#kept + 1] = kid
				end
			end
			if #kept == 0 then
				return
			end
			kept[#kept].last = true

			local function emit(item)
				cb(item)
				if item._children then
					for _, child in ipairs(item._children) do
						emit(child)
					end
				end
			end

			cb(root_item)
			for _, item in ipairs(kept) do
				emit(item)
			end
		end
	end
end

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
					preset = require("utils").get_layout_preset("telescope", { ivy_2_tall = 120 }),
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
	{
		"<leader>el",
		function()
			Snacks.explorer({
				title = "Explorer (> 300 lignes)",
				finder = big_files_finder(300),
				formatters = { file = { filename_only = true } },
				format = function(item, picker)
					local ret = Snacks.picker.format.file(item, picker)
					if item.line_count then
						ret[#ret + 1] = { ("  %d lignes"):format(item.line_count), "Comment" }
					end
					return ret
				end,
			})
		end,
		desc = "Explorer (fichiers > 300 lignes)",
	},
}

---@type SnacksSubmodule
return { opts = opts, keys = keys }
