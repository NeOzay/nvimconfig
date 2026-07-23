local autocmd = vim.api.nvim_create_autocmd

-- -- Auto-start treesitter on every filetype
-- autocmd("FileType", {
-- 	pattern = "*",
-- 	callback = function()
-- 		pcall(vim.treesitter.start)
-- 	end,
-- })

Userautocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.breakindent = true
	end,
})

-- Harpoon charge ses données depuis sha256(startup_cwd).json une seule fois.
-- Après tout changement de cwd (dashboard, persistence, :cd…), on force la
-- relecture depuis le JSON du nouveau projet pour éviter l'écrasement des harpons.
autocmd("DirChanged", {
	group = vim.api.nvim_create_augroup("HarpoonReloadOnCwd", { clear = true }),
	callback = function()
		local h = pRequire("harpoon")
		if not h then
			return
		end
		h.data = require("harpoon.data").Data:new(h.config)
		h.lists = {}
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

local function refresh_diagnostics()
	vim.lsp.buf.workspace_diagnostics()
end

local function refresh_current_buf()
	local bufnr = vim.api.nvim_get_current_buf()
	if vim.api.nvim_buf_is_loaded(bufnr) then
		refresh_diagnostics()
	end
end

local diag_timer = nil

local function debounced_refresh()
	if diag_timer then
		diag_timer:stop()
	end
	diag_timer = vim.defer_fn(refresh_current_buf, 500)
end

-- Rafraîchir les diagnostics 300ms après la dernière modification
Userautocmd({ "TextChanged", "TextChangedI" }, {
	callback = debounced_refresh,
})

-- Rafraîchir les diagnostics après sauvegarde du buffer courant
Userautocmd("BufWritePost", {
	callback = function()
		vim.defer_fn(refresh_current_buf, 300)
	end,
})

-- Rafraîchir les diagnostics en quittant le mode insertion
Userautocmd("InsertLeave", {
	callback = function()
		vim.defer_fn(refresh_current_buf, 100)
	end,
})

-- Rafraîchir les diagnostics lors de l'entrée dans un buffer
Userautocmd("BufEnter", {
	callback = function()
		vim.defer_fn(refresh_current_buf, 300)
	end,
})

-- Cache indépendant du vrai bufnr du terminal Claude Code, capturé à sa
-- création (TermOpen), avant toute manipulation via Ctrl+G. Indispensable :
-- `claudecode.terminal.get_active_terminal_bufnr()` devient non fiable après
-- édition du prompt (voir autocmd QuitPre ci-dessous).
---@type integer?
local claude_terminal_bufnr = nil

Userautocmd("TermOpen", {
	callback = function(args)
		if vim.api.nvim_buf_get_name(args.buf):match("claude") then
			claude_terminal_bufnr = args.buf
		end
	end,
})

-- Filet de sécurité après édition du prompt Claude Code via Ctrl+G (relayé par
-- nvim-unception). Cause racine : `snacks_win_opts.fixbuf = false` (nécessaire
-- pour que Ctrl+G fonctionne, voir docs/plugins/claudecode.md) fait que
-- `snacks.win:fixbuf()` (snacks/win.lua) ADOPTE le buffer du prompt comme
-- étant "son" buffer terminal en permanence (`self.buf = buf`) dès qu'il
-- remplace le terminal dans la fenêtre gérée par snacks — la restauration
-- visuelle qui suit (par nvim-unception) ne répare jamais ce champ interne
-- puisqu'elle ne passe pas par l'API de snacks. Résultat : `get_active_bufnr()`
-- (donc l'auto-attache du terminal dans l'onglet diff, et `<A-c>`) continue de
-- suivre le buffer du prompt indéfiniment. On répare ce champ en accédant à
-- l'instance réelle (`_get_terminal_for_test()`, malgré son nom) directement,
-- sans passer par `set_buf()` : cette méthode fait `assert(self:valid())`, qui
-- échoue si `self.win` a fini invalide après tout le remaniement de fenêtres
-- (observé en pratique). On répare aussi `self.win` si besoin, et on corrige
-- visuellement toute fenêtre encore bloquée sur le prompt, dans tous les
-- onglets.
Userautocmd("QuitPre", {
	pattern = "*claude-prompt-*.md",
	callback = function()
		local prompt_buf = vim.api.nvim_get_current_buf()
		vim.schedule(function()
			local term_bufnr = claude_terminal_bufnr
			if
				not (term_bufnr and vim.api.nvim_buf_is_valid(term_bufnr) and vim.bo[term_bufnr].buftype == "terminal")
			then
				return
			end

			local ok, snacks_provider = pcall(require, "claudecode.terminal.snacks")
			local term_obj = ok and snacks_provider._get_terminal_for_test()
			if not term_obj then
				return
			end

			term_obj.buf = term_bufnr
			if not (term_obj.win and vim.api.nvim_win_is_valid(term_obj.win)) then
				-- Fenêtre d'origine perdue : on raccroche l'objet à n'importe
				-- quelle fenêtre affichant déjà le terminal, s'il y en a une.
				for _, t in ipairs(vim.api.nvim_list_tabpages()) do
					for _, w in ipairs(vim.api.nvim_tabpage_list_wins(t)) do
						if vim.api.nvim_win_get_buf(w) == term_bufnr then
							term_obj.win = w
						end
					end
				end
			elseif vim.api.nvim_win_get_buf(term_obj.win) ~= term_bufnr then
				vim.api.nvim_win_set_buf(term_obj.win, term_bufnr)
			end
		end)
	end,
})

-- Mettre les fichiers en lecture seule s'ils sont en dehors de l'espace de travail
Userautocmd("BufReadPost", {
	callback = function()
		local filepath = vim.fn.expand("%:p")

		-- Fichier de prompt temporaire de Claude Code (édité via Ctrl+G/$EDITOR,
		-- relayé par nvim-unception) : toujours éditable, jamais en lecture seule.
		if filepath:match("/claude%-prompt%-[^/]+%.md$") then
			return
		end
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
