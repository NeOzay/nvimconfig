--- Events `User` émis à chaque mutation de bookmark, consommés notamment par la
--- source Trouble (`trouble.lua`, champ déclaratif `events`) pour un auto-refresh
--- sans callback manuel par site d'appel.
---@class Ozay.Bookmarks.Events
local M = {}

M.CREATE = "BookmarkCreate"
M.UPDATE = "BookmarkUpdate"
M.DELETED = "BookmarkDeleted"

---@param pattern string
---@param data? unknown
function M.emit(pattern, data)
	vim.api.nvim_exec_autocmds("User", { pattern = pattern, data = data })
end

return M
