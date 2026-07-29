local function create_commands()
	local bookmarks = require("bookmarks")
	local utils = require("bookmarks.utils")
	--- Buffer et ligne sous le curseur, dans la fenêtre courante.
	---@return integer bufnr
	---@return integer lnum
	local function cursor_pos()
		return vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_cursor(0)[1]
	end

	vim.api.nvim_create_user_command("Bookmarks", function()
		require("trouble").open({ mode = "bookmarks" })
	end, { desc = "Ouvre la liste des bookmarks du projet (Trouble)" })

	vim.api.nvim_create_user_command("BookmarkToggle", function()
		bookmarks.toggle(cursor_pos())
	end, { desc = "Ajoute/retire un bookmark sur la ligne courante" })

	vim.api.nvim_create_user_command("BookmarkAdd", function(cmd_opts)
		local bufnr, lnum = cursor_pos()
		local annotation = cmd_opts.args ~= "" and cmd_opts.args or nil
		bookmarks.create(bufnr, lnum, { annotation = annotation })
	end, { desc = "Ajoute un bookmark, l'argument servant d'annotation", nargs = "?" })

	--- Sentinelle de `vim.fn.input` : distingue l'annulation (Échap) d'une saisie vide,
	--- qui vaut effacement explicite de l'annotation.
	local CANCEL = "\1bookmark-cancel"

	vim.api.nvim_create_user_command("BookmarkAnnotate", function()
		local bufnr, lnum = cursor_pos()
		-- le prompt vient avant toute création : annuler ne doit laisser aucun résidu.
		local existing = bookmarks.get(bufnr, lnum)
		local annotation = vim.fn.input({
			prompt = "Annotation: ",
			default = existing and existing.annotation or "",
			cancelreturn = CANCEL,
		})
		if annotation == CANCEL then
			utils.notify("annulé, aucun changement.", vim.log.levels.INFO)
			return
		end
		-- `""` et non `nil` : `db.update` boucle sur `pairs` et ignore les valeurs `nil`,
		-- une annotation ne pourrait jamais être effacée autrement.
		bookmarks.create(bufnr, lnum, { annotation = annotation })
	end, { desc = "Édite l'annotation du bookmark sur la ligne courante" })

	vim.api.nvim_create_user_command("BookmarkNext", function()
		bookmarks.next(vim.api.nvim_get_current_buf())
	end, { desc = "Bookmark suivant dans le buffer" })

	vim.api.nvim_create_user_command("BookmarkPrev", function()
		bookmarks.previous(vim.api.nvim_get_current_buf())
	end, { desc = "Bookmark précédent dans le buffer" })

	vim.api.nvim_create_user_command("BookmarkClear", function()
		bookmarks.clear_buffer(vim.api.nvim_get_current_buf())
		utils.notify("bookmarks du fichier supprimés.", vim.log.levels.INFO)
	end, { desc = "Supprime tous les bookmarks du fichier courant" })

	vim.api.nvim_create_user_command("BookmarkPick", function()
		require("bookmarks.snacks_picker")()
	end, { desc = "Ouvre le picker Snacks des bookmarks du projet" })

	vim.api.nvim_create_user_command("BookmarkNote", function()
		bookmarks.open_note(cursor_pos())
	end, { desc = "Ouvre le popup de note du bookmark sur la ligne courante" })
end

return create_commands
