local M = {}

M.server_name = "jsonls"

-- Essayer de charger schemastore si disponible
local has_schemastore, schemastore = pcall(require, "schemastore")

M.settings = {
  json = {
    schemas = has_schemastore and schemastore.json.schemas() or {},
    validate = { enable = true },
    format = {
      enable = true,
    },
  },
}

return M
