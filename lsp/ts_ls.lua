---@type vim.lsp.Config
return {
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },

	settings = {
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
	},

	---@param client vim.lsp.Client
	on_init = function(client, _)
		vim.api.nvim_create_user_command("TsOrganizeImports", function()
			client:exec_cmd({
				title = "Organiser les imports TypeScript",
				command = "_typescript.organizeImports",
				arguments = { vim.api.nvim_buf_get_name(0) },
			}, { bufnr = 0 })
		end, { desc = "Organiser les imports TypeScript" })

		vim.api.nvim_create_user_command("TsRemoveUnused", function()
			client:exec_cmd({
				title = "Supprimer les imports non utilisés",
				command = "_typescript.removeUnusedImports",
				arguments = { vim.api.nvim_buf_get_name(0) },
			}, { bufnr = 0 })
		end, { desc = "Supprimer les imports non utilisés" })

		vim.api.nvim_create_user_command("TsAddMissingImports", function()
			client:exec_cmd({
				title = "Ajouter les imports manquants",
				command = "_typescript.addMissingImports",
				arguments = { vim.api.nvim_buf_get_name(0) },
			}, { bufnr = 0 })
		end, { desc = "Ajouter les imports manquants" })
	end,
}
