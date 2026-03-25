local autocmd = vim.api.nvim_create_autocmd

-- Event "User FilePost" — emitted after UIEnter + file buffer opened
autocmd({ "UIEnter", "BufReadPost", "BufNewFile" }, {
	group = vim.api.nvim_create_augroup("NvFilePost", { clear = true }),
	callback = function(args)
		local file = vim.api.nvim_buf_get_name(args.buf)
		local buftype = vim.api.nvim_get_option_value("buftype", { buf = args.buf })

		if not vim.g.ui_entered and args.event == "UIEnter" then
			vim.g.ui_entered = true
		end

		if file ~= "" and buftype ~= "nofile" and vim.g.ui_entered then
			vim.api.nvim_exec_autocmds("User", { pattern = "FilePost", modeline = false })
			vim.api.nvim_del_augroup_by_name("NvFilePost")

			vim.schedule(function()
				vim.api.nvim_exec_autocmds("FileType", {})
				if vim.g.editorconfig then
					require("editorconfig").config(args.buf)
				end
			end)
		end
	end,
})

-- Auto-start treesitter on every filetype
autocmd("FileType", {
	pattern = "*",
	callback = function()
		pcall(vim.treesitter.start)
	end,
})

-- TSInstallAll command
vim.api.nvim_create_user_command("TSInstallAll", function()
	local spec = require("lazy.core.config").plugins["nvim-treesitter"]
	local opts = type(spec.opts) == "table" and spec.opts or {}
	require("nvim-treesitter").install(opts.ensure_installed)
end, {})

-- Auto signature help on trigger characters
autocmd("LspAttach", {
	callback = function(args)
		vim.schedule(function()
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			if client then
				local signatureProvider = client.server_capabilities.signatureHelpProvider
				if signatureProvider and signatureProvider.triggerCharacters then
					require("lsp.signature").setup(client, args.buf)
				end
			end
		end)
	end,
})

Userautocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.breakindent = true
	end,
})

-- Recharger lualine automatiquement à la sauvegarde de lualine-conf.lua
Userautocmd("BufWritePost", {
	pattern = vim.fn.stdpath("config") .. "/lua/lualine-conf.lua",
	callback = function()
		vim.cmd("LualineReload")
	end,
})

-- Variable pour suivre si le diagnostic a déjà été affiché à la position actuelle
local diagnostic_shown_at = { buf = -1, line = -1, col = -1 }

-- Afficher les diagnostics flottants après un court délai lorsque le curseur reste en place
Userautocmd("CursorHold", {
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
})

-- Réinitialiser le flag quand le curseur bouge
Userautocmd("CursorMoved", {
	callback = function()
		diagnostic_shown_at = { buf = -1, line = -1, col = -1 }
	end,
})

local function refresh_diagnostics(bufnr)
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

-- Rafraîchir les diagnostics de tous les buffers ouverts après sauvegarde
Userautocmd("BufWritePost", {
	callback = function()
		-- Petit délai pour laisser le LSP traiter le fichier sauvegardé
		vim.defer_fn(function()
			-- Rafraîchir les diagnostics pour tous les buffers chargés
			for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_loaded(bufnr) then
					-- Demander les diagnostics pour ce buffer
					refresh_diagnostics(bufnr)
				end
			end
		end, 500) -- 500ms de délai
	end,
})

-- Rafraîchir les diagnostics lors de l'entrée dans un buffer
Userautocmd("BufEnter", {
	callback = function()
		vim.defer_fn(function()
			local bufnr = vim.api.nvim_get_current_buf()
			if not vim.api.nvim_buf_is_loaded(bufnr) then
				return
			end
			refresh_diagnostics(bufnr)
		end, 500)
	end,
})

-- Mettre les fichiers en lecture seule s'ils sont en dehors de l'espace de travail
Userautocmd("BufReadPost", {
	callback = function()
		local filepath = vim.fn.expand("%:p")
		local cwd = vim.fn.getcwd()
		local args = vim.v.argv

		-- Vérifier si le fichier a été ouvert explicitement via la ligne de commande
		local opened_explicitly = false
		for i = 1, #args do
			if args[i] == filepath then
				opened_explicitly = true
				break
			end
		end

		if opened_explicitly or vim.startswith(filepath, vim.fn.stdpath("data") .. "/scratch") then
			return
		end

		-- Vérifier si le fichier est en dehors du répertoire de travail
		if not vim.startswith(filepath, cwd) then
			vim.bo.readonly = true
			vim.bo.modifiable = false
		end
	end,
})
