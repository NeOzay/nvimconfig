local service = require("bookmarks.service")
local ui = require("bookmarks.ui")
local utils = require("bookmarks.utils")
local events = require("bookmarks.events")

---@class Ozay.Bookmarks.Note
local M = {}

--- Ouvre un popup flottant Snacks pré-rempli avec la note du bookmark sur bufnr/lnum.
--- Crée le bookmark s'il n'existe pas encore. Sauvegarde le texte en DB à la fermeture
--- du popup (touche, `:q`, `WinClosed`).
---@param bufnr integer
---@param lnum integer
---@param opts? { on_saved?: fun() } on_saved rappelé après la sauvegarde (ex: rafraîchir un picker/Trouble appelant)
function M.open(bufnr, lnum, opts)
	local bookmarks = require("bookmarks")

	opts = opts or {}
	local record = bookmarks.get_or_create(bufnr, lnum)
	if not record then
		-- cas normal, pas une erreur de programmation : buffer sans nom ou `buftype` non vide
		-- (terminal, quickfix…) — `service.skip_buf` refuse d'y poser un bookmark.
		utils.notify("impossible de créer le bookmark sur ce buffer.", vim.log.levels.WARN)
		return
	end

	local record_id = record.id
	local text = record.note or ""

	local win = Snacks.win.new({
		text = vim.split(text, "\n", { plain = true }),
		enter = true,
		ft = "markdown",
		border = "rounded",
		title = " Note bookmark ",
		title_pos = "center",
		width = 0.5,
		height = 0.4,
		zindex = Snacks.win.zindex(),
		wo = { wrap = true, spell = true },
		on_buf = function(self)
			vim.api.nvim_create_autocmd("BufEnter", {
				callback = function()
					vim.cmd("stopinsert")
				end,
				once = true,
				buf = self.buf,
			})
		end,
		on_close = function(self)
			local lines = vim.api.nvim_buf_get_lines(self.buf, 0, -1, false)
			local note = (table.concat(lines, "\n"):gsub("%s+$", ""))
			-- écriture par id : la ligne a pu bouger pendant l'édition du popup, une
			-- recherche par (bufnr, lnum) ne retrouverait plus le bon bookmark.
			service.update(record_id, { note = note })
			record.note = note
			ui.update_one(bufnr, record)
			events.emit(events.UPDATE, record)
			if opts.on_saved then
				opts.on_saved()
			end
		end,
	})
end

--- Charge le buffer du fichier concerné (bufadd/bufload) puis ouvre la note du bookmark.
--- Utile depuis un contexte externe au buffer courant (picker, Trouble) où l'on ne dispose
--- que du record, pas d'un bufnr déjà chargé.
---@param record Ozay.Bookmarks.Record
---@param opts? { on_saved?: fun() }
function M.open_for_record(record, opts)
	local bufnr = vim.fn.bufadd(record.file)
	vim.fn.bufload(bufnr)
	M.open(bufnr, record.lnum, opts)
end

return M
