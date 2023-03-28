local palette = require "tokyonight.colors"
local tokyonight = require "tokyonight"

local sonokaiPalette = {
  black       = '#1a181a',
  bg_dim      = '#211f21',
  bg0         = '#2d2a2e',
  bg1         = '#37343a',
  bg2         = '#3b383e',
  bg3         = '#423f46',
  bg4         = '#49464e',
  bg_red      = '#ff6188',
  diff_red    = '#55393d',
  bg_green    = '#a9dc76',
  diff_green  = '#394634',
  bg_blue     = '#78dce8',
  diff_blue   = '#354157',
  diff_yellow = '#4e432f',
  fg          = '#e3e1e4',
  red         = '#f85e84',
  orange      = '#ef9062',
  yellow      = '#e5c463',
  green       = '#9ecd6f',
  blue        = '#7accd7',
  purple      = '#ab9df2',
  grey        = '#848089',
  grey_dim    = '#605d68',
  none        = 'NONE'
}
---@param colors ColorScheme
local function sonokai(colors)


end

tokyonight.setup {
  on_colors = function(colors)
    ---@class ColorScheme
    local _colors = colors
    _colors.neutralGreen = "#afaf87"
    _colors.londonHue = "#B48EAD"
    _colors.pp = "#8A5DAB"

  end,
  on_highlights = function(highlights, colors)
    do
      --return
    end
    highlights["String"] = { fg = sonokaiPalette.yellow }
    highlights["Constant"] = { fg = colors.magenta }
    highlights["@lsp.mod.readonly"] = { fg = colors.londonHue }

    highlights["@method"] = { fg = colors.green }
    highlights["@lsp.type.method"] = { fg = colors.green }

    highlights["@function"] = { fg = colors.green }
    highlights["@function.builtin"] = highlights["@lsp.typemod.function.defaultLibrary"]
    highlights["@lsp.type.function"] = { fg = colors.green }
    highlights["@lsp.typemod.function.defaultLibrary"] = { fg = colors.green, style = { italic = true } }
    highlights["@lsp.typemod.function.global"] = { fg = colors.green, style = { italic = true } }

    highlights["@lsp.typemod.variable.global"] = { fg = colors.red}
    
    highlights["@property"] = { fg = colors.neutralGreen }
    highlights["@field"] = { fg = colors.neutralGreen }
    highlights["@member"] = { fg = colors.green }
    highlights["@parameter"] = { fg = colors.orange }

    highlights["Type"] = { fg = colors.blue2, style = { italic = true } }
    highlights["@type"] = { fg = colors.blue2, style = { italic = true } }
    highlights["@class"] = { fg = colors.blue2 }
    highlights["@lsp.type.enum"] = { fg = colors.red }

    highlights["@punctuation.delimiter"] = { fg = colors.dark5 }
    --highlights["@punctuation.special"] = { fg = colors.dark5 }
    highlights["@keyword.function"] = { fg = colors.magenta, style = { italic = true } }
    highlights["@boolean"] = { fg = colors.blue2 }


    highlights["@lsp.typemod.class.declaration"] = { style = { bold = true } }
    highlights["@lsp.typemod.interface.declaration"] = { style = {bold = true, italic = false} }
    highlights["@lsp.typemod.enum.declaration"] = { style = {bold = true} }
    highlights["@lsp.typemod.type.declaration"] = { style = {bold = true} }

    highlights["Noise"] = { fg = colors.blue1 }
    highlights["LuaNoise"] = { fg = colors.dark5 }
    highlights["luaFuncParens"] = { fg = colors.londonHue }
    highlights["luaParens"] = { fg = colors.londonHue }
    highlights["luaBraces"] = { fg = colors.blue1 }
    highlights["luaFuncKeyword"] = { fg = colors.red, style = { italic = true } }

  end,
  styles = {
    ["comments"] = { italic = false },
  }
}

vim.cmd([[
  augroup reload_colorscheme
  autocmd!
  autocmd BufWritePost tokyonight.lua nested source <afile> | colorscheme tokyonight-night
  augroup end
  ]])
