local config = require("bookmarks.config")
local db = require("bookmarks.db")
local service = require("bookmarks.service")
local ui = require("bookmarks.ui")
local note = require("bookmarks.note")

local function create_commands()
	vim.api.nvim_create_user_command("Bookmarks", function()
		require("trouble").open({ mode = "bookmarks" })
	end, { desc = "Ouvre la liste des bookmarks du projet (Trouble)" })

	vim.api.nvim_create_user_command("BookmarkToggle", function()
		local bufnr = vim.api.nvim_get_current_buf()
		local lnum = vim.api.nvim_win_get_cursor(0)[1]
		local existing = service.find(bufnr, lnum)
		if existing then
			service.remove(existing.id)
			ui.remove_one(bufnr, existing.id)
			vim.notify("bookmark supprimé.", vim.log.levels.INFO, { title = "bookmarks.nvim" })
		else
			local record = service.add(bufnr, lnum)
			if record then
				ui.render_one(bufnr, record)
				vim.notify("bookmark ajouté.", vim.log.levels.INFO, { title = "bookmarks.nvim" })
			end
		end
	end, { desc = "Ajoute/retire un bookmark sur la ligne courante" })

	vim.api.nvim_create_user_command("BookmarkAdd", function(cmd_opts)
		local bufnr = vim.api.nvim_get_current_buf()
		local lnum = vim.api.nvim_win_get_cursor(0)[1]
		local annotation = vim.fn.input({ prompt = "Annotation: ", cancelreturn = "" })
		if annotation == "" then
			vim.notify("annotation vide, annulé.", vim.log.levels.INFO, { title = "bookmarks.nvim" })
			return
		end
		local tag = cmd_opts.args ~= "" and cmd_opts.args or nil
		local record = service.add(bufnr, lnum, { annotation = annotation, tag = tag })
		if record then
			ui.render_one(bufnr, record)
		end
	end, { desc = "Ajoute un bookmark avec annotation", nargs = "?" })

	vim.api.nvim_create_user_command("BookmarkAnnotate", function()
		local bufnr = vim.api.nvim_get_current_buf()
		local lnum = vim.api.nvim_win_get_cursor(0)[1]
		local existing = service.find(bufnr, lnum)
		local annotation = vim.fn.input({
			prompt = "Annotation: ",
			default = existing and existing.annotation or "",
			cancelreturn = "",
		})
		if annotation == "" then
			vim.notify("annulé, aucun changement.", vim.log.levels.INFO, { title = "bookmarks.nvim" })
			return
		end
		if existing then
			service.set_annotation(existing.id, annotation, existing.tag)
			existing.annotation = annotation
			ui.update_one(bufnr, existing)
		else
			local record = service.add(bufnr, lnum, { annotation = annotation })
			if record then
				ui.render_one(bufnr, record)
			end
		end
	end, { desc = "Édite l'annotation du bookmark sur la ligne courante" })

	vim.api.nvim_create_user_command("BookmarkNext", function()
		ui.next(vim.api.nvim_get_current_buf())
	end, { desc = "Bookmark suivant dans le buffer" })

	vim.api.nvim_create_user_command("BookmarkPrev", function()
		ui.previous(vim.api.nvim_get_current_buf())
	end, { desc = "Bookmark précédent dans le buffer" })

	vim.api.nvim_create_user_command("BookmarkClear", function()
		ui.clear_buffer(vim.api.nvim_get_current_buf())
		vim.notify("bookmarks du fichier supprimés.", vim.log.levels.INFO, { title = "bookmarks.nvim" })
	end, { desc = "Supprime tous les bookmarks du fichier courant" })

	vim.api.nvim_create_user_command("BookmarkPick", function()
		require("bookmarks.snacks_picker")()
	end, { desc = "Ouvre le picker Snacks des bookmarks du projet" })

	vim.api.nvim_create_user_command("BookmarkNote", function()
		local bufnr = vim.api.nvim_get_current_buf()
		local lnum = vim.api.nvim_win_get_cursor(0)[1]
		note.open(bufnr, lnum)
	end, { desc = "Ouvre le popup de note du bookmark sur la ligne courante" })
end

---@class Ozay.Bookmarks
local M = {}

---@param opt Ozay.Bookmarks.Config.opt?
function M.setup(opt)
	config.setup(opt)
	db.setup(config.resolved_db_path())
	ui.setup_autocmds()
	require("bookmarks.trouble").register()
	create_commands()
end

return M
