local service = require("bookmarks.service")
local ui = require("bookmarks.ui")

---@class Ozay.Bookmarks.Note
local M = {}

--- Ouvre un popup flottant Snacks pré-rempli avec la note du bookmark sur bufnr/lnum.
--- Crée le bookmark s'il n'existe pas encore. Sauvegarde le texte en DB à la fermeture
--- du popup (touche, `:q`, `WinClosed`).
---@param bufnr integer
---@param lnum integer
---@param opts? { on_saved?: fun() } on_saved rappelé après la sauvegarde (ex: rafraîchir un picker/Trouble appelant)
function M.open(bufnr, lnum, opts)
	opts = opts or {}
	local record = service.find(bufnr, lnum)
	if not record then
		record = service.add(bufnr, lnum)
		if not record then
			vim.notify("impossible de créer le bookmark.", vim.log.levels.ERROR, { title = "bookmarks.nvim" })
			return
		end
		ui.render_one(bufnr, record)
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
			service.set_note(record_id, note)
			record.note = note
			ui.update_one(bufnr, record)
			if opts.on_saved then
				opts.on_saved()
			end
		end,
	})
end

return M
