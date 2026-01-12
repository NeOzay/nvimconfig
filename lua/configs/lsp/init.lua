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
function M.setup(common_config)
  M.common_config = common_config or {}

  local servers = {}

  for _, config_name in ipairs(M.lsp_configs) do
    local ok, lsp_config = pcall(require, "configs.lsp." .. config_name)
    if ok then
      local server_name = lsp_config.server_name

      -- Configure le serveur LSP
      local config = vim.tbl_deep_extend("force", M.common_config, {
        settings = lsp_config.settings or {},
      })

      -- Ajouter on_init si défini dans le module LSP
      if lsp_config.on_init then
        config.on_init = lsp_config.on_init
      end

      vim.lsp.config(server_name, config)
      table.insert(servers, server_name)

      -- Exécuter les commandes personnalisées si elles existent
      if lsp_config.commands then
        lsp_config.commands()
      end
    else
      vim.notify("Failed to load LSP config: " .. config_name, vim.log.levels.WARN)
    end
  end

  -- Active tous les serveurs LSP
  if #servers > 0 then
    vim.lsp.enable(servers)
  end
end

return M
