local db = require("bookmarks.db")
local utils = require("bookmarks.utils")

---@class Ozay.Bookmarks.Service
local M = {}

---@param bufnr integer
---@return boolean
local function skip_buf(bufnr)
	if vim.api.nvim_buf_get_name(bufnr) == "" then
		return true
	elseif vim.bo[bufnr].buftype ~= "" then
		return true
	end
	return false
end

---@param bufnr integer
---@return string
local function buf_file(bufnr)
	return utils.unify_path(vim.api.nvim_buf_get_name(bufnr))
end

--- Ajoute un bookmark sur la ligne courante du buffer donné.
---@param bufnr integer
---@param lnum integer
---@param opts? { annotation?: string, tag?: string }
---@return Ozay.Bookmarks.Record?
function M.add(bufnr, lnum, opts)
	if skip_buf(bufnr) then
		return nil
	end
	opts = opts or {}
	local file = buf_file(bufnr)
	local code_context = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
	---@type Ozay.Bookmarks.Record
	local record = {
		project_root = utils.project_root(),
		file = file,
		lnum = lnum,
		annotation = opts.annotation,
		code_context = code_context,
		tag = opts.tag,
		created_at = os.time(),
	}
	local id = db.insert(record)
	if not id then
		return nil
	end
	record.id = id
	return record
end

--- Supprime un bookmark par id.
---@param id integer
function M.remove(id)
	db.delete(id)
end

--- Bookmark existant sur bufnr/lnum, ou nil.
---@param bufnr integer
---@param lnum integer
---@return Ozay.Bookmarks.Record?
function M.find(bufnr, lnum)
	if skip_buf(bufnr) then
		return nil
	end
	local root = utils.project_root()
	local file = buf_file(bufnr)
	for _, record in ipairs(db.list_by_file(root, file)) do
		if record.lnum == lnum then
			return record
		end
	end
	return nil
end

--- Tous les bookmarks du fichier courant, triés par lnum.
---@param bufnr integer
---@return Ozay.Bookmarks.Record[]
function M.list_for_buffer(bufnr)
	if skip_buf(bufnr) then
		return {}
	end
	return db.list_by_file(utils.project_root(), buf_file(bufnr))
end

--- Tous les bookmarks du projet courant (pour Trouble/Snacks), triés par fichier puis lnum.
---@return Ozay.Bookmarks.Record[]
function M.list_for_project()
	return db.list_by_project(utils.project_root())
end

--- Met à jour l'annotation/tag d'un bookmark existant.
---@param id integer
---@param annotation? string
---@param tag? string
function M.set_annotation(id, annotation, tag)
	db.update(id, { annotation = annotation, tag = tag })
end

--- Met à jour le numéro de ligne d'un bookmark (resync après déplacement).
---@param id integer
---@param lnum integer
function M.set_lnum(id, lnum)
	db.update(id, { lnum = lnum })
end

--- Supprime tous les bookmarks du fichier courant.
---@param bufnr integer
function M.clear_buffer(bufnr)
	if skip_buf(bufnr) then
		return
	end
	db.delete_by_file(utils.project_root(), buf_file(bufnr))
end

M.skip_buf = skip_buf

return M
