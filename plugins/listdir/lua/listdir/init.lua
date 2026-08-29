---Visualisation des répertoires-listes du skill `list-dir`, en lecture seule.
---
---Trois vues enchaînées : un picker des listes trouvées sous les chemins configurés,
---un picker des éléments de la liste choisie, et un buffer `nofile` où les éléments
---sont concaténés en Markdown.
---
---Aucune commande d'écriture de `list-dir` n'est appelée, et `show` non plus : le
---contenu des éléments est lu directement par Neovim.

---@class Ozay.ListDir
local M = {}

---@param opts? Partial<Ozay.ListDir.Options>
function M.setup(opts)
	require("listdir.config").setup(opts)

	vim.api.nvim_create_user_command("ListDir", function()
		require("listdir.picker.lists").open()
	end, { desc = "listdir: picker des répertoires-listes" })
end

return M
