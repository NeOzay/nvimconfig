local M = {}

--- Variable globale partagée avec dap.lua pour la persistance
---@type table<string, table<string, Ozay.Dap.BreakpointOpts>?>
M.DapDisabledBreakpoints = {}

--- Namespace Neovim pour les extmarks des breakpoints désactivés.
--- Utiliser les extmarks au lieu des legacy signs pour éviter les conflits
--- avec les opérations de signes de nvim-dap.
M.disabled_ns = vim.api.nvim_create_namespace("dap_disabled")

return M
