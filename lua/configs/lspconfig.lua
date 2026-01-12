local M = {}
local map = vim.keymap.set

-- export on_attach & capabilities
M.on_attach = function(_, bufnr)
	local function opts(desc)
		return { buffer = bufnr, desc = "LSP " .. desc }
	end

	map("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
	map("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
	map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts("Add workspace folder"))
	map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts("Remove workspace folder"))

	map("n", "<leader>wl", function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, opts("List workspace folders"))

	map("n", "<leader>D", vim.lsp.buf.type_definition, opts("Go to type definition"))
	map("n", "<leader>ra", require("nvchad.lsp.renamer"), opts("NvRenamer"))
end

-- disable semanticTokens
M.on_init = function(client, _) end

M.capabilities = vim.lsp.protocol.make_client_capabilities()

M.capabilities.textDocument.completion.completionItem = {
	documentationFormat = { "markdown", "plaintext" },
	snippetSupport = true,
	preselectSupport = true,
	insertReplaceSupport = true,
	labelDetailsSupport = true,
	deprecatedSupport = true,
	commitCharactersSupport = true,
	-- tagSupport = { valueSet = { 1 } },
	-- resolveSupport = {
	-- 	properties = {
	-- 		"documentation",
	-- 		"detail",
	-- 		"additionalTextEdits",
	-- 	},
	-- },
}

-- Activer le support des diagnostics pull (pour Neovim 0.11+)
M.capabilities.textDocument.diagnostic = {
	dynamicRegistration = false,
}

M.defaults = function()
	dofile(vim.g.base46_cache .. "lsp")
	require("nvchad.lsp").diagnostic_config()

	vim.api.nvim_create_autocmd("LspAttach", {
		callback = function(args)
			M.on_attach(_, args.buf)
		end,
	})

	-- Use new vim.lsp.config API for Neovim 0.11+
	-- Configuration globale pour tous les serveurs LSP
	vim.lsp.config("*", {
		capabilities = M.capabilities,
		on_init = M.on_init,
		-- handlers = {
		-- 	["workspace/diagnostic/refresh"] = function(err, result, ctx, config)
		-- 		-- Accepter la demande de rafraîchissement sans action
		-- 		-- Le LSP va automatiquement renvoyer les diagnostics
		--
		-- 		return vim.NIL
		-- 	end,
		-- },
	})

	-- Charge et configure tous les serveurs LSP depuis le module
	require("configs.lsp").setup()
end

M.defaults()

-- read :h vim.lsp.config for changing options of lsp servers
