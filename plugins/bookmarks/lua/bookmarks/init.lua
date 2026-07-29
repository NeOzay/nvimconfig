local config = require("bookmarks.config")
local db = require("bookmarks.db")
local service = require("bookmarks.service")
local ui = require("bookmarks.ui")
local note = require("bookmarks.note")
local utils = require("bookmarks.utils")

--- Buffer et ligne sous le curseur, dans la fenêtre courante.
---@return integer bufnr
---@return integer lnum
local function cursor_pos()
	return vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_cursor(0)[1]
end

---@class Ozay.Bookmarks
local M = {}

---@param bufnr integer
---@param lnum integer
---@param opts? Ozay.Bookmarks.Service.Opts
---@return Ozay.Bookmarks.Record?
function M.create(bufnr, lnum, opts)
	local existing = M.get(bufnr, lnum)
	if existing then
		if opts then
			return M.update(bufnr, lnum, opts)
		end
		return existing
	end

	local record = service.add(bufnr, lnum, opts)
	if record then
		ui.render_one(bufnr, record)
		utils.notify("bookmark ajouté.", vim.log.levels.INFO)
	end
	return record
end

M.get = service.find

---@param bufnr integer
---@param lnum integer
---@param opts?  Ozay.Bookmarks.Service.Opts
---@return Ozay.Bookmarks.Record?
function M.get_or_create(bufnr, lnum, opts)
	local existing = service.find(bufnr, lnum)
	if existing then
		return existing
	end
	return M.create(bufnr, lnum, opts)
end

-- @param bufnr integer|Ozay.Bookmarks.Record
-- @param lnum integer?
---@overload fun(record:Ozay.Bookmarks.Record)
---@overload fun(bufnr:integer, lnum:integer)
function M.remove(bufnr, lnum)
	local record
	if type(bufnr) == "table" then
		record = bufnr
		bufnr = utils.find_buf(record.file) or -1
	elseif lnum then
		record = service.find(bufnr, lnum)
	end

	if not record or not record.id then
		return
	end

	service.remove(record.id)
	if bufnr ~= -1 then
		ui.remove_one(bufnr, record.id)
	end
	utils.notify("bookmark supprimé.", vim.log.levels.INFO)
end

function M.clear_buffer(bufnr)
	ui.clear_buffer(bufnr)
end

---@param bufnr integer
---@param lnum integer
function M.toggle(bufnr, lnum)
	if M.get(bufnr, lnum) then
		M.remove(bufnr, lnum)
	else
		M.create(bufnr, lnum)
	end
end

--- Met à jour les champs fournis d'un bookmark existant et rafraîchit son extmark.
--- Sans bookmark sur la ligne, ne fait rien.
---@param bufnr integer
---@param lnum integer
---@param opts? Ozay.Bookmarks.Service.Opts
---@return Ozay.Bookmarks.Record?
function M.update(bufnr, lnum, opts)
	local existing = M.get(bufnr, lnum)
	if not existing or not opts or vim.tbl_isempty(opts) then
		return existing
	end
	service.update(existing.id, opts)
	---@type Ozay.Bookmarks.Record
	local record = M.get(bufnr, lnum)
	ui.update_one(bufnr, record)
	utils.notify("bookmark mis à jour.", vim.log.levels.INFO)
	return record
end

function M.next(bufnr)
	ui.next(bufnr)
end

function M.previous(bufnr)
	ui.previous(bufnr)
end

function M.open_note(bufnr, lnum)
	note.open(bufnr, lnum)
end

---@param opt Ozay.Bookmarks.Config.opt?
function M.setup(opt)
	config.setup(opt)
	db.setup(config.resolved_db_path())
	ui.setup_autocmds()
	require("bookmarks.trouble").register()
	require("bookmarks.commands")()
end

--- API publique : créer/consulter/retirer un bookmark sans passer par les commandes.
M.list_for_buffer = service.list_for_buffer
M.list_for_project = service.list_for_project

return M
