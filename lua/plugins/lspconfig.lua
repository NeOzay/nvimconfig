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

local function list_workspace_folders()
	print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
end

local function on_attach(client_id, bufnr)
	local client = vim.lsp.get_client_by_id(client_id)
	if client and client.server_capabilities and client.server_capabilities.documentSymbolProvider then
		require("nvim-navic").attach(client, bufnr)
	end

	local map = vim.keymap.set
	local function opts(desc)
		return { buffer = bufnr, desc = "LSP " .. desc }
	end
	map("n", "gD", wrapTrouble("lsp_declarations"), opts("Go to declaration"))
	map("n", "gd", wrapTrouble("lsp_definitions"), opts("Go to definition"))
	map("n", "gr", wrapTrouble("lsp_references"), opts("Go to references"))
	map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts("Remove workspace folder"))
	map("n", "<leader>wl", list_workspace_folders, opts("List workspace folders"))
	map("n", "<leader>D", vim.lsp.buf.type_definition, opts("Go to type definition"))
	map("n", "<F2>", require("nvchad.lsp.renamer"), opts("NvRenamer"))
end

local function on_init(_client, _) end

local function setup_capabilities()
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	---@diagnostic disable-next-line
	capabilities.textDocument.completion.completionItem = {
		documentationFormat = { "markdown", "plaintext" },
		snippetSupport = true,
		preselectSupport = true,
		insertReplaceSupport = true,
		labelDetailsSupport = true,
		deprecatedSupport = true,
		commitCharactersSupport = true,
	}
	---@diagnostic disable-next-line
	capabilities.textDocument.diagnostic = {
		dynamicRegistration = true,
	}
	return capabilities
end

local function setup_floating_preview()
	local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
	function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
		opts = opts or {}
		opts.border = opts.border or "rounded"
		return orig_util_open_floating_preview(contents, syntax, opts, ...)
	end
end

local function config()
	dofile(vim.g.base46_cache .. "lsp")
	require("nvchad.lsp").diagnostic_config()

	vim.diagnostic.config({
		float = {
			border = "rounded",
		},
	})

	setup_floating_preview()

	vim.api.nvim_create_autocmd("LspAttach", {
		callback = function(args)
			on_attach(args.data.client_id, args.buf)
		end,
	})

	local capabilities = setup_capabilities()
	vim.lsp.config("*", {
		capabilities = capabilities,
		on_init = on_init,
	})

	require("lsp").setup()
end

---@type LazySpec
return {
	"neovim/nvim-lspconfig",
	config = config,
}
