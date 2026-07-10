local tabpage = require("tabpage")

---@class Ozay.TabpageItem : snacks.picker.finder.Item
---@field tabnr integer
---@field nwin integer
---@field current boolean

---@return Ozay.TabpageItem[]
local function tabpage_items()
	local current = vim.api.nvim_get_current_tabpage()
	---@type Ozay.TabpageItem[]
	local items = {}
	for _, tabnr in ipairs(vim.api.nvim_list_tabpages()) do
		local wins = vim.api.nvim_tabpage_list_wins(tabnr)
		wins = vim.tbl_filter(function(win)
			local buf = vim.api.nvim_win_get_buf(win)
			local bt = vim.api.nvim_get_option_value("buftype", { buf = buf })
			return not (bt ~= "" and bt ~= "help")
		end, wins)
		local buf = vim.api.nvim_win_get_buf(wins[1] or 0)
		items[#items + 1] = {
			text = tabpage.get_name(tabnr),
			file = vim.api.nvim_buf_get_name(buf),
			tabnr = tabnr,
			nwin = #wins,
			current = tabnr == current,
		}
	end
	table.sort(items, function(a, b)
		return vim.api.nvim_tabpage_get_number(a.tabnr) < vim.api.nvim_tabpage_get_number(b.tabnr)
	end)
	return items
end

--- Les fenêtres flottantes (dont le picker) appartiennent à un seul tabpage :
--- changer de tab masque le picker au lieu de le suivre. On ferme donc le
--- picker et on le rouvre sur le nouveau tab, en replaçant le curseur sur le
--- même item et en conservant le texte de recherche.
---@param opts? { origin_tab?: integer, preselect_tab?: integer, pattern?: string }
local function open_tabpage_picker(opts)
	opts = opts or {}
	local origin_tab = opts.origin_tab or vim.api.nvim_get_current_tabpage()
	local preselect_tab = opts.preselect_tab or origin_tab
	local accepted = false
	local switching = false
	-- La toute première preview (item de la ligne 1) se déclenche pendant la
	-- création de la fenêtre de la list, donc avant que notre `on_show`
	-- puisse repositionner le curseur sur `preselect_tab`. On ignore les
	-- `on_change` tant que ce repositionnement initial n'a pas eu lieu.
	local ready = false

	-- Hauteur de la box ajustée au nombre de tabs : input (1) + bordures (2) +
	-- une ligne par item. `bottom_compact` borne le résultat via min/max_height.
	local item_count = #tabpage_items()

	Snacks.picker.pick({
		title = "Tabpages",
		pattern = opts.pattern,
		layout = {
			preset = "bottom_compact",
			layout = { height = item_count + 2, width = 30 },
		},
		finder = function(_, ctx)
			return ctx.filter:filter(tabpage_items())
		end,
		---@param item Ozay.TabpageItem
		format = function(item, picker)
			local ret = {
				{ item.current and "  " or "  ", "Comment" },
				{ ("[%d] "):format(vim.api.nvim_tabpage_get_number(item.tabnr)), "Comment" },
				{ item.text, item.current and "Title" or "Normal" },
			}
			if item.nwin > 1 then
				ret[#ret + 1] = { (" · %d fenêtres"):format(item.nwin), "Comment" }
			end
			return ret
		end,
		on_show = function(picker)
			local function select_preselected()
				for item, idx in picker:iter() do
					if item.tabnr == preselect_tab then
						picker.list:view(idx)
						return true
					end
				end
				return false
			end
			-- Le matcher tourne de façon asynchrone (coroutine) : à l'ouverture
			-- la liste peut encore être vide. Si la sélection échoue, on attend
			-- la fin du matching (task "done") avant de réessayer.
			if select_preselected() or not picker.matcher.task:running() then
				ready = true
			else
				picker.matcher.task:on(
					"done",
					vim.schedule_wrap(function()
						if not picker.closed then
							select_preselected()
						end
						ready = true
					end)
				)
			end
		end,
		---@param item Ozay.TabpageItem
		on_change = function(picker, item)
			if not ready or switching or not item then
				return
			end
			if item.tabnr == vim.api.nvim_get_current_tabpage() or not vim.api.nvim_tabpage_is_valid(item.tabnr) then
				return
			end
			switching = true
			local pattern = picker:filter().pattern
			local target = item.tabnr
			-- Différé : laisse le throttle TextChangedI de l'input (30-200ms)
			-- vider sa file avant de fermer le picker, sinon son callback
			-- planifié peut s'exécuter après coup sur un picker détruit
			-- (input.picker devient nil dans input.lua:close) et crasher.
			vim.defer_fn(function()
				if picker.closed then
					return
				end
				picker:close()
				vim.api.nvim_set_current_tabpage(target)
				open_tabpage_picker({ origin_tab = origin_tab, preselect_tab = target, pattern = pattern })
			end, 10)
		end,
		on_close = function()
			if switching or accepted then
				return
			end
			if vim.api.nvim_tabpage_is_valid(origin_tab) then
				vim.api.nvim_set_current_tabpage(origin_tab)
			end
		end,
		---@param item Ozay.TabpageItem
		confirm = function(picker, item)
			accepted = true
			picker:close()
			if item then
				vim.api.nvim_set_current_tabpage(item.tabnr)
			end
		end,
		actions = {
			---@param item Ozay.TabpageItem
			tab_rename = function(picker, item)
				if not item then
					return
				end
				tabpage.rename(item.tabnr, function()
					picker:refresh()
				end)
			end,
			---@param item Ozay.TabpageItem
			tab_close = function(picker, item)
				if not item then
					return
				end
				vim.cmd(("%dtabclose"):format(vim.api.nvim_tabpage_get_number(item.tabnr)))
				picker:refresh()
				open_tabpage_picker({
					origin_tab = origin_tab,
					preselect_tab = vim.api.nvim_get_current_tabpage(),
					pattern = picker:filter().pattern,
				})
			end,
			tab_new = function(picker)
				accepted = true
				picker:close()
				vim.cmd("tabnew")
			end,
			---@param item Ozay.TabpageItem
			tab_cwd = function(picker, item)
				if not item then
					return
				end
				local tabpage_nr = vim.api.nvim_tabpage_get_number(item.tabnr)
				local tab_cwd = vim.fs.normalize(vim.fn.getcwd(-1, tabpage_nr))
				-- Si le buffer du tab est hors du cwd du tab, on préremplit avec
				-- son dossier plutôt que le cwd actuel (souvent inutile dans ce cas).
				local default_cwd = tab_cwd
				if item.file ~= "" then
					local file_dir = vim.fs.normalize(vim.fs.dirname(item.file))
					if file_dir ~= tab_cwd and not vim.startswith(file_dir .. "/", tab_cwd .. "/") then
						default_cwd = file_dir
					end
				end
				vim.ui.input({ prompt = "Cwd du tab: ", default = default_cwd, completion = "dir" }, function(input)
					if not input or input == "" then
						return
					end
					vim.api.nvim_set_current_tabpage(item.tabnr)
					vim.cmd.tcd(input)
					picker:refresh()
				end)
			end,
		},
		win = {
			input = {
				keys = {
					["<A-r>"] = { "tab_rename", mode = { "i", "n" } },
					["<A-d>"] = { "tab_close", mode = { "i", "n" } },
					["<A-n>"] = { "tab_new", mode = { "i", "n" } },
					["<A-c>"] = { "tab_cwd", mode = { "i", "n" } },
				},
			},
			list = {
				keys = {
					["r"] = "tab_rename",
					["dd"] = "tab_close",
					["a"] = "tab_new",
					["c"] = "tab_cwd",
				},
			},
		},
	})
end

--- Ouvre le picker Snacks listant les tabpages ouverts.
return function()
	open_tabpage_picker()
end
