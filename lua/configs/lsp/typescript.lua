---@type vim.lsp.Config
local M = {}

M.server_name = "ts_ls"

M.settings = {
  typescript = {
    inlayHints = {
      includeInlayParameterNameHints = "all",
      includeInlayParameterNameHintsWhenArgumentMatchesName = false,
      includeInlayFunctionParameterTypeHints = true,
      includeInlayVariableTypeHints = true,
      includeInlayVariableTypeHintsWhenTypeMatchesName = false,
      includeInlayPropertyDeclarationTypeHints = true,
      includeInlayFunctionLikeReturnTypeHints = true,
      includeInlayEnumMemberValueHints = true,
    },
    suggest = {
      includeCompletionsForModuleExports = true,
    },
    preferences = {
      importModuleSpecifier = "non-relative",
    },
  },
  javascript = {
    inlayHints = {
      includeInlayParameterNameHints = "all",
      includeInlayParameterNameHintsWhenArgumentMatchesName = false,
      includeInlayFunctionParameterTypeHints = true,
      includeInlayVariableTypeHints = true,
      includeInlayVariableTypeHintsWhenTypeMatchesName = false,
      includeInlayPropertyDeclarationTypeHints = true,
      includeInlayFunctionLikeReturnTypeHints = true,
      includeInlayEnumMemberValueHints = true,
    },
    suggest = {
      includeCompletionsForModuleExports = true,
    },
  },
}

-- Activer les jetons sémantiques pour TypeScript
M.on_init = function(client, _)
  -- Forcer l'activation des semantic tokens pour TypeScript
  if client.supports_method "textDocument/semanticTokens" then
    client.server_capabilities.semanticTokensProvider = {
      full = true,
      legend = {
        tokenTypes = client.server_capabilities.semanticTokensProvider.legend.tokenTypes,
        tokenModifiers = client.server_capabilities.semanticTokensProvider.legend.tokenModifiers,
      },
    }
  end
end

-- Commandes personnalisées pour TypeScript
M.commands = function()
  -- Commande pour organiser les imports
  vim.api.nvim_create_user_command("TsOrganizeImports", function()
    vim.lsp.buf.execute_command({
      command = "_typescript.organizeImports",
      arguments = { vim.api.nvim_buf_get_name(0) },
    })
  end, { desc = "Organiser les imports TypeScript" })

  -- Commande pour supprimer les imports non utilisés
  vim.api.nvim_create_user_command("TsRemoveUnused", function()
    vim.lsp.buf.execute_command({
      command = "_typescript.removeUnusedImports",
      arguments = { vim.api.nvim_buf_get_name(0) },
    })
  end, { desc = "Supprimer les imports non utilisés" })

  -- Commande pour ajouter les imports manquants
  vim.api.nvim_create_user_command("TsAddMissingImports", function()
    vim.lsp.buf.execute_command({
      command = "_typescript.addMissingImports",
      arguments = { vim.api.nvim_buf_get_name(0) },
    })
  end, { desc = "Ajouter les imports manquants" })
end

return M
