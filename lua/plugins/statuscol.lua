local DapDisabledBreakpoints = require("shared_data").DapDisabledBreakpoints
local disabled_ns = require("shared_data").disabled_ns

--- Place un extmark pour représenter un breakpoint désactivé.
---@param bufnr integer
---@param line integer Numéro de ligne (1-indexé)
local function place_disabled_sign(bufnr, line)
	vim.api.nvim_buf_set_extmark(bufnr, disabled_ns, line - 1, 0, {
		sign_text = "○",
		sign_hl_group = "DapBreakpointRejected",
		priority = 11,
	})
end

--- Supprime l'extmark de breakpoint désactivé à une ligne donnée.
---@param bufnr integer
---@param line integer Numéro de ligne (1-indexé)
local function unplace_disabled_sign(bufnr, line)
	local marks = vim.api.nvim_buf_get_extmarks(bufnr, disabled_ns, { line - 1, 0 }, { line - 1, -1 }, {})
	for _, mark in ipairs(marks) do
		vim.api.nvim_buf_del_extmark(bufnr, disabled_ns, mark[1])
	end
end

local _git_types = { "Add", "Change", "Delete", "Topdelete", "Changedelete", "Untracked" }

local function setup_hl()
	local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
	vim.api.nvim_set_hl(0, "CursorLineFold", { fg = normal.fg, bg = normal.bg })
end

local function get_git_hl(bufnr, lnum, is_cursor)
	local gitsigns, ok = pRequire("gitsigns")
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

--- Récupère les options d'un breakpoint désactivé.
---@param filepath string Chemin absolu du fichier
---@param line number Numéro de ligne
---@return Ozay.Dap.BreakpointOpts|nil opts Options du breakpoint ou nil si non trouvé
local function get_disabled_bp(filepath, line)
	local file_bps = DapDisabledBreakpoints[filepath]
	return file_bps and file_bps[tostring(line)]
end

--- Enregistre un breakpoint comme désactivé.
---@param filepath string Chemin absolu du fichier
---@param line number Numéro de ligne
---@param opts Ozay.Dap.BreakpointOpts Options du breakpoint à sauvegarder
local function set_disabled_bp(filepath, line, opts)
	DapDisabledBreakpoints[filepath] = DapDisabledBreakpoints[filepath] or {}
	DapDisabledBreakpoints[filepath][tostring(line)] = opts
end

--- Supprime un breakpoint de la liste des désactivés.
--- Nettoie l'entrée du fichier si elle devient vide.
---@param filepath string Chemin absolu du fichier
---@param line number Numéro de ligne
local function remove_disabled_bp(filepath, line)
	local file_bps = DapDisabledBreakpoints[filepath]
	if file_bps then
		file_bps[tostring(line)] = nil
		if vim.tbl_isempty(file_bps) then
			DapDisabledBreakpoints[filepath] = nil
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
			unplace_disabled_sign(bufnr, line)
			remove_disabled_bp(filepath, line)
		end
		dap.toggle_breakpoint()
	elseif button == "r" then
		-- Clic droit: activer/désactiver
		local bp = get_bp_at_line(breakpoints, bufnr, line)

		if disabled_opts then
			-- Réactiver: restaurer le breakpoint avec ses options d'origine
			unplace_disabled_sign(bufnr, line)
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
			-- Afficher l'extmark "désactivé" (cercle vide gris)
			place_disabled_sign(bufnr, line)
		else
			-- Aucun breakpoint: en créer un nouveau
			dap.toggle_breakpoint()
		end
	end
end

---@class statuscol.FoldData
---@field width integer         -- current width of the fold column
---@field close string         -- foldclose char
---@field open string          -- foldopen char
---@field sep string           -- foldsep char

---@class statuscol.text.arg
---@field lnum integer         -- v:lnum
---@field relnum integer       -- v:relnum
---@field virtnum integer      -- v:virtnum
---@field buf integer          -- buffer handle of drawn window
---@field win integer          -- window handle of drawn window
---@field actual_curbuf integer -- buffer handle of |g:actual_curwin|
---@field actual_curwin integer -- window handle of |g:actual_curbuf|
---@field nu boolean           -- 'number' option value
---@field rnu boolean          -- 'relativenumber' option value
---@field empty boolean        -- statuscolumn is currently empty
---@field fold statuscol.FoldData        -- fold column data
---@field tick integer         -- display_tick value
---@field wp any               -- win_T pointer handle (FFI cdata)

local ft_ignore = {
	Avante = true,
	AvanteInput = true,
	help = true,
	["neo-tree"] = true,
	codecompanion = true,
	snacks_terminal = true,
}
local ft_padding = { help = true, checkhealth = true, snacks_terminal = true }
local ft_scrolloff = { help = true, checkhealth = true }

---@param arg statuscol.text.arg
local function should_ignore(arg)
	local ft = vim.bo[arg.buf].filetype
	return not ft_ignore[ft] and vim.wo.number
end

Userautocmd({ "FileType", "WinEnter", "BufWinEnter" }, {
	callback = function(args)
		local w = vim.api.nvim_get_current_win()
		local wo = vim.wo[w]
		local bo = vim.bo[args.buf]
		vim.defer_fn(function()
			if not vim.api.nvim_buf_is_loaded(args.buf) or not vim.api.nvim_win_is_valid(w) then
				return
			end
			if ft_ignore[bo.filetype] or bo.buftype == "nofile" or not wo.number then
				wo.number = false
				wo.signcolumn = "no"
				wo.foldcolumn = "0"
				if ft_scrolloff[bo.filetype] then
					wo.sidescrolloff = -1
					wo.scrolloff = -1
				else
					wo.sidescrolloff = 0
					wo.scrolloff = 0
				end
			else
				wo.number = true
				wo.signcolumn = "yes"
				wo.foldcolumn = "1"
				wo.sidescrolloff = -1
				wo.scrolloff = -1
			end
		end, 75)
	end,
})

local function opts()
	local builtin = require("statuscol.builtin")

	local padding = {
		text = { " " },
		condition = {
			function(args)
				return ft_padding[vim.bo[args.buf].filetype]
			end,
		},
		hl = "Normal",
	}

	local sign = { -- Signes DAP (breakpoints actifs via legacy signs + désactivés via extmarks)
		sign = {
			name = { "Dap.*" },
			namespace = { "dap_disabled" },
			maxwidth = 1,
			colwidth = 2,
			auto = false,
		},
		---@param args statuscol.text.arg
		condition = {
			function(args)
				return should_ignore(args) and vim.b[args.buf].scratch ~= true
			end,
		},
		click = "v:lua.DapClickHandler",
	}
	---@param win statuscol.text.arg
	local function number_cond(win)
		if win.nu then
			return true
		end
		return false
	end
	local number = { text = { builtin.lnumfunc }, condition = { number_cond } } --click = "v:lua.ScLa" },
	local git_gold =
		{ text = { " ", fold_with_git }, condition = { should_ignore, should_ignore }, click = "v:lua.ScFa" }

	return {
		relculright = true,
		segments = {
			padding,
			sign,
			number,
			git_gold,
		},
	}
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
	opts = opts,
}
