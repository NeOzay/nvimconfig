local M = {}

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

---@param client vim.lsp.Client
---@param bufnr integer
function M.attach(client, bufnr)
	local map = vim.keymap.set
	local function opts(desc)
		return { buffer = bufnr, desc = "LSP " .. desc }
	end

	map("n", "gD", wrapTrouble("lsp_declarations"), opts("Go to declaration"))
	map("n", "gd", wrapTrouble("lsp_definitions"), opts("Go to definition"))
	map("n", "grr", wrapTrouble("lsp_references"), opts("Go to references"))
	map("n", "gri", wrapTrouble("lsp_implementations"), opts("Go to implementation"))
	map("n", "grt", wrapTrouble("lsp_type_definitions"), opts("Go to type definition"))
	map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts("Remove workspace folder"))
	map("n", "<leader>wl", list_workspace_folders, opts("List workspace folders"))
	map("n", "<F2>", vim.lsp.buf.rename, opts("Rename"))
	map("n", "grn", vim.lsp.buf.rename, opts("Rename"))
	map("n", "<leader>ra", function()
		require("lsp.ai-rename").rename()
	end, opts("AI Rename"))
end

return M
