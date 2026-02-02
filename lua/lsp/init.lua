local M = {}

-- Liste des fichiers de configuration LSP à charger
M.lsp_configs = {
	"lua",
	"python",
	"json",
	"typescript",
	-- Ajoutez d'autres configurations LSP ici
}

-- Active et configure les LSP par défaut ou spécifiés
---@param server_list? string[]
function M.setup(server_list)
	for _, config_name in ipairs(server_list or M.lsp_configs) do
		---@type vim.lsp.Config
		local lsp_config, ok = pRequire("lsp." .. config_name)
		if ok and lsp_config.name then
			local server_name = lsp_config.name
			vim.lsp.config(server_name, lsp_config)
			vim.lsp.enable(server_name)
		else
			vim.notify("Failed to load LSP config: " .. config_name, vim.log.levels.WARN)
		end
	end

	-- Les serveurs seront activés automatiquement sur les bons filetypes
	-- car nous avons défini le champ 'filetypes' dans la configuration
end

return M
