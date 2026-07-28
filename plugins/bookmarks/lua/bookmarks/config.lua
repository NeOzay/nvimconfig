---@class Ozay.Bookmarks.Config.Signs
---@field icon string
---@field hl_group string
---@field annotation_hl_group string annotation_hl_group hl du virtual text
---@field line_hl_group? string hl du fond de ligne pour les lignes marquées
---@field note_icon string icône affichée en virtual text si une note est présente
---@field note_hl_group string hl du chunk icône de note

---@class Ozay.Bookmarks.ConfigModule
local M = {}

---@alias Ozay.Bookmarks.Config.opt Partial<Ozay.Bookmarks.Config>
---@alias Ozay.Bookmarks.Config.Signs.opt Partial<Ozay.Bookmarks.Config.Signs>

---@class Ozay.Bookmarks.Config
---@field db_dir? string dossier custom, défaut stdpath("data")
---@field db_path? string chemin complet custom, prioritaire sur db_dir
---@field signs Ozay.Bookmarks.Config.Signs
---@field default_tag string tag par défaut du toggle rapide
M.defaults = {
	db_dir = nil,
	db_path = nil,
	signs = {
		icon = "󰃁",
		hl_group = "DiagnosticSignInfo",
		annotation_hl_group = "Comment",
		line_hl_group = "BookmarksLine",
		note_icon = "󰛓",
		note_hl_group = "DiagnosticSignHint",
	},
	default_tag = "",
}

---@type Ozay.Bookmarks.Config
M.options = vim.deepcopy(M.defaults)

--- Fusionne les options utilisateur avec les défauts.
---@param opts? Ozay.Bookmarks.Config
---@return Ozay.Bookmarks.Config
function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
	return M.options
end

--- Chemin absolu résolu du fichier sqlite.
--- Ordre de priorité : db_path > db_dir/bookmarks.sqlite.db > stdpath('data')/bookmarks.sqlite.db
---@return string
function M.resolved_db_path()
	if M.options.db_path then
		return M.options.db_path
	end
	local dir = M.options.db_dir or vim.fn.stdpath("data")
	return vim.fs.joinpath(dir, "bookmarks.sqlite.db")
end

return M
