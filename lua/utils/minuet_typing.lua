---Réconciliation des complétions minuet « en vol » avec le texte tapé entre-temps.
---
---Problème résolu : minuet lance sa requête à la position P, mais la réponse arrive
---plusieurs centaines de ms plus tard, alors que le curseur est en P+n. Le ghost text
---est alors affiché tel quel, décalé du texte qu'on vient de taper.
---minuet ne recale les suggestions que sur celles *déjà affichées*
---(`update_suggestion_on_typing`), pas sur celles qui arrivent après coup.
---
---Ce module enveloppe `complete()` du backend actif : à la réception,
---- si le texte tapé depuis l'envoi préfixe la suggestion → la suggestion est affichée
---  amputée de ce préfixe ;
---- sinon → la suggestion est jetée.
---
---Le patch ne s'applique qu'aux requêtes émises par le ghost text (`minuet.virtualtext`) :
---la source blink.cmp gère elle-même son préfixe via son keyword range.
---@class Ozay.MinuetTyping
local M = {}

local api = vim.api

---@type table<string, true>
local patched = {}

---Vrai si l'appel courant provient du module ghost text de minuet.
---@return boolean
---@nodiscard
local function called_from_virtualtext()
	for level = 2, 10 do
		local info = debug.getinfo(level, "S")
		if not info then
			return false
		end
		if info.source:find("minuet/virtualtext%.lua$") then
			return true
		end
	end
	return false
end

---Texte saisi dans `bufnr` entre `start` et la position courante.
---Retourne `nil` si le contexte n'est plus valide (autre buffer, sortie du mode
---insertion, curseur revenu en arrière) : dans ce cas les suggestions sont jetées.
---@param bufnr integer
---@param start integer[] position `(1-based row, 0-based col)`
---@return string?
---@nodiscard
local function typed_since(bufnr, start)
	if not api.nvim_buf_is_valid(bufnr) or api.nvim_get_current_buf() ~= bufnr then
		return nil
	end
	if not vim.fn.mode():match("^[iR]") then
		return nil
	end

	local cursor = api.nvim_win_get_cursor(0)
	local start_row, start_col = start[1] - 1, start[2]
	local end_row, end_col = cursor[1] - 1, cursor[2]

	-- curseur revenu en arrière (backspace, déplacement) : suggestion obsolète
	if end_row < start_row or (end_row == start_row and end_col < start_col) then
		return nil
	end

	local ok, lines = pcall(api.nvim_buf_get_text, bufnr, start_row, start_col, end_row, end_col, {})
	if not ok then
		return nil
	end
	return table.concat(lines, "\n")
end

---Retire de `item` le préfixe déjà tapé, ou `nil` si l'item ne correspond pas.
---Tolère une indentation en tête de suggestion : les modèles FIM répètent souvent
---l'indentation déjà présente dans le buffer.
---@param item string
---@param typed string
---@return string?
---@nodiscard
local function strip_typed(item, typed)
	if item:sub(1, #typed) == typed then
		return item:sub(#typed + 1)
	end

	if typed:match("^%s") then
		return nil
	end

	local trimmed = item:match("^%s*(.*)$")
	if trimmed ~= item and trimmed:sub(1, #typed) == typed then
		return trimmed:sub(#typed + 1)
	end

	return nil
end

---@param items string[]
---@param bufnr integer
---@param start integer[]
---@return string[]
---@nodiscard
local function reconcile(items, bufnr, start)
	if not items or vim.tbl_isempty(items) then
		return items or {}
	end

	local typed = typed_since(bufnr, start)
	if not typed then
		return {}
	end
	if typed == "" then
		return items
	end

	---@type string[]
	local kept = {}
	for _, item in ipairs(items) do
		local rest = strip_typed(item, typed)
		if rest and rest ~= "" then
			kept[#kept + 1] = rest
		end
	end
	return kept
end

---Enveloppe `complete()` du backend d'un provider minuet (idempotent).
---@param provider string
function M.patch(provider)
	if patched[provider] then
		return
	end

	local ok, backend = pcall(require, "minuet.backends." .. provider)
	if not ok or type(backend) ~= "table" or type(backend.complete) ~= "function" then
		return
	end

	local original = backend.complete

	---@param context table
	---@param callback fun(items: string[])
	backend.complete = function(context, callback)
		if not called_from_virtualtext() then
			return original(context, callback)
		end

		local bufnr = api.nvim_get_current_buf()
		local start = api.nvim_win_get_cursor(0)

		return original(context, function(items)
			callback(reconcile(items, bufnr, start))
		end)
	end

	patched[provider] = true
end

---À appeler après `require("minuet").setup()`.
function M.setup()
	local minuet = require("minuet")
	M.patch(minuet.config.provider)

	-- `:Minuet change_provider` bascule sur un backend non encore enveloppé
	local change_provider = minuet.change_provider
	if type(change_provider) == "function" then
		---@param provider string
		minuet.change_provider = function(provider)
			change_provider(provider)
			M.patch(minuet.config.provider)
		end
	end
end

return M
