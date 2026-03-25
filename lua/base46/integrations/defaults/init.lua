--- Merges all core integration highlights into a single table.
--- Files: defaults, syntax, treesitter, lsp, git

local modules = {
	"defaults",
	"syntax",
	"treesitter",
	"lsp",
	"git",
}

local all = {}
for _, name in ipairs(modules) do
	local hl = require("base46.integrations.defaults." .. name)
	all = vim.tbl_deep_extend("error", all, hl)
end

---@type Base46HLTable
return all
