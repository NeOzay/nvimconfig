local colors = require("base46").get_theme_tb("base_30") ---@as Base30Table
local mix = require("base46.colors").mix_colors_group

return {
	TroubleDirectory = { fg = mix("comment", "Normal", 60) },
	TroubleIconDirectory = { link = "Directory" },
}
