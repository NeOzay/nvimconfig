require("nvchad.autocmds")
local utils = require("utils")
vim.o.updatetime = 250

local UserAutocmds = vim.api.nvim_create_augroup("UserAutocmds", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

-- Variable pour suivre si le diagnostic a déjà été affiché à la position actuelle
local diagnostic_shown_at = { buf = -1, line = -1, col = -1 }

-- Afficher les diagnostics flottants après un court délai lorsque le curseur reste en place
autocmd("CursorHold", {
	callback = function()
		local cursor = vim.api.nvim_win_get_cursor(0)
		local bufnr = vim.api.nvim_get_current_buf()
		local line = cursor[1]
		local col = cursor[2]

		-- N'afficher le diagnostic que si on n'a pas déjà affiché à cette position
		if diagnostic_shown_at.buf ~= bufnr or diagnostic_shown_at.line ~= line or diagnostic_shown_at.col ~= col then
			vim.diagnostic.open_float({
				scope = "cursor",
			}, { focus = false })

			-- Marquer cette position comme affichée
			diagnostic_shown_at.buf = bufnr
			diagnostic_shown_at.line = line
			diagnostic_shown_at.col = col
		end
	end,
	group = UserAutocmds,
})

-- Réinitialiser le flag quand le curseur bouge
autocmd("CursorMoved", {
	callback = function()
		diagnostic_shown_at = { buf = -1, line = -1, col = -1 }
	end,
	group = UserAutocmds,
})

-- Rafraîchir les diagnostics de tous les buffers ouverts après sauvegarde
autocmd("BufWritePost", {
	callback = function()
		-- Petit délai pour laisser le LSP traiter le fichier sauvegardé
		vim.defer_fn(function()
			-- Rafraîchir les diagnostics pour tous les buffers chargés
			for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_loaded(bufnr) then
					-- Demander les diagnostics pour ce buffer
					local clients = vim.lsp.get_clients({ bufnr = bufnr })
					for _, client in ipairs(clients) do
						if client:supports_method("textDocument/diagnostic") then
							vim.lsp.buf_request(
								bufnr,
								"textDocument/diagnostic",
								{ textDocument = vim.lsp.util.make_text_document_params(bufnr) },
								nil
							)
						end
					end
				end
			end
		end, 500) -- 500ms de délai
	end,
	group = UserAutocmds,
})

-- Rafraîchir les diagnostics lors de l'entrée dans un buffer
autocmd("BufEnter", {
	callback = function()
		vim.defer_fn(function()
			local bufnr = vim.api.nvim_get_current_buf()
			if not vim.api.nvim_buf_is_loaded(bufnr) then
				return
			end
			local clients = vim.lsp.get_clients({ bufnr = bufnr })
			for _, client in ipairs(clients) do
				if client:supports_method("textDocument/diagnostic") then
					vim.lsp.buf_request(
						bufnr,
						"textDocument/diagnostic",
						{ textDocument = vim.lsp.util.make_text_document_params(bufnr) },
						nil
					)
				end
			end
		end, 500)
	end,
	group = UserAutocmds,
})

-- activer les fonctionnalités de nvim-treesitter à l'ouverture d'un fichier supporté
autocmd("FileType", {
	pattern = require("nvim-treesitter").get_installed(),
	callback = function()
		-- syntax highlighting, provided by Neovim
		vim.treesitter.start()
		-- folds, provided by Neovim
		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
		-- vim.wo.foldmethod = 'expr'
		-- indentation, provided by nvim-treesitter
		vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end,
	group = UserAutocmds,
})

-- Restaurer automatiquement la session au démarrag
autocmd("VimEnter", {
	group = vim.api.nvim_create_augroup("persistence_autoload", { clear = true }),
	nested = true,
	callback = function()
		-- Ne pas restaurer si des arguments ont été passés (fichiers ouverts)
		if vim.fn.argc() == 0 and not vim.g.started_with_stdin then
			local persistence, ok = pRequire("persistence")
			if ok then
				persistence.load()
			end
		end
	end,
})

-- Mettre les fichiers en lecture seule s'ils sont en dehors de l'espace de travail
autocmd("BufReadPost", {
	callback = function()
		local filepath = vim.fn.expand("%:p")
		local cwd = vim.fn.getcwd()

		-- Vérifier si le fichier est en dehors du répertoire de travail
		if not vim.startswith(filepath, cwd) then
			vim.bo.readonly = true
			vim.bo.modifiable = false
		end
	end,
	group = UserAutocmds,
})
