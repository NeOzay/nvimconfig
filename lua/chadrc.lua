-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

local field = "#A6A67C"
local class = "#0DB9D7"

M.base46 = {
	theme = "sonokai",
	integrations = { "trouble", "telescope" },

	hl_add = {
		["@lsp.typemod.keyword.readonly"] = { fg = "purple", italic = false },
		["@lsp.typemod.class.declaration"] = { italic = true },
	},

	hl_override = {
		["@comment"] = { italic = false },
		["@lsp.type.comment"] = { link = "@comment" },
		["@keyword"] = { italic = true, fg = "blue" },
		["@keyword.conditional"] = { fg = "blue" },
		["@keyword.return"] = { italic = true, fg = "blue" },
		["@lsp.type.property"] = { fg = field },
		["@property"] = { fg = field },
		["@lsp.type.class"] = { fg = class },
		["@type"] = { fg = class },
	},
}

-- M.nvdash = { load_on_startup = true }
M.ui = {
	tabufline = {
		lazyload = false,
	},
}

return M
