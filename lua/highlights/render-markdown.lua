-- render-markdown highlights for Sonokai theme (transposition des couleurs de l'autre moteur).
-- Remplace entièrement base46.integrations.render-markdown : les titres sont redéfinis ici.

local colors = require("base46").get_theme_tb("base_30") ---@as Base30Table

local heading = { colors.red, colors.orange, colors.yellow, colors.green, colors.blue, colors.purple }

---@type table<string, vim.api.keyset.highlight>
local hl = {
	-- Code blocks
	RenderMarkdownCode = { bg = "code_bg" },
	RenderMarkdownCodeInfo = { fg = colors.grey_fg, bg = colors.one_bg },
	RenderMarkdownCodeInline = { bg = "code_bg", fg = colors.cyan },
	-- Étiquette de langage (`code.highlight_language`). Le fond n'est pas réglable ici : le plugin
	-- empile RenderMarkdownCodeBorder après ce groupe, et la ligne de la fence en prend la couleur.
	RenderMarkdownCodeLanguage = { fg = "yellow" },
	RenderMarkdownCodeBorder = { bg = "code_bg" },

	-- Block quotes et callouts
	RenderMarkdownQuote = { fg = colors.grey_fg },
	RenderMarkdownInfo = { fg = colors.blue },
	RenderMarkdownSuccess = { fg = colors.green },
	RenderMarkdownHint = { fg = colors.purple },
	RenderMarkdownWarn = { fg = colors.yellow },
	RenderMarkdownError = { fg = colors.red },

	-- Séparateur horizontal (`---`)
	RenderMarkdownDash = { fg = "grey_fg2" },

	-- Lists et checkboxes
	RenderMarkdownBullet = { fg = colors.red },
	RenderMarkdownChecked = { fg = colors.green },
	RenderMarkdownUnchecked = { fg = colors.grey_fg },
	RenderMarkdownTodo = { fg = colors.yellow },

	-- Tables
	RenderMarkdownTableHead = { fg = colors.blue, bold = true },
	RenderMarkdownTableRow = { fg = colors.grey },

	-- Links
	RenderMarkdownLink = { fg = colors.blue, underline = true },
	RenderMarkdownWikiLink = { fg = colors.purple, underline = true },
}

for i, color in ipairs(heading) do
	hl["@markup.heading." .. i .. ".markdown"] = { fg = color }
	hl["RenderMarkdownH" .. i] = { fg = color, bold = true }
	hl["RenderMarkdownH" .. i .. "Bg"] = { fg = color, bg = colors.one_bg2, bold = true }
end

return hl
