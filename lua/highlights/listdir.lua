-- listdir highlights for Sonokai theme : pickers des Registres (`lua/registres.lua`)

local colors = require("base46").get_theme_tb("base_30") ---@as Base30Table

---@type Base46HLTable
return {
	-- Libellé d'une dette épinglée
	ListDirPinned = { fg = colors.purple, bold = true },

	-- Sévérité d'une dette, par niveau ; `inconnue` reste en retrait
	ListDirSeverityCritique = { fg = colors.red, bold = true },
	ListDirSeverityMajeur = { fg = colors.orange },
	ListDirSeverityAvertissement = { fg = colors.yellow },
	ListDirSeverityNote = { fg = colors.grey_fg },
	ListDirSeverityInconnue = { fg = colors.grey },
}
