-- On Termux, copilot-language-server is a JS file with #!/usr/bin/env node shebang
-- but /usr/bin/env doesn't exist. Call node directly when that's the case.
local function resolve_cmd()
	local bin = vim.fn.exepath("copilot-language-server")
	if bin ~= "" and not vim.uv.fs_stat("/usr/bin/env") then
		return { "node", vim.uv.fs_realpath(bin), "--stdio" }
	end
	return { "copilot-language-server", "--stdio" }
end

local v = vim.version()

---@type vim.lsp.Config
return {
	name = "copilot_ls",
	cmd = resolve_cmd(),
	init_options = {
		editorInfo = {
			name = "neovim",
			version = ("%d.%d.%d"):format(v.major, v.minor, v.patch),
		},
		editorPluginInfo = { name = "Github Copilot LSP for Neovim", version = "0.0.1" },
	},
	settings = { nextEditSuggestions = { enabled = true } },
	handlers = require("copilot-lsp.handlers"),
	root_dir = vim.uv.cwd(),
	on_init = function(client)
		local au = vim.api.nvim_create_augroup("copilotlsp.init", { clear = true })
		require("copilot-lsp.nes").lsp_on_init(client, au)
	end,
}
