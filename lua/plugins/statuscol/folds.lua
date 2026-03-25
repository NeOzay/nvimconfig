local M = {}

M.FOLD_END = "╰"

M.indent_hls = {
	"IblScopeChar",
	"RainbowScopeRed",
	"RainbowScopeYellow",
	"RainbowScopeBlue",
	"RainbowScopeOrange",
	"RainbowScopeGreen",
	"RainbowScopeViolet",
	"RainbowScopeCyan",
}

function M.setup_hl()
	vim.api.nvim_set_hl(0, "CursorLineFold", { link = "Normal" })
	vim.api.nvim_set_hl(0, "FoldColumn", { link = "IblChar" })
end

---@param args statuscol.text.arg
function M.fold_by_indent(args)
	local fold_text = require("statuscol.builtin").foldfunc(args)
	local level = vim.fn.foldlevel(args.lnum)
	if level > 0 then
		local hl = M.indent_hls[((level - 1) % #M.indent_hls) + 1]
		local clean = fold_text:gsub("%%#[^#]*#", ""):gsub("%%%*", "")
		local next_level = vim.fn.foldlevel(args.lnum + 1)
		if next_level < level and vim.fn.foldclosed(args.lnum) == -1 then
			local sep = args.fold.sep
			clean = clean:gsub(vim.pesc(sep), M.FOLD_END)
		end
		return "%#" .. hl .. "#" .. clean
	end
	return fold_text
end

--- Wrap un clickhandler de fold pour scroller le haut du fold
--- à la position écran du clic après fermeture.
---@param default_handler function
---@return function
function M.with_scroll_to_click(default_handler)
	return function(args)
		if args.button ~= "l" then
			default_handler(args)
			return
		end

		local line = args.mousepos.line
		-- Fold déjà fermé → comportement par défaut (ouverture)
		if vim.fn.foldclosed(line) ~= -1 then
			default_handler(args)
			return
		end

		local target_winline = vim.fn.winline()
		default_handler(args)

		-- Vérifier si le fold est maintenant fermé
		local fold_start = vim.fn.foldclosed(line)
		if fold_start == -1 then
			return
		end

		-- Calculer le topline pour placer fold_start à la position du clic
		local topline = fold_start
		local visible = 0
		while visible < target_winline - 1 and topline > 1 do
			topline = topline - 1
			local fc = vim.fn.foldclosed(topline)
			if fc ~= -1 then
				topline = fc
			end
			visible = visible + 1
		end
		vim.fn.winrestview({ topline = topline, lnum = fold_start, col = 0 })
	end
end

return M
