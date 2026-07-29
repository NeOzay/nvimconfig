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

---@class Ozay.Bookmarks.Service.Context
---@field root string
---@field file string

--- Racine du projet + chemin du fichier du buffer, regroupés en un seul appel.
---@param bufnr integer
---@return Ozay.Bookmarks.Service.Context
local function context(bufnr)
	return { root = utils.project_root(), file = buf_file(bufnr) }
end

---@alias Ozay.Bookmarks.Service.Opts { annotation?: string, tag?: string, note?: string }

--- Ajoute un bookmark sur la ligne courante du buffer donné.
---@param bufnr integer
---@param lnum integer
---@param opts? Ozay.Bookmarks.Service.Opts
---@return Ozay.Bookmarks.Record?
function M.add(bufnr, lnum, opts)
	if skip_buf(bufnr) then
		return nil
	end
	opts = opts or {}
	local ctx = context(bufnr)
	local code_context = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
	---@type Ozay.Bookmarks.NewRecord
	local new_record = {
		project_root = ctx.root,
		file = ctx.file,
		lnum = lnum,
		annotation = opts.annotation,
		code_context = code_context,
		tag = opts.tag,
		note = opts.note,
		created_at = os.time(),
	}
	local id = db.insert(new_record)
	if not id then
		return nil
	end
	---@type Ozay.Bookmarks.Record
	return vim.tbl_extend("force", new_record, { id = id })
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
	local ctx = context(bufnr)
	for _, record in ipairs(db.list_by_file(ctx.root, ctx.file)) do
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
	local ctx = context(bufnr)
	return db.list_by_file(ctx.root, ctx.file)
end

--- Tous les bookmarks du projet courant (pour Trouble/Snacks), triés par fichier puis lnum.
---@return Ozay.Bookmarks.Record[]
function M.list_for_project()
	return db.list_by_project(utils.project_root())
end

--- Met à jour un bookmark existant (partiel : seuls les champs fournis sont écrits —
--- `db.update` boucle sur `pairs`, une valeur `nil` est donc ignorée, pas effacée).
---@param id integer
---@param opts Partial<Ozay.Bookmarks.Record>
function M.update(id, opts)
	db.update(id, opts)
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
	local ctx = context(bufnr)
	db.delete_by_file(ctx.root, ctx.file)
end

M.skip_buf = skip_buf

return M
