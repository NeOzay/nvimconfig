local M = {}

M.lsp_configs = {
	"emmylua_ls",
	"ruff",
	"basedpyright",
	-- "ty",
	"jsonls",
	"ts_ls",
	"rust_analyzer",
	"zshcs",
	"marksman",
}

---@param client vim.lsp.Client
---@param bufnr integer
local function on_attach(client, bufnr)
	if client and client.server_capabilities and client.server_capabilities.documentSymbolProvider then
		require("nvim-navic").attach(client, bufnr)
	end

	if client:supports_method("workspace/diagnostic", bufnr) then
		vim.lsp.buf.workspace_diagnostics({ client_id = client.id })
	elseif client.name ~= "copilot" and client.name ~= "basedpyright" then
		require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
	end

	require("lsp.mappings").attach(client, bufnr)
end

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
	capabilities.textDocument.hover = capabilities.textDocument.hover or {}
	capabilities.textDocument.diagnostic.dynamicRegistration = true
	return capabilities
end

local function setup_floating_preview()
	local orig = vim.lsp.util.open_floating_preview
	function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
		opts = opts or {}
		opts.border = opts.border or "rounded"
		return orig(contents, syntax, opts, ...)
	end
end

local function setup_diagnostics()
	local x = vim.diagnostic.severity
	local sign_icons = { [x.ERROR] = "󰅙", [x.WARN] = "", [x.INFO] = "󰋼", [x.HINT] = "󰌵" }

	vim.diagnostic.config({
		virtual_text = {
			prefix = function(diagnostic, i, _total)
				local severity = diagnostic.severity
				if i == 1 then
					vim.b[diagnostic.bufnr]._diag_seen = {}
				end
				local seen = vim.b[diagnostic.bufnr]._diag_seen or {}
				if seen[severity] then
					return ""
				end
				seen[severity] = true
				vim.b[diagnostic.bufnr]._diag_seen = seen
				local count = #vim.diagnostic.get(diagnostic.bufnr, { severity = severity, lnum = diagnostic.lnum })
				local icon = sign_icons[severity] or ""
				return string.format("%s %d ", icon, count)
			end,
			hl_mode = "combine",
		},
		signs = { text = sign_icons },
		underline = true,
		float = { border = "rounded" },
	})
end

---@param server_list? string[]
function M.setup(server_list)
	setup_diagnostics()
	setup_floating_preview()

	local capabilities = setup_capabilities()
	vim.lsp.config("*", {
		capabilities = capabilities,
		root_dir = function(_, on_dir)
			on_dir(vim.fn.getcwd())
		end,
	})

	Userautocmd("LspAttach", {
		callback = function(args)
			on_attach(vim.lsp.get_client_by_id(args.data.client_id), args.buf)
		end,
	})

	for _, name in ipairs(server_list or M.lsp_configs) do
		vim.lsp.enable(name)
	end

	require("lsp.hover").setup()
end

return M
