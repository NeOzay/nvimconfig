---@diagnostic disable:missing-fields
---@class trouble.Source.bookmarks: trouble.Source
local M = {}

---@type trouble.Config
M.config = {
	modes = {
		bookmarks = {
			desc = "Project Bookmarks",
			source = "bookmarks.bookmarks",
			groups = {
				{ "filename", format = "{file_icon} {filename} {count}" },
			},
			sort = { "filename", "pos" },
			format = "{text} {pos}",
			keys = {
				K = {
					action = function(view, ctx)
						local record = ctx.item and ctx.item.item
						if not record then
							return
						end
						require("bookmarks.note").open_for_record(record, {
							on_saved = function()
								view:refresh()
							end,
						})
					end,
					desc = "Note du bookmark",
				},
				dd = {
					action = function(view, ctx)
						local record = ctx.item and ctx.item.item
						if not record then
							return
						end
						require("bookmarks").remove(record)
						view:refresh()
					end,
				},
			},
		},
	},
}

M.get = {
	---@param cb trouble.Source.Callback
	bookmarks = function(cb)
		local config = require("bookmarks.config")
		local service = require("bookmarks.service")
		local Item = require("trouble.item")
		local note_icon = config.options.signs.note_icon
		-- espace insécable (U+00A0) : trouble.nvim fait vim.trim() sur `text`, qui ne
		-- retire que les espaces ASCII (%s) — un padding en tête doit donc l'éviter.
		local note_pad = string.rep("\u{00A0}", vim.fn.strdisplaywidth(note_icon))
		local items = {}
		for _, record in ipairs(service.list_for_project()) do
			local text = ""
			if record.note and record.note ~= "" then
				text = text .. note_icon .. " "
			else
				text = text .. note_pad .. " "
			end

			text = text .. vim.trim(record.annotation or record.code_context or "")
			if record.tag and record.tag ~= "" then
				text = ("[%s] %s"):format(record.tag, text)
			end
			items[#items + 1] = Item.new({
				source = "bookmarks",
				filename = record.file,
				pos = { record.lnum, 0 },
				text = text,
				item = record,
			})
		end
		cb(items)
	end,
}

local registered = false

--- Enregistre la source auprès de trouble.nvim. Idempotent.
function M.register()
	if registered then
		return
	end
	require("trouble.sources").register("bookmarks", M)
	registered = true
end

return M
