---@class Ozay.Bookmarks.Utils
local M = {}

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

return M
