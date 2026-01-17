---@type vim.lsp.Config
local M = {}

M.name = "emmylua_ls"

M.filetypes = { "lua" }

M.settings = {
	Lua = {
		runtime = {
			version = "LuaJIT",
			requireLikeFunction = { "pRequire" },
			requirePattern = { "?.lua", "?/init.lua", "lua/?.lua", "lua/?/init.lua" },
		},
		workspace = {
			library = {
				-- vim.fn.stdpath("data") .. "/lazy/ui/nvchad_types",
				-- vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua/lazy",
			},
			checkThirdParty = false,
			ignoreDir = {},
		},
		strict = {
			requirePath = true,
		},
		diagnostics = {
			enable = true,
			-- globals = { "vim" },
		},
	},
}

local function addPluginsAndVimToLib()
	local lib = M.settings.Lua.workspace.library
	table.insert(lib, vim.fn.expand("$VIMRUNTIME/lua"))
	local folder = vim.fn.stdpath("data") .. "/lazy/"
	for name, _ in vim.fs.dir(folder) do
		table.insert(lib, vim.fs.joinpath(folder, name))
	end
end

addPluginsAndVimToLib()

return M
