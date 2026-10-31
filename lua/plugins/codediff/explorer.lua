-- Pilotage de l'explorateur de codediff depuis la configuration, sans toucher
-- au plugin : tout passe par son API (lifecycle, actions) et son registre de
-- mappings, qui restaure les mappings d'origine à la fin de la session.

---@class Ozay.CodediffExplorer
local M = {}

---@param tabpage integer
---@return table? explorer
local function get_explorer(tabpage)
	local lifecycle = require("codediff.ui.lifecycle")
	if lifecycle.get_panel_name(tabpage) ~= "explorer" then
		return nil
	end
	return lifecycle.get_panel_view(tabpage)
end

---@param explorer table
---@return integer? winid
local function visible_win(explorer)
	local winid = explorer.split and explorer.split.winid
	if winid and vim.api.nvim_win_is_valid(winid) then
		return winid
	end
end

-- Cache l'explorateur et met le focus sur le diff.
---@param tabpage integer
local function hide_and_focus_diff(tabpage)
	require("codediff.ui.view.actions.panes").toggle_explorer({ tabpage = tabpage })
	local _, modified_win = require("codediff.ui.lifecycle").get_windows(tabpage)
	if modified_win and vim.api.nvim_win_is_valid(modified_win) then
		vim.api.nvim_set_current_win(modified_win)
	end
end

-- Caché → s'ouvre et prend le focus ; visible sans le focus → focus ;
-- focus → se ferme, le focus passe au diff.
local function toggle_focus()
	local tabpage = vim.api.nvim_get_current_tabpage()
	local explorer = get_explorer(tabpage)
	if not explorer then
		return
	end
	if visible_win(explorer) ~= vim.api.nvim_get_current_win() then
		require("codediff.ui.view.actions.panes").focus_explorer({ tabpage = tabpage })
		return
	end
	hide_and_focus_diff(tabpage)
end

---@param node table?
---@return boolean
local function is_foldable(node)
	local kind = node and node.data and node.data.type
	return kind == "directory" or kind == "group"
end

-- Colonne (1-based) du nom dans la ligne, ou de ce qu'il en reste quand
-- `truncate_priority` l'a tronqué : son plus long début présent, sinon « … ».
-- Le préfixe de la ligne (indentation, traits de l'arbre, icône) n'a que des
-- espaces et des caractères non ASCII, qu'un début de nom ne rencontre pas.
---@param line string
---@param name string
---@return integer?
local function name_col(line, name)
	for len = #name, 1, -1 do
		local col = line:find(name:sub(1, len), 1, true)
		if col then
			return col
		end
	end
	return (line:find("…", 1, true))
end

-- Curseur sur la première lettre du nom de la ligne courante : nom du fichier
-- ou du dossier. Groupe ou nom introuvable → premier caractère non blanc.
---@param explorer table
local function place_cursor(explorer)
	local win = visible_win(explorer)
	if not win then
		return
	end
	local row = vim.api.nvim_win_get_cursor(win)[1]
	local line = vim.api.nvim_buf_get_lines(explorer.split.bufnr, row - 1, row, false)[1]
	if not line then
		return
	end
	local node = vim.api.nvim_win_call(win, function()
		return explorer.tree:get_node()
	end)
	local data = node and node.data or {}
	---@type string?
	local name
	if data.type == "directory" then
		name = data.name
	elseif data.type ~= "group" and data.path then
		name = vim.fs.basename(data.path)
	end
	local col = name and name ~= "" and name_col(line, name) or line:find("%S") or 1
	vim.api.nvim_win_set_cursor(win, { row, col - 1 })
end

---@param explorer table
---@param node table
local function toggle_fold(explorer, node)
	if node:is_expanded() then
		node:collapse()
	else
		node:expand()
	end
	explorer.tree:render()
	place_cursor(explorer)
end

-- Entrée sur un fichier : cacher l'explorateur et focus le diff **avant** la
-- sélection. `M.update` capture la fenêtre courante à son entrée et la rend en
-- fin de chargement : il capture ainsi le diff. Un chargement déjà en cours
-- (lancé par un clic) a capturé l'explorateur, fermé entre-temps, donc
-- invalide, et ne le rend pas.
---@param explorer table
---@param node table
local function open_file(explorer, node)
	hide_and_focus_diff(explorer.tabpage)
	explorer.on_file_select(node.data)
end

-- Applique `on_file` ou `on_fold` au nœud sous le curseur.
---@param explorer table
---@param on_file fun(explorer: table, node: table)
---@param on_fold? fun(explorer: table, node: table)
local function on_cursor_node(explorer, on_file, on_fold)
	local node = explorer.tree:get_node()
	if not node or not node.data then
		return
	end
	if not is_foldable(node) then
		on_file(explorer, node)
	elseif on_fold then
		on_fold(explorer, node)
	end
end

---@param explorer table
---@param node table
local function select_file(explorer, node)
	explorer.on_file_select(node.data)
end

-- Entrée et double-clic sur le buffer de l'explorateur. Même propriétaire et
-- même portée que les claims du plugin : elles les remplacent, posées après
-- `keymaps.setup` de l'explorateur, qui précède `CodeDiffOpen`. Au
-- double-clic, le premier relâchement a fait l'effet du clic ;
-- `<2-LeftMouse>` n'ajoute que ce qui distingue Entrée, rien sur un dossier.
---@param explorer table
local function map_explorer(explorer)
	local lifecycle = require("codediff.ui.lifecycle")
	---@param lhs string
	---@param on_file fun(explorer: table, node: table)
	---@param on_fold? fun(explorer: table, node: table)
	---@param desc string
	local function map(lhs, on_file, on_fold, desc)
		lifecycle.set_buf_keymap(explorer.tabpage, explorer.split.bufnr, "n", lhs, function()
			on_cursor_node(explorer, on_file, on_fold)
		end, { desc = desc, nowait = true, silent = true }, { suspendable = false, priority = 10 })
	end
	map("<CR>", open_file, toggle_fold, "CodeDiff: aller au diff / plier")
	map("<2-LeftMouse>", open_file, nil, "CodeDiff: aller au diff")
	-- Le clic natif place le curseur après le WinEnter : on_left_release le
	-- replace ensuite.
	Userautocmd("WinEnter", {
		buffer = explorer.split.bufnr,
		callback = function()
			place_cursor(explorer)
		end,
	})
end

-- Clic simple : un mapping `<LeftRelease>` ne se déclenche pas, satellite
-- pose un `<LeftMouse>` global qui lit lui-même la suite des événements
-- souris et les rejoue sans remap (`nvim_feedkeys(…, "ni")`). On guette donc
-- la touche, tapée ou rejouée, et on agit au tour de boucle suivant, une fois
-- le clic natif traité (focus et curseur placés), s'il a eu lieu sur une ligne
-- de l'explorateur.
local function on_left_release()
	if vim.api.nvim_get_mode().mode ~= "n" then
		return
	end
	local explorer = get_explorer(vim.api.nvim_get_current_tabpage())
	local win = explorer and visible_win(explorer)
	if not explorer or not win or vim.api.nvim_get_current_win() ~= win then
		return
	end
	local pos = vim.fn.getmousepos()
	if pos.winid ~= win or pos.line == 0 then
		return
	end
	-- Sous la dernière ligne, `line` vaut la dernière ligne : un clic dans le
	-- vide n'agit pas, il replace seulement le curseur.
	if vim.fn.screenpos(win, pos.line, 1).row ~= pos.screenrow then
		place_cursor(explorer)
		return
	end
	on_cursor_node(explorer, select_file, toggle_fold)
	place_cursor(explorer)
end

-- Chaque fichier sélectionné crée un nouveau buffer modifié, que le plugin
-- re-mappe pour ses touches mais pas pour les nôtres : `<leader>e` se réclame
-- à chaque entrée dans une fenêtre de la session. Le filtre porte sur la
-- fenêtre, pas sur le buffer : pendant le chargement, le nouveau buffer entre
-- dans la fenêtre du diff avant que la session ne l'enregistre, et le focus
-- rendu ensuite à la même fenêtre ne redéclenche rien. Réclamer deux fois
-- remplace la claim précédente. `suspendable` le retire au TabLeave : le vrai
-- fichier, affiché dans un autre tab, ne le porte pas là-bas.
---@param bufnr integer
local function claim_leader_e(bufnr)
	local tabpage = vim.api.nvim_get_current_tabpage()
	local explorer = get_explorer(tabpage)
	if not explorer then
		return
	end
	local lifecycle = require("codediff.ui.lifecycle")
	local win = vim.api.nvim_get_current_win()
	local original_win, modified_win = lifecycle.get_windows(tabpage)
	if win ~= original_win and win ~= modified_win and win ~= visible_win(explorer) then
		return
	end
	if vim.api.nvim_win_get_buf(win) ~= bufnr then
		return
	end
	lifecycle.set_buf_keymap(
		tabpage,
		bufnr,
		"n",
		"<leader>e",
		toggle_focus,
		{ desc = "CodeDiff: ouvrir, focus ou fermer l'explorateur", nowait = true, silent = true },
		{ suspendable = true, priority = 10 }
	)
end

-- En layout inline, un fichier simple face (`??`, `A`, `D`) pas encore chargé
-- passe par `helpers.open_real_file`, qui met le focus sur le diff pour son
-- `:edit` et ne le rend jamais. Le diff ordinaire, lui, le rend en fin de
-- chargement (`saved_current_win` de `commit_update`) : on fait de même.
-- `view/init.lua` lit `inline_view.show_single_file` à chaque appel, d'où
-- l'enveloppe posée sur ce champ.
local function restore_focus_after_single_file()
	local inline_view = require("codediff.ui.view.inline_view")
	local show_single_file = inline_view.show_single_file
	inline_view.show_single_file = function(...)
		local win = vim.api.nvim_get_current_win()
		show_single_file(...)
		if vim.api.nvim_win_is_valid(win) and vim.api.nvim_get_current_win() ~= win then
			vim.api.nvim_set_current_win(win)
		end
	end
end

function M.setup()
	restore_focus_after_single_file()
	local left_release = vim.keycode("<LeftRelease>")
	vim.on_key(function(key)
		if key == left_release then
			vim.schedule(on_left_release)
		end
	end, vim.api.nvim_create_namespace("Ozay.codediff_explorer"))
	Userautocmd("User", {
		pattern = "CodeDiffOpen",
		callback = function(args)
			local data = args.data or {}
			if data.mode ~= "explorer" then
				return
			end
			local explorer = get_explorer(data.tabpage)
			if explorer then
				map_explorer(explorer)
			end
		end,
	})
	Userautocmd({ "BufEnter", "WinEnter" }, {
		callback = function(args)
			claim_leader_e(args.buf)
		end,
	})
end

return M
