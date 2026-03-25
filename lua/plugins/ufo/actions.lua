local api = vim.api

local M = {}

--- Trouve le fold cible et ses enfants pour le curseur actuel
---@return table|nil fb, table|nil folds (triés par taille croissante)
function M.get_cursor_fold_tree()
	local bufnr = api.nvim_get_current_buf()
	local row = api.nvim_win_get_cursor(0)[1] - 1
	local fb = require("ufo.fold").get(bufnr)
	if not fb then return end
	-- Trouver le fold le plus petit contenant le curseur
	local target
	for _, range in ipairs(fb.foldRanges) do
		if row >= range.startLine and row <= range.endLine then
			if not target or (range.endLine - range.startLine) < (target.endLine - target.startLine) then
				target = range
			end
		end
	end
	if not target then return end
	-- Étendre au plus grand fold partageant la même startLine
	for _, range in ipairs(fb.foldRanges) do
		if range.startLine == target.startLine and (range.endLine - range.startLine) > (target.endLine - target.startLine) then
			target = range
		end
	end
	-- Collecter les folds dans la portée du fold cible
	local folds = {}
	for _, range in ipairs(fb.foldRanges) do
		if range.startLine >= target.startLine and range.endLine <= target.endLine then
			folds[#folds + 1] = range
		end
	end
	-- Trier par taille croissante (enfants d'abord)
	table.sort(folds, function(a, b)
		return (a.endLine - a.startLine) < (b.endLine - b.startLine)
	end)
	return fb, folds
end

--- Ferme récursivement tous les folds sous le curseur (zC)
function M.close_recursive()
	local fb, folds = M.get_cursor_fold_tree()
	if not fb then return end
	for _, range in ipairs(folds) do
		local lnum = range.startLine + 1
		if vim.fn.foldclosedend(lnum) < range.endLine + 1 then
			pcall(vim.cmd, lnum .. "foldclose")
		end
		fb:closeFold(lnum, range.endLine + 1)
	end
end

--- Ouvre récursivement tous les folds sous le curseur (zO)
function M.open_recursive()
	local fb, folds = M.get_cursor_fold_tree()
	if not fb then return end
	for i = #folds, 1, -1 do
		local lnum = folds[i].startLine + 1
		if vim.fn.foldclosed(lnum) ~= -1 then
			pcall(vim.cmd, lnum .. "foldopen")
		end
		fb:openFold(lnum)
	end
end

--- Toggle récursif des folds sous le curseur (zA)
function M.toggle_recursive()
	local fb, folds = M.get_cursor_fold_tree()
	if not fb then return end
	local target_closed = vim.fn.foldclosed(api.nvim_win_get_cursor(0)[1]) ~= -1
	if target_closed then
		for i = #folds, 1, -1 do
			local lnum = folds[i].startLine + 1
			if vim.fn.foldclosed(lnum) ~= -1 then
				pcall(vim.cmd, lnum .. "foldopen")
			end
			fb:openFold(lnum)
		end
	else
		for _, range in ipairs(folds) do
			local lnum = range.startLine + 1
			if vim.fn.foldclosedend(lnum) < range.endLine + 1 then
				pcall(vim.cmd, lnum .. "foldclose")
			end
			fb:closeFold(lnum, range.endLine + 1)
		end
	end
end

return M
