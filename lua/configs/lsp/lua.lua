---@type vim.lsp.Config
local M = {}

M.name = "emmylua_ls"

M.filetypes = { "lua" }

M.settings = {
  Lua = {
    runtime = {
      version = "LuaJIT",
      requirePattern = { "?.lua", "?/init.lua", "lua/?.lua", "lua/?/init.lua" }
    },
    workspace = {
      library = {
        vim.fn.expand("$VIMRUNTIME/lua"),
        -- vim.fn.stdpath("data") .. "/lazy/ui/nvchad_types",
        -- vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua/lazy",
      },
      checkThirdParty = false,
      workspaceRoots = {
        vim.fn.getcwd(),
      },
      ignoreDir = {},
    },
    strict = {
      requirePath = true
    },
    diagnostics = {
      enable = true,
      globals = { "vim" },
    },
  },
}

vim.list_extend(M.settings.Lua.workspace.library, vim.opt.rtp:get())

return M
