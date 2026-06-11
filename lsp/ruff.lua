---@alias Ozay.RuffCommand
---| "applyAutofix"
---| "applyFormat"
---| "applyOrganizeImports"
---| "printDebugInformation"

---@type Ozay.RuffCommand[]
local commands = {
	"applyAutofix",
	"applyFormat",
	"applyOrganizeImports",
	"printDebugInformation",
}

---@type vim.lsp.Config
return {
	on_attach = function(client, bufnr)
		vim.api.nvim_buf_create_user_command(bufnr, "Ruff", function(opts)
			client:exec_cmd({
				title = opts.args,
				command = "ruff." .. opts.args,
				arguments = { { uri = vim.uri_from_bufnr(bufnr), version = vim.lsp.util.buf_versions[bufnr] } },
			})
		end, {
			nargs = 1,
			complete = function(lead)
				return vim.tbl_filter(function(c)
					return c:lower():find(lead:lower(), 1, true) ~= nil
				end, commands)
			end,
			desc = "Exécute une commande ruff LSP",
		})
	end,
}
