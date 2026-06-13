local M = {}

local DapDisabledBreakpoints = require("shared_data").DapDisabledBreakpoints
local disabled_ns = require("shared_data").disabled_ns

--- Force le recalcul de la largeur `auto` des colonnes de signs. Sans ca, la
--- colonne dap reste reservee apres le retrait du dernier breakpoint : sa
--- largeur n'est recalculee (statuscol -> update_callargs) qu'au prochain redraw
--- COMPLET de la statuscolumn. Retirer un breakpoint ne redessine que la ligne
--- touchee, donc les autres lignes gardent l'ancienne largeur.
---@param win integer
local function refresh_statuscolumn(win)
	vim.schedule(function()
		if not vim.api.nvim_win_is_valid(win) then
			return
		end
		if not pcall(vim.api.nvim__redraw, { win = win, statuscolumn = true }) then
			vim.cmd("redraw!")
		end
	end)
end

--- Place un extmark pour representer un breakpoint desactive.
---@param bufnr integer
---@param line integer Numero de ligne (1-indexe)
local function place_disabled_sign(bufnr, line)
	vim.api.nvim_buf_set_extmark(bufnr, disabled_ns, line - 1, 0, {
		sign_text = "○",
		sign_hl_group = "DapBreakpointRejected",
		priority = 11,
	})
end

--- Supprime l'extmark de breakpoint desactive a une ligne donnee.
---@param bufnr integer
---@param line integer Numero de ligne (1-indexe)
local function unplace_disabled_sign(bufnr, line)
	local marks = vim.api.nvim_buf_get_extmarks(bufnr, disabled_ns, { line - 1, 0 }, { line - 1, -1 }, {})
	for _, mark in ipairs(marks) do
		vim.api.nvim_buf_del_extmark(bufnr, disabled_ns, mark[1])
	end
end

--- Recupere les options d'un breakpoint desactive.
---@param filepath string Chemin absolu du fichier
---@param line number Numero de ligne
---@return Ozay.Dap.BreakpointOpts|nil opts Options du breakpoint ou nil si non trouve
local function get_disabled_bp(filepath, line)
	local file_bps = DapDisabledBreakpoints[filepath]
	return file_bps and file_bps[tostring(line)]
end

--- Enregistre un breakpoint comme desactive.
---@param filepath string Chemin absolu du fichier
---@param line number Numero de ligne
---@param opts Ozay.Dap.BreakpointOpts Options du breakpoint a sauvegarder
local function set_disabled_bp(filepath, line, opts)
	DapDisabledBreakpoints[filepath] = DapDisabledBreakpoints[filepath] or {}
	DapDisabledBreakpoints[filepath][tostring(line)] = opts
end

--- Supprime un breakpoint de la liste des desactives.
---@param filepath string Chemin absolu du fichier
---@param line number Numero de ligne
local function remove_disabled_bp(filepath, line)
	local file_bps = DapDisabledBreakpoints[filepath]
	if file_bps then
		file_bps[tostring(line)] = nil
		if vim.tbl_isempty(file_bps) then
			DapDisabledBreakpoints[filepath] = nil
		end
	end
end

--- Recherche un breakpoint actif a une ligne donnee.
---@param breakpoints table Module dap.breakpoints
---@param bufnr number Numero du buffer
---@param line number Numero de ligne
---@return table|nil bp Le breakpoint trouve ou nil
local function get_bp_at_line(breakpoints, bufnr, line)
	local bps = breakpoints.get(bufnr)[bufnr] or {}
	for _, bp in ipairs(bps) do
		if bp.line == line then
			return bp
		end
	end
	return nil
end

-- Window + ligne du dernier clic gauche sur la colonne numero. Sert a verifier
-- que les deux clics d'un "double-clic" portent sur LA MEME ligne (et meme
-- window) : Vim incremente `clicks` pour deux clics rapproches meme sur des
-- lignes differentes, donc `clicks == 2` seul poserait un breakpoint sur la 2e
-- ligne par erreur.
local last_click = {}

--- Handler de la colonne numero : double-clic gauche (meme ligne) => toggle bp.
--- La colonne dap (`auto = true`) se replie quand vide, donc on pose le premier
--- breakpoint via la colonne numero. Le coeur statuscol a deja place curseur +
--- fenetre courante sur la ligne cliquee (get_click_args), donc toggle agit au
--- bon endroit. On filtre sur le double-clic pour eviter les poses accidentelles
--- (un simple clic sert juste a positionner le curseur).
---@param args table  -- args statuscol : { button, clicks, mousepos, ... }
function M.lnum_click(args)
	if args.button ~= "l" then
		return
	end
	local line = args.mousepos.line
	local win = args.mousepos.winid
	-- Memorise (win, ligne) au 1er clic. Un clicks==2 sur une AUTRE ligne/window
	-- (deux clics rapides distincts) ne doit pas toggler : on re-memorise et sort.
	if args.clicks ~= 2 or last_click.win ~= win or last_click.line ~= line then
		last_click.win, last_click.line = win, line
		return
	end
	last_click.win, last_click.line = nil, nil

	local dap, dap_ok = pRequire("dap")
	if not dap_ok then
		return
	end
	dap.toggle_breakpoint()
	refresh_statuscolumn(win)
end

--- Assigne le handler de clic global pour la colonne DAP.
function M.setup()
	---@param minwid number ID du widget (non utilise)
	---@param clicks number Nombre de clics
	---@param button string Type de bouton ("l"=gauche, "r"=droit, "m"=milieu)
	---@param mods string Modificateurs (ctrl, shift, etc.)
	function _G.DapClickHandler(minwid, clicks, button, mods)
		local pos = vim.fn.getmousepos()
		local line = pos.line
		local bufnr = vim.api.nvim_win_get_buf(pos.winid)
		local filepath = vim.api.nvim_buf_get_name(bufnr)

		local dap, dap_ok = pRequire("dap")
		if not dap_ok then
			return
		end

		local breakpoints, bp_ok = pRequire("dap.breakpoints")
		if not bp_ok then
			return
		end

		vim.api.nvim_set_current_win(pos.winid)
		vim.api.nvim_win_set_cursor(pos.winid, { line, 0 })

		local disabled_opts = get_disabled_bp(filepath, line)

		if button == "l" then
			if disabled_opts then
				unplace_disabled_sign(bufnr, line)
				remove_disabled_bp(filepath, line)
			end
			dap.toggle_breakpoint()
		elseif button == "r" then
			local bp = get_bp_at_line(breakpoints, bufnr, line)

			if disabled_opts then
				unplace_disabled_sign(bufnr, line)
				dap.set_breakpoint(disabled_opts.condition, disabled_opts.hit_condition, disabled_opts.log_message)
				remove_disabled_bp(filepath, line)
			elseif bp then
				set_disabled_bp(filepath, line, {
					condition = bp.condition,
					hit_condition = bp.hitCondition,
					log_message = bp.logMessage,
				})
				breakpoints.remove(bufnr, line)
				place_disabled_sign(bufnr, line)
			else
				dap.toggle_breakpoint()
			end
		end

		refresh_statuscolumn(pos.winid)
	end
end

return M
