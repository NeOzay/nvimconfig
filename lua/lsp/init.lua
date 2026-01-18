local M = {}

-- Configuration commune pour tous les LSP
M.common_config = {}
-- Liste des fichiers de configuration LSP à charger
M.lsp_configs = {
	"lua",
	"python",
	"json",
	"typescript",
	-- Ajoutez d'autres configurations LSP ici
}

-- Charge et configure tous les LSP
---@param common_config? vim.lsp.Config
function M.setup(common_config)
	M.common_config = common_config or {}

	for _, config_name in ipairs(M.lsp_configs) do
		---@type vim.lsp.Config
		local lsp_config, ok = pRequire("lsp." .. config_name)
		if ok and lsp_config.name then
			local server_name = lsp_config.name
			-- Merger la config commune avec la config spécifique
			local config = vim.tbl_deep_extend("force", M.common_config, lsp_config)

			vim.lsp.config(server_name, config)
			vim.lsp.enable(server_name)
		else
			vim.notify("Failed to load LSP config: " .. config_name, vim.log.levels.WARN)
		end
	end

	-- Les serveurs seront activés automatiquement sur les bons filetypes
	-- car nous avons défini le champ 'filetypes' dans la configuration
end

return M
