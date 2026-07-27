--- Ouvre un picker Snacks listant les bookmarks du projet courant.
return function()
	local service = require("plugins.bookmarks.service")

	Snacks.picker.pick({
		title = "󰃁 Bookmarks",
		layout = {
			preset = "ivy_2",
		},
		finder = function(opts, ctx)
			local items = {}
			for _, record in ipairs(service.list_for_project()) do
				table.insert(items, {
					text = record.annotation or record.code_context or "",
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
			if item.text ~= "" then
				table.insert(ret, { "  " .. item.text, "Comment" })
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
		actions = {
			bookmark_delete = function(picker, item)
				if not item then
					return
				end
				service.remove(item.bookmark.id)
				picker:refresh()
			end,
		},
		win = {
			input = { keys = { ["<M-d>"] = "bookmark_delete" } },
			list = { keys = { ["dd"] = "bookmark_delete" } },
		},
	})
end
