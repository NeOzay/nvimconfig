local _git_types = { "Add", "Change", "Delete", "Topdelete", "Changedelete", "Untracked" }

local function setup_hl()
	local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
	vim.api.nvim_set_hl(0, "CursorLineFold", { fg = normal.fg, bg = normal.bg })
end

local function get_git_hl(bufnr, lnum, is_cursor)
	local ok, gitsigns = pcall(require, "gitsigns")
	if not ok then
		return
	end

	local hunks = gitsigns.get_hunks(bufnr)
	if not hunks then
		return
	end

	for _, hunk in ipairs(hunks) do
		local start, count = hunk.added.start, math.max(hunk.added.count, 1)
		if lnum >= start and lnum < start + count then
			local prefix = is_cursor and "CursorLineFoldGit" or "FoldGit"
			return prefix .. hunk.type:gsub("^%l", string.upper)
		end
	end
end

local function fold_with_git(args)
	local fold_text = require("statuscol.builtin").foldfunc(args)
	local hl = get_git_hl(args.buf, args.lnum, args.lnum == vim.fn.line("."))

	if hl then
		local clean = fold_text:gsub("%%#[^#]*#", ""):gsub("%%%*", "")
		return "%#" .. hl .. "#" .. clean
	end
	return fold_text
end

---============================================================================
--- Gestion des clics DAP dans la colonne de statut
---============================================================================
---
--- Fonctionnalités:
--- - Clic gauche: Toggle breakpoint (ajouter/supprimer)
--- - Clic droit: Activer/désactiver un breakpoint existant
---
--- Les breakpoints désactivés sont stockés dans _G.DapDisabledBreakpoints
--- et persistés via dap.lua entre les sessions.
---
--- Structure: { [filepath]: { [line_str]: opts } }

--- Variable globale partagée avec dap.lua pour la persistance
---@type table<string, table<string, DapBreakpointOpts>>
_G.DapDisabledBreakpoints = _G.DapDisabledBreakpoints or {}

--- Récupère les options d'un breakpoint désactivé.
---@param filepath string Chemin absolu du fichier
---@param line number Numéro de ligne
---@return DapBreakpointOpts|nil opts Options du breakpoint ou nil si non trouvé
local function get_disabled_bp(filepath, line)
	local file_bps = _G.DapDisabledBreakpoints[filepath]
	return file_bps and file_bps[tostring(line)]
end

--- Enregistre un breakpoint comme désactivé.
---@param filepath string Chemin absolu du fichier
---@param line number Numéro de ligne
---@param opts DapBreakpointOpts Options du breakpoint à sauvegarder
local function set_disabled_bp(filepath, line, opts)
	_G.DapDisabledBreakpoints[filepath] = _G.DapDisabledBreakpoints[filepath] or {}
	_G.DapDisabledBreakpoints[filepath][tostring(line)] = opts
end

--- Supprime un breakpoint de la liste des désactivés.
--- Nettoie l'entrée du fichier si elle devient vide.
---@param filepath string Chemin absolu du fichier
---@param line number Numéro de ligne
local function remove_disabled_bp(filepath, line)
	local file_bps = _G.DapDisabledBreakpoints[filepath]
	if file_bps then
		file_bps[tostring(line)] = nil
		if vim.tbl_isempty(file_bps) then
			_G.DapDisabledBreakpoints[filepath] = nil
		end
	end
end

--- Recherche un breakpoint actif à une ligne donnée.
---@param breakpoints table Module dap.breakpoints
---@param bufnr number Numéro du buffer
---@param line number Numéro de ligne
---@return table|nil bp Le breakpoint trouvé ou nil
local function get_bp_at_line(breakpoints, bufnr, line)
	local bps = breakpoints.get(bufnr)[bufnr] or {}
	for _, bp in ipairs(bps) do
		if bp.line == line then
			return bp
		end
	end
	return nil
end

--- Handler de clic pour la colonne DAP dans statuscol.
--- Appelé via "v:lua.DapClickHandler" dans la config statuscol.
---
--- Actions:
--- - Clic gauche (button="l"): Toggle breakpoint, supprime l'état désactivé si présent
--- - Clic droit (button="r"):
---   - Sur breakpoint désactivé: Le réactive
---   - Sur breakpoint actif: Le désactive (supprime + stocke options)
---   - Sur ligne vide: Crée un nouveau breakpoint
---
---@param minwid number ID du widget (non utilisé)
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

	-- Positionner le curseur sur la ligne cliquée (requis par dap.set_breakpoint)
	vim.api.nvim_set_current_win(pos.winid)
	vim.api.nvim_win_set_cursor(pos.winid, { line, 0 })

	local disabled_opts = get_disabled_bp(filepath, line)

	if button == "l" then
		-- Clic gauche: toggle breakpoint
		if disabled_opts then
			-- Supprimer d'abord le signe désactivé
			vim.fn.sign_unplace("dap_disabled", { buffer = bufnr, lnum = line })
			remove_disabled_bp(filepath, line)
		end
		dap.toggle_breakpoint()
	elseif button == "r" then
		-- Clic droit: activer/désactiver
		local bp = get_bp_at_line(breakpoints, bufnr, line)

		if disabled_opts then
			-- Réactiver: restaurer le breakpoint avec ses options d'origine
			vim.fn.sign_unplace("dap_disabled", { buffer = bufnr, lnum = line })
			dap.set_breakpoint(disabled_opts.condition, disabled_opts.hit_condition, disabled_opts.log_message)
			remove_disabled_bp(filepath, line)
		elseif bp then
			-- Désactiver: sauvegarder les options et supprimer le breakpoint
			set_disabled_bp(filepath, line, {
				condition = bp.condition,
				hit_condition = bp.hitCondition,
				log_message = bp.logMessage,
			})
			breakpoints.remove(bufnr, line)
			-- Afficher le signe "désactivé" (cercle vide gris)
			vim.fn.sign_place(0, "dap_disabled", "DapBreakpointRejected", bufnr, { lnum = line, priority = 11 })
		else
			-- Aucun breakpoint: en créer un nouveau
			dap.toggle_breakpoint()
		end
	end
end

---@type LazySpec
return {
	"luukvbaal/statuscol.nvim",
	-- enabled = false,
	event = "User FilePost",
	config = function(_, opts)
		setup_hl()
		vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_hl })
		require("statuscol").setup(opts)
	end,
	opts = function()
		local builtin = require("statuscol.builtin")
		return {
			relculright = true,
			segments = {
				-- Signes DAP (breakpoints)
				{
					sign = {
						name = { "Dap.*" },
						maxwidth = 1,
						colwidth = 2,
						auto = false,
					},
					click = "v:lua.DapClickHandler",
				},
				{ text = { builtin.lnumfunc } }, --click = "v:lua.ScLa" },
				{ text = { " ", fold_with_git }, click = "v:lua.ScFa" },
			},
		}
	end,
}
