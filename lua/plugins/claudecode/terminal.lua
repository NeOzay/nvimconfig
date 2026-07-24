---Provider terminal custom pour claudecode.nvim, basé sur Snacks.terminal/Snacks.win.
---
---Remplace le provider "snacks" intégré à coder/claudecode.nvim : au lieu de subir le suivi
---buf/win de snacks (fixbuf) et de le réparer après coup, ce module garde sa propre référence
---stable au buffer terminal et surveille lui-même la fenêtre qui l'affiche.
---Voir docs/plugins/claudecode.md pour le contexte complet.

---@class Ozay.ClaudeCodeTerminalProvider : ClaudeCodeTerminalProvider
---@field reset_size fun()

---@type Ozay.ClaudeCodeTerminalProvider
local M = {}

---@return boolean, Snacks?
local function get_snacks()
	return pcall(require, "snacks")
end

---@return boolean
local function is_available()
	local ok, Snacks = get_snacks()
	return ok and Snacks and Snacks.terminal ~= nil
end

---@type snacks.win?
local terminal = nil
---Référence stable au vrai buffer terminal, jamais réassignée après la création. C'est la seule
---source de vérité pour get_active_bufnr() : terminal.buf, lui, peut être temporairement
---désynchronisé pendant l'édition du prompt Ctrl+G.
---@type integer?
local term_buf = nil
---Dernière taille connue de la fenêtre, capturée juste avant un hide, réappliquée au show suivant.
---@type { width: integer, height: integer }?
local last_win_size = nil
---Taille par défaut (`snacks_win_opts.width/height` de la config), capturée à l'ouverture — cible
---de M.reset_size().
---@type { width: number, height: number }?
local default_win_size = nil
---Augroup dédié à la garde de fenêtre, indépendant du cycle de vie interne de snacks.win (qui
---recrée son propre augroup à chaque show()).
---@type integer?
local guard_augroup = nil

---Détecte le fichier de prompt temporaire de Claude Code (édition Ctrl+G via nvim-unception).
---Même pattern que l'exemption readonly dans lua/autocmds.lua.
---@param bufnr integer
---@return boolean
local function is_prompt_buf(bufnr)
	return vim.api.nvim_buf_get_name(bufnr):match("/claude%-prompt%-[^/]+%.md$") ~= nil
end

---Reconnecte terminal.win/terminal.buf à une fenêtre affichant réellement term_buf, quelle
---qu'elle soit. Nécessaire après l'édition Ctrl+G : nvim-unception restaure le terminal via
---`:split` + `:buffer term_buf` + `:wincmd x` (server_functions.lua), qui échange la fenêtre
---courante avec la *suivante* dans la liste des fenêtres — pas forcément notre `terminal.win`
---d'origine. Rescanner tous les onglets est la seule façon fiable de retrouver la bonne fenêtre.
local function reconcile_terminal_window()
	if not (term_buf and vim.api.nvim_buf_is_valid(term_buf) and terminal) then
		return
	end
	terminal.buf = term_buf
	if
		terminal.win
		and vim.api.nvim_win_is_valid(terminal.win)
		and vim.api.nvim_win_get_buf(terminal.win) == term_buf
	then
		return
	end
	for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
			if vim.api.nvim_win_get_buf(win) == term_buf then
				terminal.win = win
				return
			end
		end
	end
end

---Réagit quand un buffer étranger remplace le terminal dans sa fenêtre (ex : navigation cokeline,
---`gf`, un plugin qui réutilise la fenêtre courante) — deux approches essayées et abandonnées avant
---celle-ci : `'winfixbuf'` fait planter tout code tiers qui appelle `nvim_set_current_buf`/`:buffer`
---sans `pcall` (ex : cokeline lors d'un clic sur un onglet) ; l'éjection réactive maison
---(`nvim_win_set_buf` + `sbuffer` différé) faisait fuiter les options de fenêtre du terminal
---(`winhighlight`, `statuscolumn`) vers le buffer relogé, cause jamais élucidée avec certitude.
---Ici, on délègue à `terminal:fixbuf()`, la méthode native de `snacks.win` déjà responsable de ce
---comportement pour ses propres terminaux — en la pilotant nous-mêmes plutôt que de laisser
---`fixbuf = false` la désactiver complètement. On bascule `terminal.opts.fixbuf` à `true` juste le
---temps de l'appel, seulement si le buffer courant est étranger (ni `term_buf`, ni le prompt
---Ctrl+G), puis on le repasse à `false` — pour que `fixbuf()` reste un no-op sur `term_buf` et sur
---le prompt (qui doit pouvoir s'afficher en place). Un garde `nvim_get_current_win() ==
---terminal.win` filtre les `BufWinEnter` qui ne concernent pas notre fenêtre.
local function guard_window()
	if guard_augroup then
		return
	end
	guard_augroup = vim.api.nvim_create_augroup("ClaudeCodeTerminalGuard", { clear = true })

	vim.api.nvim_create_autocmd("BufWinEnter", {
		group = guard_augroup,
		nested = true,
		callback = function(opt)
			if
				not (terminal and terminal.win and vim.api.nvim_win_is_valid(terminal.win))
				or vim.api.nvim_get_current_win() ~= terminal.win
			then
				return
			end
			local win = terminal.win
			local buf = vim.api.nvim_win_get_buf(win)
			if not is_prompt_buf(buf) and buf ~= term_buf then
				terminal.opts.fixbuf = true
			end
			terminal:fixbuf()
			terminal.opts.fixbuf = false
			if is_prompt_buf(buf) then
				-- API directe plutôt que nvim_feedkeys("GA") : ce callback est nested = true et
				-- peut se redéclencher plusieurs fois pour le même buffer (nvim-unception fait
				-- 0argadd + argument + edit), chacun empilant ses touches dans le typeahead ; au
				-- second passage, "G"/"A" sont alors tapées en mode insert (déjà entré au premier
				-- passage) et s'insèrent littéralement comme texte. normal!/startinsert! sont
				-- idempotents : les rappeler ne réinsère rien.
				vim.defer_fn(function()
					vim.api.nvim_win_call(win, function()
						vim.cmd("normal! G")
						vim.cmd("startinsert!")
					end)
				end, 50)
			end
		end,
	})
	vim.api.nvim_create_autocmd("QuitPre", {
		group = guard_augroup,
		pattern = "*claude-prompt-*.md",
		callback = function(ev)
			local prompt_buf = ev.buf
			vim.schedule(function()
				reconcile_terminal_window()
				-- Le CLI Claude supprime ce fichier temporaire dès qu'il l'a lu ; si ce buffer
				-- reste chargé, le prochain balayage de timestamps de Neovim (retour de focus
				-- après le job terminal) tombe sur un fichier disparu et lève E211. On ne le
				-- wipe que si le quit a effectivement abouti (plus aucune fenêtre ne l'affiche) :
				-- un quit annulé (modifications non sauvegardées) laisse le buffer dans sa fenêtre.
				if
					vim.api.nvim_buf_is_valid(prompt_buf)
					and vim.api.nvim_buf_is_loaded(prompt_buf)
					and #vim.fn.win_findbuf(prompt_buf) == 0
				then
					vim.api.nvim_buf_delete(prompt_buf, { force = true })
				end
				vim.cmd.startinsert()
			end)
		end,
	})
end

---@param config ClaudeCodeTerminalConfig
---@return snacks.win.Config
local function resolve_win_opts(config)
	local win_opts = vim.tbl_deep_extend("force", {}, config.snacks_win_opts or {})
	default_win_size = { width = win_opts.width, height = win_opts.height }
	-- Indispensable pour laisser guard_window() (et non snacks) décider quoi faire d'un buffer
	-- étranger, notamment le prompt Ctrl+G qui doit pouvoir s'afficher en place sans être
	-- immédiatement swappé hors de la fenêtre par le fixbuf par défaut de snacks.
	win_opts.fixbuf = false
	if last_win_size then
		win_opts.width = last_win_size.width
		win_opts.height = last_win_size.height
	end
	return win_opts
end

---Capture la taille actuelle avant de cacher la fenêtre, pour la restaurer au prochain show().
local function capture_win_size()
	if terminal and terminal.win and vim.api.nvim_win_is_valid(terminal.win) then
		last_win_size = {
			width = vim.api.nvim_win_get_width(terminal.win),
			height = vim.api.nvim_win_get_height(terminal.win),
		}
	end
end

---Réapplique last_win_size sur l'instance existante avant un show(), pour que la géométrie
---recalculée par snacks.win (self:dim(), lue depuis self.opts à chaque show) reprenne la taille
---précédente au lieu des pourcentages par défaut.
local function apply_last_win_size()
	if terminal and last_win_size then
		terminal.opts.width = last_win_size.width
		terminal.opts.height = last_win_size.height
	end
end

---@param term snacks.win
---@param config ClaudeCodeTerminalConfig
local function setup_terminal_events(term, config)
	if config.auto_close then
		term:on("TermClose", function()
			if vim.v.event.status ~= 0 then
				vim.notify(
					"Claude exited with code " .. vim.v.event.status .. ".\nCheck for any errors.",
					vim.log.levels.ERROR
				)
			end
			terminal = nil
			term_buf = nil
			last_win_size = nil
			if guard_augroup then
				vim.api.nvim_del_augroup_by_id(guard_augroup)
				guard_augroup = nil
			end
			vim.schedule(function()
				term:close({ buf = true })
				vim.cmd.checktime()
			end)
		end, { buf = true })
	end

	term:on("BufWipeout", function()
		terminal = nil
		term_buf = nil
		last_win_size = nil
		if guard_augroup then
			vim.api.nvim_del_augroup_by_id(guard_augroup)
			guard_augroup = nil
		end
	end, { buf = true })
	-- suppression de l'autocmd BufWinEnter de Snacks pour éviter les conflits avec notre propre gestion de la fenêtre
	vim.api.nvim_clear_autocmds({
		group = term.augroup,
		event = "BufWinEnter",
	})
end

---@param _config ClaudeCodeTerminalConfig
function M.setup(_config) end

---@return boolean
function M.is_available()
	return is_available()
end

---@param cmd_string string
---@param env_table table
---@param config ClaudeCodeTerminalConfig
---@param focus boolean?
function M.open(cmd_string, env_table, config, focus)
	if not is_available() then
		vim.notify("Snacks.nvim terminal provider selected but Snacks.terminal not available.", vim.log.levels.ERROR)
		return
	end

	local utils = require("claudecode.utils")
	focus = utils.normalize_focus(focus)

	if terminal and terminal:buf_valid() then
		apply_last_win_size()
		terminal:show()
		local win = terminal.win
		if focus and win then
			vim.api.nvim_set_current_win(win)
			if config.auto_insert ~= false then
				vim.api.nvim_win_call(win, function()
					vim.cmd("startinsert")
				end)
			end
		end
		return
	end

	local should_insert = focus and config.auto_insert ~= false
	---@type snacks.terminal.Opts
	local opts = {
		env = env_table,
		cwd = config.cwd,
		start_insert = should_insert,
		auto_insert = should_insert,
		auto_close = false,
		win = resolve_win_opts(config),
	}

	local _, Snacks = get_snacks()
	assert(Snacks, "is_available() vient de confirmer que snacks est chargeable")
	local cmd = utils.parse_command(cmd_string)
	local term_instance = Snacks.terminal.open(cmd, opts)
	if term_instance and term_instance:buf_valid() then
		terminal = term_instance
		term_buf = term_instance.buf
		setup_terminal_events(term_instance, config)
		guard_window()
	else
		terminal = nil
		term_buf = nil
		vim.notify("Failed to open Claude terminal using Snacks.", vim.log.levels.ERROR)
	end
end

function M.close()
	if terminal and terminal:buf_valid() then
		terminal:close()
	end
end

---@param cmd_string string
---@param env_table table
---@param config ClaudeCodeTerminalConfig
function M.simple_toggle(cmd_string, env_table, config)
	if not is_available() then
		vim.notify("Snacks.nvim terminal provider selected but Snacks.terminal not available.", vim.log.levels.ERROR)
		return
	end

	if terminal and terminal:buf_valid() then
		if terminal:valid() then
			capture_win_size()
			terminal:hide()
		else
			apply_last_win_size()
			terminal:show()
		end
	else
		M.open(cmd_string, env_table, config)
	end
end

---@param cmd_string string
---@param env_table table
---@param config ClaudeCodeTerminalConfig
function M.focus_toggle(cmd_string, env_table, config)
	if not is_available() then
		vim.notify("Snacks.nvim terminal provider selected but Snacks.terminal not available.", vim.log.levels.ERROR)
		return
	end

	if not (terminal and terminal:buf_valid()) then
		M.open(cmd_string, env_table, config)
		return
	end

	local win = terminal.win
	if not terminal:valid() then
		apply_last_win_size()
		terminal:show()
	elseif win and win == vim.api.nvim_get_current_win() then
		capture_win_size()
		terminal:hide()
	elseif win then
		vim.api.nvim_set_current_win(win)
		if config.auto_insert ~= false then
			vim.api.nvim_win_call(win, function()
				vim.cmd("startinsert")
			end)
		end
	end
end

---Réinitialise la taille du terminal à `snacks_win_opts.width/height` (efface la taille manuelle
---persistée) et redessine la fenêtre immédiatement si elle est visible — sinon la taille par
---défaut sera simplement appliquée au prochain `show()`.
function M.reset_size()
	last_win_size = nil
	if not (terminal and default_win_size) then
		return
	end
	terminal.opts.width = default_win_size.width
	terminal.opts.height = default_win_size.height
	if terminal.win and vim.api.nvim_win_is_valid(terminal.win) then
		local vertical = terminal.opts.position == "left" or terminal.opts.position == "right"
		local dim = terminal:dim()
		local size = vertical and dim.width or dim.height
		vim.api.nvim_win_call(terminal.win, function()
			vim.cmd((vertical and "vertical resize " or "resize ") .. size)
		end)
	end
end

---@return integer?
function M.get_active_bufnr()
	if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
		return term_buf
	end
	return nil
end

---For testing/debug purposes.
---@return snacks.win?
function M._get_terminal_for_test()
	return terminal
end

return M
