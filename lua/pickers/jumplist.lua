local api = vim.api
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

--- Tronque le début d'un chemin si trop long
---@param path string
---@param max_len number
---@return string
local function truncate_path(path, max_len)
	if #path <= max_len then
		return path
	end
	return "…" .. path:sub(-(max_len - 1))
end

--- Ouvre Telescope avec la jumplist, position actuelle sélectionnée par défaut
return function(opts)
	opts = opts or {}
	local path_max_len = opts.path_max_len or 40

	local jumplist, current_idx = unpack(vim.fn.getjumplist())

	if #jumplist == 0 then
		vim.notify("Jumplist vide", vim.log.levels.INFO)
		return
	end

	-- Filtrer les entrées valides (ordre inversé : dernier jump en haut)
	local entries = {}
	for i = #jumplist, 1, -1 do
		local jump = jumplist[i]
		local bufnr = jump.bufnr
		if api.nvim_buf_is_valid(bufnr) then
			local bufname = api.nvim_buf_get_name(bufnr)
			local filename = bufname ~= "" and vim.fn.fnamemodify(bufname, ":~:.") or "[No Name]"
			local line_text = ""
			if api.nvim_buf_is_loaded(bufnr) then
				local lines = api.nvim_buf_get_lines(bufnr, jump.lnum - 1, jump.lnum, false)
				line_text = lines[1] and vim.trim(lines[1]) or ""
			end
			table.insert(entries, {
				idx = i,
				bufnr = bufnr,
				lnum = jump.lnum,
				col = jump.col + 1,
				filename = filename,
				text = line_text,
			})
		end
	end

	-- Calculer l'index de sélection par défaut (position actuelle dans la jumplist)
	local default_selection = 1
	for i, entry in ipairs(entries) do
		if entry.idx == current_idx + 1 then
			default_selection = i
			break
		end
	end

	-- Calculer la largeur max des numéros de ligne pour alignement
	local max_lnum = 0
	for _, entry in ipairs(entries) do
		if entry.lnum > max_lnum then
			max_lnum = entry.lnum
		end
	end
	local lnum_width = #tostring(max_lnum)

	local function make_display(entry)
		local is_current = entry.value.idx == current_idx + 1
		local lnum_str = string.format("%" .. lnum_width .. "d", entry.value.lnum)
		local display_path = truncate_path(entry.value.filename, path_max_len)
		local text = entry.value.text

		local line = lnum_str .. " " .. display_path
		if text ~= "" then
			line = line .. "  " .. text
		end

		local highlights = {}
		local col = 0

		local lnum_hl = is_current and "DiagnosticError" or "TelescopeResultsLineNr"
		table.insert(highlights, { { col, col + #lnum_str }, lnum_hl })
		col = col + #lnum_str + 1

		table.insert(highlights, { { col, col + #display_path }, "Normal" })
		col = col + #display_path

		if text ~= "" then
			col = col + 2
			table.insert(highlights, { { col, col + #text }, "Comment" })
		end

		return line, highlights
	end

	pickers
		.new(opts, {
			prompt_title = "Jumplist",
			finder = finders.new_table({
				results = entries,
				entry_maker = function(entry)
					return {
						value = entry,
						display = make_display,
						ordinal = entry.filename .. " " .. entry.text,
						path = api.nvim_buf_get_name(entry.bufnr),
						filename = api.nvim_buf_get_name(entry.bufnr),
						lnum = entry.lnum,
						col = entry.col,
						bufnr = entry.bufnr,
					}
				end,
			}),
			previewer = conf.qflist_previewer(opts),
			sorter = conf.generic_sorter(opts),
			default_selection_index = default_selection,
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection then
						api.nvim_set_current_buf(selection.bufnr)
						api.nvim_win_set_cursor(0, { selection.lnum, selection.col - 1 })
					end
				end)
				return true
			end,
		})
		:find()
end
