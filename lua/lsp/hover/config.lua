---@namespace Ozay.Hover

---@class opts
---
---@field border_hl string Highlight group for the window borders.
---@field name_hl? string Highlight group for the `name`. Defaults to `border_hl`.
---@field name string
---
---@field min_width integer
---@field max_width integer
---
---@field min_height integer
---@field max_height integer

local M = {}

--- Configuration for lsp_hovers from different
--- servers.
---
---@type { default: opts, [string]: Partial<opts> }
M.config = {
	default = {
		border_hl = "@comment",
		name = "󰗊 LSP/Hover",

		min_width = 20,
		max_width = math.floor(vim.o.columns * 0.75),

		min_height = 1,
		max_height = math.floor(vim.o.lines * 0.5),
	},

	["^lua_ls"] = {
		name = " LuaLS",
		border_hl = "@function",
	},

	["^emmylua"] = {
		name = " Emmylua",
		border_hl = "@comment",
	},
}

--- Finds matching configuration.
--- NOTE: The output is the merge of the {config} and {default}.
---@param str string
---@return opts
function M.get_config(str)
	local default = vim.deepcopy(M.config.default)

	for name, config in pairs(M.config) do
		if name ~= "default" and string.match(str, name) then
			---@cast config opts
			return vim.tbl_deep_extend("force", default, config)
		end
	end
	return default
end

return M
