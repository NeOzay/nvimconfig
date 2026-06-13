local M = {}

---@class Ozay.Statuscol.ConditionSpec
---@field ft_blacklist? table<string, true>
---@field ft_whitelist? table<string, true>
---@field require_number? boolean
---@field require_file? boolean         -- vrai fichier : buftype "" + nom non vide
---@field buftype_blacklist? table<string, true>
---@field active_only? boolean          -- seulement dans la window focalisée
---@field ignore_float_win? boolean
---@field min_win_width? integer  -- masque si la largeur de la window <
---@field max_win_width? integer  -- masque si la largeur de la window >
---@field min_columns? integer    -- garde-fou : masque si la largeur terminal <
---@field buf_predicate? fun(bufnr: integer): boolean
---@field win_predicate? fun(winid: integer): boolean
---@field predicate? fun(args: Ozay.Statuscol.text.arg): boolean
---@field enabled? boolean|fun(): boolean
---@field after? fun(ctx: Ozay.Statuscol.RenderCtx): boolean  -- expérimental : interroge les segments déjà rendus à gauche (même ligne)

---@class Ozay.Statuscol.RenderCtx
---@field win integer
---@field lnum integer
---@field tick integer
---@field rendered table<string, boolean>  -- nom de segment -> condition passée (texte autorisé)

M.ft_ignore = {
	[""] = true,
	Avante = true,
	AvanteInput = true,
	help = true,
	["neo-tree"] = true,
	codecompanion = true,
	snacks_terminal = true,
}

M.ft_padding = { help = true, checkhealth = true, snacks_terminal = true }
M.ft_scrolloff = { help = true, checkhealth = true }

-- Seuils de masquage des segments superflus (numéros de ligne, colonne dap).
-- Deux axes : la largeur de la *window* (axe principal, gère les splits
-- verticaux) ET un garde-fou sur la largeur du *terminal* entier. NARROW_WIDTH
-- est aligné sur le seuil du picker snacks. Les deux sont indépendamment
-- réglables : on masque dès que l'un des deux n'est pas satisfait.
M.NARROW_WIDTH = 100 -- terminal (garde-fou)
M.NARROW_WIN_WIDTH = 100 -- window

--- La window (et le terminal) sont-ils assez larges pour les segments superflus ?
--- Mesure la largeur de la window passée — pas `vim.o.columns` — pour réagir
--- correctement aux splits verticaux (une window étroite dans un terminal large).
---@param win? integer  -- défaut : window courante (= window en cours de rendu)
---@return boolean
function M.wide_enough(win)
	win = win or vim.api.nvim_get_current_win()
	if not vim.api.nvim_win_is_valid(win) then
		return true
	end
	return vim.api.nvim_win_get_width(win) >= M.NARROW_WIN_WIDTH and vim.o.columns >= M.NARROW_WIDTH
end

-- Contexte de rendu partagé entre les segments d'UNE MÊME ligne (expérimental,
-- piste 2). statuscol évalue les conditions des segments DANS L'ORDRE (cf.
-- get_statuscol_string), pour chaque (win, lnum) à un `tick` donné. On accumule
-- donc au fil de l'évaluation quels segments ont passé leur condition, et un
-- segment peut interroger ceux qui le précèdent (order inférieur) via `after`.
-- Une seule table module-level suffit : statuscol rend les segments d'une ligne
-- séquentiellement, donc le contexte courant est toujours celui de (win, lnum,
-- tick). On le réinitialise dès que cette clé change.
--
-- Caveats :
--  * `rendered[name]` = « la CONDITION du segment a passé », pas « un glyphe est
--    visible ». Pour un sign segment `auto = true`, la colonne peut quand même se
--    replier si aucun sign n'est présent — l'info est donc approximative.
--  * dépend de l'ordre `order` et du fait que statuscol n'inverse pas l'éval ;
--    l'écriture est idempotente, donc une réévaluation partielle (cache) ne
--    corrompt pas le contexte tant que le `tick` est le même.
---@type Ozay.Statuscol.RenderCtx
local render_ctx = { win = -1, lnum = -1, tick = -1, rendered = {} }

--- Récupère (et réinitialise au besoin) le contexte de rendu pour la ligne en
--- cours. Réinitialise `rendered` dès que (win, lnum, tick) change.
---@param args Ozay.Statuscol.text.arg
---@return Ozay.Statuscol.RenderCtx
local function get_render_ctx(args)
	if render_ctx.win ~= args.win or render_ctx.lnum ~= args.lnum or render_ctx.tick ~= args.tick then
		render_ctx.win = args.win
		render_ctx.lnum = args.lnum
		render_ctx.tick = args.tick
		render_ctx.rendered = {}
	end
	return render_ctx
end

--- Evalue un ConditionSpec contre les arguments statuscol.
---@param spec Ozay.Statuscol.ConditionSpec
---@param args Ozay.Statuscol.text.arg
---@param ctx? Ozay.Statuscol.RenderCtx  -- contexte inter-segments (fourni par make_condition)
---@return boolean
function M.evaluate(spec, args, ctx)
	if spec.enabled ~= nil then
		-- NB : ne pas réduire en ternaire `cond and f() or x` — si `f()` renvoie
		-- false, le `or` renverrait la fonction elle-même (truthy) et le segment
		-- ne serait jamais masqué.
		local enabled = spec.enabled
		if type(enabled) == "function" then
			enabled = enabled()
		end
		if enabled == false then
			return false
		end
	end

	-- Window active : `args.win` = window dessinée, `args.actual_curwin` =
	-- `g:actual_curwin` = window réellement focalisée. Fail-open si non renseigné.
	if spec.active_only and args.actual_curwin and args.win ~= args.actual_curwin then
		return false
	end

	local ft = vim.bo[args.buf].filetype

	if spec.ignore_float_win then
		local opts = vim.api.nvim_win_get_config(args.win)
		if opts.relative ~= "" then
			return false
		end
	end

	if spec.min_columns and vim.o.columns < spec.min_columns then
		return false
	end

	if spec.min_win_width or spec.max_win_width then
		local w = vim.api.nvim_win_get_width(args.win)
		if spec.min_win_width and w < spec.min_win_width then
			return false
		end
		if spec.max_win_width and w > spec.max_win_width then
			return false
		end
	end

	if spec.ft_blacklist and spec.ft_blacklist[ft] then
		return false
	end

	if spec.ft_whitelist and not spec.ft_whitelist[ft] then
		return false
	end

	if spec.buftype_blacklist and spec.buftype_blacklist[vim.bo[args.buf].buftype] then
		return false
	end

	if spec.require_number ~= nil and spec.require_number ~= vim.wo.number then
		return false
	end

	-- Vrai fichier : buftype normal ("") ET nom non vide. Exclut terminal/prompt/
	-- nofile/help/quickfix et les buffers anonymes. Pas de stat disque (évalué par
	-- ligne à chaque rendu).
	if spec.require_file then
		if vim.bo[args.buf].buftype ~= "" or vim.api.nvim_buf_get_name(args.buf) == "" then
			return false
		end
	end

	if spec.buf_predicate and not spec.buf_predicate(args.buf) then
		return false
	end

	if spec.win_predicate and not spec.win_predicate(args.win) then
		return false
	end

	if spec.predicate and not spec.predicate(args) then
		return false
	end

	-- Contexte inter-segments (expérimental) : interroge les segments déjà
	-- évalués à gauche sur la même ligne. Évalué en dernier (le plus cher / le
	-- plus fragile). Sans ctx (appel direct de `evaluate`), `after` est ignoré.
	if spec.after and ctx and not spec.after(ctx) then
		return false
	end

	return true
end

--- Retourne une table condition compatible avec statuscol.
--- `name` (le nom du segment) est inscrit dans le contexte de rendu quand la
--- condition passe, pour que les segments suivants puissent l'interroger via
--- `after`.
---@param spec Ozay.Statuscol.ConditionSpec
---@param name string
---@return table
function M.make_condition(spec, name)
	return {
		function(args)
			local ctx = get_render_ctx(args)
			local ok = M.evaluate(spec, args, ctx)
			if ok then
				ctx.rendered[name] = true
			end
			return ok
		end,
	}
end

--- Applique les options de fenetre (number/signcolumn/foldcolumn/scrolloff)
--- a une fenetre selon son filetype/buftype et la largeur du terminal.
--- Vider le texte d'un segment via une condition ne suffit pas a reduire la
--- largeur de la colonne : `numberwidth` reste reserve tant que `number` est
--- actif. On eteint donc `number` quand le terminal est etroit pour reclamer
--- la place. La colonne dap (sign segment) se replie d'elle-meme une fois son
--- texte vide (statuscolumn a largeur dynamique).
---@param win integer
---@param buf integer
function M.apply_win_options(win, buf)
	if not vim.api.nvim_buf_is_loaded(buf) or not vim.api.nvim_win_is_valid(win) then
		return
	end
	if vim.api.nvim_win_get_config(win).relative ~= "" then
		return
	end
	local wo = vim.wo[win]
	local bo = vim.bo[buf]
	-- Buffers speciaux : aucune colonne. Décision basée sur le filetype/buftype
	-- (pas sur `wo.number` courant, sinon on ne pourrait pas restaurer après un
	-- passage en mode étroit).
	local special = M.ft_ignore[bo.filetype] or bo.buftype == "nofile"
	if special then
		wo.number = false
		wo.signcolumn = "no"
		wo.foldcolumn = "0"
		if M.ft_scrolloff[bo.filetype] then
			wo.sidescrolloff = -1
			wo.scrolloff = -1
		else
			wo.sidescrolloff = 0
			wo.scrolloff = 0
		end
	else
		-- Fenetre de contenu : numeros masques (et largeur reclamee) si la window
		-- (ou le terminal) est etroite. Mesure par window -> reagit aux splits.
		local wide = M.wide_enough(win)
		wo.number = wide
		wo.signcolumn = wide and "yes" or "no"
		wo.foldcolumn = "1"
		wo.sidescrolloff = -1
		wo.scrolloff = -1
	end
end

--- Configure les autocmds pour les options de fenetre selon le filetype et la
--- largeur du terminal.
--- Reapplique les options a une liste de fenetres (apres un court delai pour
--- laisser la largeur se stabiliser).
---@param wins integer[]
local function reapply_to(wins)
	vim.defer_fn(function()
		for _, win in ipairs(wins) do
			if vim.api.nvim_win_is_valid(win) then
				M.apply_win_options(win, vim.api.nvim_win_get_buf(win))
			end
		end
	end, 75)
end

function M.setup_win_autocmd()
	Userautocmd({ "FileType", "WinEnter", "BufWinEnter" }, {
		callback = function(args)
			reapply_to({ vim.api.nvim_get_current_win() })
		end,
	})
	-- Resize du terminal entier : reappliquer a toutes les fenetres du tab.
	Userautocmd("VimResized", {
		callback = function()
			reapply_to(vim.api.nvim_tabpage_list_wins(0))
		end,
	})
	-- Resize d'un split (sans VimResized) : reappliquer aux fenetres touchees.
	-- `v:event.windows` n'est valide que pendant l'autocmd -> on le capture avant
	-- le defer.
	Userautocmd("WinResized", {
		callback = function()
			local wins = vim.v.event and vim.v.event.windows
			reapply_to(wins or vim.api.nvim_tabpage_list_wins(0))
		end,
	})
end

return M
