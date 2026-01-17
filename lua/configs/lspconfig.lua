local M = {}
local map = vim.keymap.set

---@param mode string
---@param opt? trouble.Mode|{ new: boolean?, refresh: boolean? }
local function wrapTrouble(mode, opt)
	---@type trouble
	local trouble = require("trouble")
	opt = opt or {}
	opt.mode = mode
	return function()
		trouble.open(opt)
	end
end

-- export on_attach & capabilities
M.on_attach = function(_, bufnr)
	local function opts(desc)
		return { buffer = bufnr, desc = "LSP " .. desc }
	end
	map("n", "gD", wrapTrouble("lsp_declarations"), opts("Go to declaration"))
	map("n", "gd", wrapTrouble("lsp_definitions"), opts("Go to definition"))
	map("n", "gr", wrapTrouble("lsp_references"), opts("Go to references"))
	-- map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts("Add workspace folder"))
	map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts("Remove workspace folder"))

	map("n", "<leader>wl", function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, opts("List workspace folders"))

	map("n", "<leader>D", vim.lsp.buf.type_definition, opts("Go to type definition"))
	map("n", "<F2>", require("nvchad.lsp.renamer"), opts("NvRenamer"))
end

M.on_init = function(_client, _) end

M.capabilities = vim.lsp.protocol.make_client_capabilities()

---@diagnostic disable-next-line
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
---@diagnostic disable-next-line
M.capabilities.textDocument.diagnostic = {
	dynamicRegistration = true,
}

M.defaults = function()
	dofile(vim.g.base46_cache .. "lsp")
	require("nvchad.lsp").diagnostic_config()

	-- Configurer les bordures pour les popups de diagnostic
	vim.diagnostic.config({
		float = {
			border = "rounded",
		},
	})

	-- Configurer les bordures pour les popups hover et signature help (Neovim 0.11+)
	local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
	function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
		opts = opts or {}
		opts.border = opts.border or "rounded"
		return orig_util_open_floating_preview(contents, syntax, opts, ...)
	end

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
		-- 		-- Accepter la demande de rafraîchissement
		-- 		-- Le LSP va automatiquement renvoyer les diagnostics mis à jour
		-- 		return vim.NIL
		-- 	end,
		-- },
	})

	-- Charge et configure tous les serveurs LSP depuis le module
	require("configs.lsp").setup()
end

M.defaults()

-- read :h vim.lsp.config for changing options of lsp servers
