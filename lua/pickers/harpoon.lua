local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")

local function make_finder()
	local harpoon = require("harpoon")
	---@type {idx:integer, value:string, display:string}[]
	local items = {}
	for idx, item in pairs(harpoon:list().items) do
		table.insert(items, {
			idx = idx,
			value = item.value,
			display = string.format("[%d] %s", idx, item.value),
		})
	end
	table.sort(items, function(a, b)
		return a.idx < b.idx
	end)

	return finders.new_table({
		results = items,
		entry_maker = function(entry)
			return {
				value = entry.value,
				display = entry.display,
				ordinal = entry.value,
				path = entry.value,
				idx = entry.idx,
			}
		end,
	})
end

local function restore_selection(picker, target_row)
	local total = picker.manager:num_results()
	if total == 0 then
		return
	end

	local target = math.min(target_row, total)
	local old_lazyredraw = vim.o.lazyredraw
	vim.o.lazyredraw = true

	for _ = 1, total do
		actions.move_selection_previous(picker.prompt_bufnr)
	end
	for _ = 1, target - 1 do
		actions.move_selection_next(picker.prompt_bufnr)
	end

	vim.o.lazyredraw = old_lazyredraw
	vim.cmd("redraw")
end

return function()
	local harpoon = require("harpoon")
	pickers
		.new({}, {
			prompt_title = "Harpoon",
			finder = make_finder(),
			previewer = conf.file_previewer({}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				local function delete_entry()
					local picker = action_state.get_current_picker(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if not selection then
						return
					end

					local current_row = picker:get_selection_row()
					harpoon:list():remove_at(selection.idx)
					picker:refresh(make_finder(), { reset_prompt = false })

					vim.defer_fn(function()
						restore_selection(picker, current_row + 1)
					end, 50)
				end

				local function select_by_index(idx)
					actions.close(prompt_bufnr)
					harpoon:list():select(idx)
				end

				map("i", "<A-d>", delete_entry)
				map("n", "dd", delete_entry)

				for i = 1, 9 do
					local key = require("utils").key_nb_mapping(i)
					map("n", key, function()
						select_by_index(i)
					end)
					map("i", "<C-" .. key .. ">", function()
						select_by_index(i)
					end)
				end

				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if selection then
						harpoon:list():select(selection.idx)
					end
				end)

				return true
			end,
		})
		:find()
end
