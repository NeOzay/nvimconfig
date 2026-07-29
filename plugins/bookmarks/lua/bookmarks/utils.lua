---@class Ozay.Bookmarks.Utils
local M = {}

--- Notifie avec le titre "bookmarks.nvim" (évite de le répéter à chaque appel).
---@param msg string
---@param level integer
function M.notify(msg, level)
	vim.notify(msg, level, { title = "bookmarks.nvim" })
end

--- Normalise un chemin de fichier en chemin absolu, séparateurs uniformisés.
---@param path string
---@return string
function M.unify_path(path)
	local p = vim.fs.normalize(path)
	if not vim.startswith(p, "/") then
		p = vim.fs.joinpath(vim.fn.getcwd(), p)
	end
	return p
end

--- Racine du projet courant : racine git si disponible, sinon cwd.
---@return string
function M.project_root()
	local root = vim.fs.root(0, ".git")
	return M.unify_path(root or vim.fn.getcwd())
end

--- Bufnr du buffer chargé correspondant à un chemin absolu (voir unify_path).
---@param file string
---@return integer?
function M.find_buf(file)
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and M.unify_path(vim.api.nvim_buf_get_name(buf)) == file then
			return buf
		end
	end
end

return M
