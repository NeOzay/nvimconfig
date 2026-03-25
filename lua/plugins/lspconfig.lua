---@param mode string
---@param opt? trouble.Mode|{ new: boolean?, refresh: boolean? }
local function wrapTrouble(mode, opt)
	---@type trouble
	local trouble = require("trouble")
	opt = opt or { auto_close = true }
	opt.mode = mode
	return function()
		trouble.open(opt)
	end
end

local function list_workspace_folders()
	print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
end

local function on_attach(client, bufnr)
	if client and client.server_capabilities and client.server_capabilities.documentSymbolProvider then
		require("nvim-navic").attach(client, bufnr)
	end

	local map = vim.keymap.set
	local function opts(desc)
		return { buffer = bufnr, desc = "LSP " .. desc }
	end

	map("n", "gD", wrapTrouble("lsp_declarations"), opts("Go to declaration"))
	map("n", "gd", wrapTrouble("lsp_definitions"), opts("Go to definition"))
	map("n", "grr", wrapTrouble("lsp_references"), opts("Go to references"))
	map("n", "gri", wrapTrouble("lsp_implementations"), opts("Go to implmentation"))
	map("n", "grt", wrapTrouble("lsp_type_definitions"), opts("Go to type definition"))
	map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts("Remove workspace folder"))
	map("n", "<leader>wl", list_workspace_folders, opts("List workspace folders"))
	map("n", "<F2>", vim.lsp.buf.rename, opts("Rename"))
	map("n", "grn", vim.lsp.buf.rename, opts("Rename"))
end

local function on_init(_client, _) end

local function root_dir(fname, on_dir)
	on_dir(vim.fn.getcwd())
end

-- ===== NOUVEAU CODE (blink.cmp) =====
local function setup_capabilities()
	local blink, ok = pRequire("blink.cmp")
	local capabilities
	if ok then
		capabilities = blink.get_lsp_capabilities()
	else
		capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities.textDocument = capabilities.textDocument or {}
		capabilities.textDocument.completion = capabilities.textDocument.completion or {}
		capabilities.textDocument.completion.completionItem = {
			documentationFormat = { "markdown", "plaintext" },
			snippetSupport = true,
			preselectSupport = true,
			insertReplaceSupport = true,
			labelDetailsSupport = true,
			deprecatedSupport = true,
			commitCharactersSupport = true,
		}
	end
	capabilities.textDocument = capabilities.textDocument or {}
	capabilities.textDocument.diagnostic = capabilities.textDocument.diagnostic or {}

	capabilities.textDocument.diagnostic.dynamicRegistration = true

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
	local x = vim.diagnostic.severity
	vim.diagnostic.config({
		virtual_text = { prefix = "" },
		signs = { text = { [x.ERROR] = "󰅙", [x.WARN] = "", [x.INFO] = "󰋼", [x.HINT] = "󰌵" } },
		underline = true,
	})

	vim.diagnostic.config({
		float = {
			border = "rounded",
		},
	})

	setup_floating_preview()

	local capabilities = setup_capabilities()
	vim.lsp.config("*", {
		capabilities = capabilities,
		on_init = on_init,
		on_attach = on_attach,
		root_dir = root_dir,
	})

	require("lsp").setup()
end

---@type LazySpec
return {
	"neovim/nvim-lspconfig",
	event = "User FilePost",
	config = config,
}
