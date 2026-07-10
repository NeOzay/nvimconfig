return function()
	local harpoon = require("harpoon")
	local utils = require("utils")

	local input_keys = {
		["<A-d>"] = { "harpoon_delete", mode = { "i", "n" } },
	}

	---@type table<string, snacks.picker.Action.spec>
	local list_keys = {
		["dd"] = "harpoon_delete",
	}
	for i = 1, 9 do
		local key = utils.key_nb_mapping(i)
		local idx = i
		list_keys[key] = function(picker)
			picker:close()
			harpoon:list():select(idx)
		end
		input_keys["<C-" .. key .. ">"] = {
			function(picker)
				picker:close()
				harpoon:list():select(idx)
			end,
			mode = { "i", "n" },
		}
	end

	Snacks.picker.pick({
		title = "ψ Harpoon",
		finder = function(opts, ctx)
			local items = {}
			for idx, item in pairs(harpoon:list().items) do
				table.insert(items, {
					text = item.value,
					file = vim.fs.abspath(item.value),
					pos = {
						item.context and item.context.row or 1,
						item.context and item.context.col or 0,
					},
					harpoon_idx = idx,
				})
			end
			table.sort(items, function(a, b)
				return a.harpoon_idx < b.harpoon_idx
			end)
			return ctx.filter:filter(items)
		end,
		format = function(item, picker)
			local ret = { { string.format("[%d] ", item.harpoon_idx), "Comment" } }
			vim.list_extend(ret, Snacks.picker.format.filename(item, picker))
			return ret
		end,
		confirm = function(picker, item)
			if not item then
				return
			end
			picker:close()
			harpoon:list():select(item.harpoon_idx)
		end,
		actions = {
			harpoon_delete = function(picker, item)
				if not item then
					return
				end
				harpoon:list():remove_at(item.harpoon_idx)
				picker:refresh()
			end,
		},
		win = {
			input = { keys = input_keys },
			list = { keys = list_keys },
		},
	})
end
