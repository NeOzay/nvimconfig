---Document concaténé d'une liste, écrit sous le cache de Neovim puis ouvert en
---lecture seule.
---
---Généré en Lua depuis les fichiers, jamais par `merge` : celui-ci exige `--filled`
---et n'écrit pas de liens. Chaque titre d'élément est un lien Markdown vers son
---fichier, et `render` est pure pour rester vérifiable.
---
---POURQUOI UN VRAI FICHIER, et non un buffer `nofile` : le core de Neovim refuse
---d'attacher un serveur LSP à tout buffer dont `buftype` n'est pas vide
---(`runtime/lua/vim/lsp.lua`, « Only ever attach to buffers … that represent an
---actual file »). Un `nofile` privait donc le document de marksman. Le fichier est
---écrit **hors du répertoire-liste** : la liste elle-même n'est jamais touchée.

local item = require("listdir.item")

---Sous-répertoire du cache où les documents sont écrits.
local CACHE = "listdir"

---@class Ozay.ListDir.Document
local M = {}

---Décale les titres du corps d'un niveau, pour les faire passer sous le titre de
---l'élément. Les lignes internes à un bloc de code sont laissées telles quelles :
---un `## ` collé dans une sortie de commande est du contenu, pas un titre — même
---règle que celle appliquée par `list-dir` lui-même.
---@param body string
---@return string[]
local function shifted(body)
	---@type string[]
	local out = {}
	local fence = nil ---@type string?
	for line in vim.gsplit(body, "\n", { plain = true }) do
		local marker = line:match("^%s*(```+)") or line:match("^%s*(~~~+)")
		if fence then
			if marker and marker:sub(1, 1) == fence:sub(1, 1) and #marker >= #fence then
				fence = nil
			end
		elseif marker then
			fence = marker
		end
		out[#out + 1] = (not fence and line:match("^#+%s")) and ("#" .. line) or line
	end
	return out
end

---Destination d'un lien Markdown. Un chemin peut contenir des parenthèses ou des
---espaces, que la forme `(…)` de CommonMark ne sait pas porter : `[t](/a/b (c)/d.md)`
---se coupe à la première parenthèse fermante et ouvre un fichier qui n'existe pas,
---sans la moindre erreur. La forme `<…>` les accepte ; seuls `<` et `>` y sont
---échappés.
---@param path string
---@return string
---@nodiscard
local function destination(path)
	if path:find("[%s()<>]") then
		return "<" .. path:gsub("[<>]", "\\%0") .. ">"
	end
	return path
end

---@param dir string répertoire-liste
---@param contract Ozay.ListDir.Contract
---@param rows Ozay.ListDir.Row[] dans l'ordre voulu — celui du tri courant
---@return string[]
---@nodiscard
function M.render(dir, contract, rows)
	---@type string[]
	local lines = { "# " .. contract.name, "" }
	if contract.description ~= "" then
		lines[#lines + 1] = contract.description
		lines[#lines + 1] = ""
	end
	-- Deux listes homonymes partagent le même fichier de cache : le chemin d'origine
	-- lève l'ambiguïté sans avoir à décorer le nom du buffer.
	lines[#lines + 1] = "`" .. dir .. "`"
	lines[#lines + 1] = ""

	for _, row in ipairs(rows) do
		local data = item.read(row.path)
		local title = item.title(row.path, row.id)
		lines[#lines + 1] = ("## [%s](%s)"):format(title, destination(row.path))
		lines[#lines + 1] = ""
		if data and data.body ~= "" then
			vim.list_extend(lines, shifted(data.body))
			lines[#lines + 1] = ""
		end
	end

	return lines
end

---Chemin du document d'une liste, sous le cache de Neovim.
---@param contract Ozay.ListDir.Contract
---@return string
---@nodiscard
function M.path(contract)
	local name = contract.name:gsub("[^%w%-_.]", "_")
	return vim.fs.joinpath(vim.fn.stdpath("cache") --[[@as string]], CACHE, name .. ".md")
end

---La cible du lien Markdown porté par une ligne, s'il y en a une.
---@param buf integer
---@param line integer numéro de ligne, 1-based
---@return string?
---@nodiscard
function M.target(buf, line)
	local text = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1]
	if not text then
		return nil
	end
	local angle = text:match("%]%(<(.-)>%)")
	if angle then
		return (angle:gsub("\\([<>])", "%1"))
	end
	-- Forme nue : elle n'est émise que pour un chemin sans parenthèse, d'où `[^()]`.
	return text:match("%]%(([^()]*)%)")
end

---Suit le lien Markdown de la ligne courante. Sans lien, ne fait rien : le message
---vaut mieux qu'un `gf` qui ouvrirait un fichier arbitraire sous le curseur.
local function follow()
	local buf = vim.api.nvim_get_current_buf()
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local target = M.target(buf, line)
	if not target then
		vim.notify("listdir : aucun lien sur cette ligne", vim.log.levels.INFO)
		return
	end
	vim.cmd.edit(vim.fn.fnameescape(target))
end

---@param buf integer
local function set_keymaps(buf)
	vim.keymap.set("n", "<CR>", follow, { buffer = buf, desc = "listdir: ouvrir l élément" })
	vim.keymap.set("n", "gf", follow, { buffer = buf, desc = "listdir: ouvrir l élément" })
	vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, desc = "listdir: fermer" })
end

---@param dir string
---@param contract Ozay.ListDir.Contract
---@param rows Ozay.ListDir.Row[]
---@return integer bufnr
function M.open(dir, contract, rows)
	local path = M.path(contract)
	vim.fn.mkdir(vim.fs.dirname(path), "p")
	vim.fn.writefile(M.render(dir, contract, rows), path)

	-- `edit!` recharge le buffer s'il était déjà ouvert : son contenu vient de
	-- changer sur le disque, et il est `nomodifiable`.
	vim.cmd.edit({ args = { vim.fn.fnameescape(path) }, bang = true })

	local buf = vim.api.nvim_get_current_buf()
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false
	vim.bo[buf].readonly = true
	set_keymaps(buf)

	return buf
end

return M
