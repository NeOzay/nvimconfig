local service = require("bookmarks.service")
local config = require("bookmarks.config")

local ns = vim.api.nvim_create_namespace("bookmarks.nvim")

---@class Ozay.Bookmarks.Ui
local M = {}

---@type table<integer, table<integer, integer>> bufnr -> {record_id -> extmark_id}
local extmarks_by_buf = {}

---@param bufnr integer
---@param record Ozay.Bookmarks.Record
---@return integer extmark_id
function M.render_one(bufnr, record)
	local signs = config.options.signs
	local opts = {
		sign_text = signs.icon,
		sign_hl_group = signs.hl_group,
	}
	if signs.line_hl_group and signs.line_hl_group ~= "" then
		opts.line_hl_group = signs.line_hl_group
	end

	local label = record.annotation or record.tag
	local virt_text = {} ---@type {[1]: string, [2]: string}[]

	if record.note and record.note ~= "" then
		virt_text[#virt_text + 1] = { signs.note_icon .. " ", signs.note_hl_group }
	end
	if label and label ~= "" then
		virt_text[#virt_text + 1] = { label, signs.annotation_hl_group }
	end
	if #virt_text > 0 then
		opts.virt_text = virt_text
		opts.hl_mode = "combine"
	end

	local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, ns, record.lnum - 1, 0, opts)
	extmarks_by_buf[bufnr] = extmarks_by_buf[bufnr] or {}
	extmarks_by_buf[bufnr][record.id] = extmark_id
	return extmark_id
end

--- Pose les extmarks pour tous les bookmarks connus de ce buffer. Idempotent.
---@param bufnr integer
function M.attach(bufnr)
	if service.skip_buf(bufnr) or vim.b[bufnr].bookmarks_attached then
		return
	end
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
	extmarks_by_buf[bufnr] = {}
	for _, record in ipairs(service.list_for_buffer(bufnr)) do
		M.render_one(bufnr, record)
	end
	vim.b[bufnr].bookmarks_attached = true
end

--- Resync les lnum en DB à partir de la position réelle des extmarks (les lignes ont pu bouger).
---@param bufnr integer
local function resync(bufnr)
	local marks = extmarks_by_buf[bufnr]
	if not marks then
		return
	end
	for record_id, extmark_id in pairs(marks) do
		local extmark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, extmark_id, {})
		if extmark and #extmark > 0 then
			service.set_lnum(record_id, extmark[1] + 1)
		end
	end
end

--- Configure les autocmds globaux (BufEnter/BufWritePost). À appeler une seule fois.
function M.setup_autocmds()
	local augroup = vim.api.nvim_create_augroup("bookmarks.nvim", { clear = true })
	vim.api.nvim_create_autocmd("BufEnter", {
		group = augroup,
		callback = function(ev)
			M.attach(ev.buf)
		end,
	})
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = augroup,
		callback = function(ev)
			resync(ev.buf)
		end,
	})
	vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
		group = augroup,
		callback = function(ev)
			extmarks_by_buf[ev.buf] = nil
		end,
	})
end

---@param bufnr integer
---@return Ozay.Bookmarks.Record[]
local function sorted_records(bufnr)
	local records = service.list_for_buffer(bufnr)
	table.sort(records, function(a, b)
		return a.lnum < b.lnum
	end)
	return records
end

--- Saute au bookmark suivant dans le buffer.
---@param bufnr integer
function M.next(bufnr)
	local cur = vim.api.nvim_win_get_cursor(0)[1]
	for _, record in ipairs(sorted_records(bufnr)) do
		if record.lnum > cur then
			vim.api.nvim_win_set_cursor(0, { record.lnum, 0 })
			return
		end
	end
end

--- Saute au bookmark précédent dans le buffer.
---@param bufnr integer
function M.previous(bufnr)
	local cur = vim.api.nvim_win_get_cursor(0)[1]
	local records = sorted_records(bufnr)
	for i = #records, 1, -1 do
		if records[i].lnum < cur then
			vim.api.nvim_win_set_cursor(0, { records[i].lnum, 0 })
			return
		end
	end
end

--- Supprime tous les bookmarks (et leurs extmarks) du buffer courant.
---@param bufnr integer
function M.clear_buffer(bufnr)
	service.clear_buffer(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
	extmarks_by_buf[bufnr] = {}
end

--- Retire un extmark précis (utilisé par le toggle après suppression en DB).
---@param bufnr integer
---@param record_id integer
function M.remove_one(bufnr, record_id)
	local marks = extmarks_by_buf[bufnr]
	local extmark_id = marks and marks[record_id]
	if extmark_id then
		vim.api.nvim_buf_del_extmark(bufnr, ns, extmark_id)
		marks[record_id] = nil
	end
end

--- Ré-affiche un bookmark existant (ex: après modification de son annotation).
---@param bufnr integer
---@param record Ozay.Bookmarks.Record
function M.update_one(bufnr, record)
	M.remove_one(bufnr, record.id)
	M.render_one(bufnr, record)
end

return M
