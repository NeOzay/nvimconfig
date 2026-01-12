---@type vim.lsp.Config
local M = {}

M.name = "ts_ls"
M.filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" }

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
---@param client vim.lsp.Client
M.on_init = function(client, _)
	-- Commandes personnalisées pour TypeScript
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
