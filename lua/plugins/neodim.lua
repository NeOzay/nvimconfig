local get_hi = require("base46.colors").get_hi_attr

local function x() end
local a = x()
-- print(a)

---@type LazyPluginSpec
return {
	"ALVAROPING1/neodim",
	branch = "fix-nvim-0.11",
	event = "LspAttach",
	config = function()
		require("neodim").setup({
			alpha = 0.45,
			blend_color = get_hi("@comment", "fg"),
			hide = {
				virtual_text = false,
				signs = false,
				-- underline = false,
			},
		})
	end,
}
