local config = require("plugins.bookmarks.config")
local db = require("plugins.bookmarks.db")
local service = require("plugins.bookmarks.service")
local ui = require("plugins.bookmarks.ui")

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
		require("plugins.bookmarks.snacks_picker")()
	end, { desc = "Ouvre le picker Snacks des bookmarks du projet" })
end

local function setup()
	config.setup({})
	db.setup(config.resolved_db_path())
	ui.setup_autocmds()
	require("plugins.bookmarks.trouble").register()
	create_commands()
end

local function gen_keymaps()
	return {
		{ "<leader>bb", "<cmd>BookmarkToggle<CR>", mode = "n", desc = "Bookmarks: toggle" },
		{ "<leader>ba", "<cmd>BookmarkAnnotate<CR>", mode = "n", desc = "Bookmarks: annoter" },
		{ "<leader>bl", "<cmd>Bookmarks<CR>", mode = "n", desc = "Bookmarks: liste (Trouble)" },
		{ "<leader>bp", "<cmd>BookmarkPick<CR>", mode = "n", desc = "Bookmarks: picker Snacks" },
		{ "]b", "<cmd>BookmarkNext<CR>", mode = "n", desc = "Bookmark suivant" },
		{ "[b", "<cmd>BookmarkPrev<CR>", mode = "n", desc = "Bookmark précédent" },
		{ "<leader>bx", "<cmd>BookmarkClear<CR>", mode = "n", desc = "Bookmarks: vider le fichier" },
	}
end

---@type LazySpec
return {
	dir = "~",
	dependencies = {
		"neozay/trouble.nvim",
		"kkharji/sqlite.lua",
	},
	lazy = false,
	config = setup,
	cmd = {
		"Bookmarks",
		"BookmarkToggle",
		"BookmarkAdd",
		"BookmarkAnnotate",
		"BookmarkNext",
		"BookmarkPrev",
		"BookmarkClear",
		"BookmarkPick",
	},
	keys = gen_keymaps(),
}
