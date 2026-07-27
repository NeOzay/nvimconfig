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
		},
	},
}

M.get = {
	---@param cb trouble.Source.Callback
	bookmarks = function(cb)
		local service = require("plugins.bookmarks.service")
		local Item = require("trouble.item")
		local items = {}
		for _, record in ipairs(service.list_for_project()) do
			local text = record.annotation or record.code_context or ""
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
