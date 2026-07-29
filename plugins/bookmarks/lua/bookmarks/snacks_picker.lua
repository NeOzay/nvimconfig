---@diagnostic disable:param-type-mismatch
--- Ouvre un picker Snacks listant les bookmarks du projet courant.
return function()
	local bookmarks = require("bookmarks")
	local config = require("bookmarks.config")

	Snacks.picker.pick({
		title = "󰃁 Bookmarks",
		layout = {
			preset = "ivy_2",
		},
		finder = function(opts, ctx)
			local items = {}
			for _, record in ipairs(bookmarks.list_for_project()) do
				table.insert(items, {
					text = vim.trim(record.annotation or record.code_context or ""),
					file = record.file,
					pos = { record.lnum, 0 },
					bookmark = record,
				})
			end
			return ctx.filter:filter(items)
		end,
		format = function(item, picker)
			local ret = {}
			if item.bookmark.tag and item.bookmark.tag ~= "" then
				table.insert(ret, { "[" .. item.bookmark.tag .. "] ", "DiagnosticSignInfo" })
			end
			vim.list_extend(ret, Snacks.picker.format.filename(item, picker))
			if item.bookmark.note and item.bookmark.note ~= "" then
				local signs = config.options.signs
				table.insert(ret, { " " .. signs.note_icon, signs.note_hl_group })
			end
			if item.text ~= "" then
				table.insert(ret, { " " .. item.text, "Comment" })
			end
			return ret
		end,
		confirm = function(picker, item)
			if not item then
				return
			end
			picker:close()
			vim.cmd(("edit %s"):format(vim.fn.fnameescape(item.file)))
			vim.api.nvim_win_set_cursor(0, { item.pos[1], item.pos[2] })
		end,
		---@type table<string, fun(picker:snacks.Picker, item: {bookmark: Ozay.Bookmarks.Record})>
		actions = {
			bookmark_delete = function(picker, item)
				if not item then
					return
				end
				bookmarks.remove(item.bookmark)
				picker:refresh()
			end,
			bookmark_note = function(picker, item)
				if not item then
					return
				end
				require("bookmarks.note").open_for_record(item.bookmark, {
					on_saved = function()
						if picker then
							picker:refresh()
						end
					end,
				})
			end,
		},
		win = {
			input = {
				keys = {
					["<M-d>"] = { "bookmark_delete", mode = { "i", "n" } },
					["<M-k>"] = { "bookmark_note", mode = { "i", "n" } },
				},
			},
			list = { keys = { ["dd"] = "bookmark_delete", ["K"] = "bookmark_note" } },
		},
	})
end
