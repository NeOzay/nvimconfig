local palette = require "tokyonight.colors"
local tokyonight = require "tokyonight"
local getRGBGroup = require "ozay.util".getRGBHighlightGroup

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
  return {
    1
  }
end

tokyonight.setup {
  on_colors = function(colors)
    ---@class ColorScheme
    local _colors = colors
    _colors.neutralGreen = "#afaf87"
    _colors.londonHue = "#B48EAD"
    _colors.londonHue2 = "#e0d1de"
    _colors.pp = "#8A5DAB"
  end,
  on_highlights = function(h, colors)
    local highlights = {}
    setmetatable(highlights, {
      __newindex = function(t, k, v)
        if type(v) == "table" then
          h[k] = v
        else
          h[k] = h[v] or getRGBGroup(v)
        end
      end,
      __index = h
    })

    highlights["String"] = { fg = sonokaiPalette.yellow }
    highlights["Constant"] = { fg = colors.magenta }
    highlights["@lsp.mod.readonly"] = { fg = colors.londonHue2 }

    highlights["@method"] = { fg = colors.green }
    highlights["@lsp.type.method"] = { fg = colors.green }

    highlights["Function"] = { fg = colors.green }
    highlights["@function"] = "Function"
    highlights["@function.builtin"] = "Function"
    highlights["@lsp.type.function"] = { fg = colors.green }
    highlights["@lsp.typemod.function.defaultLibrary"] = { fg = colors.green, style = { italic = true } }
    highlights["@lsp.typemod.function.global"] = { fg = colors.green, style = { italic = true } }

    highlights["@lsp.typemod.variable.global"] = { style = { italic = true } }

    highlights["@property"] = { fg = colors.neutralGreen }
    highlights["@field"] = { fg = colors.neutralGreen }
    highlights["@member"] = { fg = colors.green }
    highlights["@parameter"] = { fg = colors.orange }

    highlights["Type"] = { fg = colors.blue2, style = { italic = true } }
    highlights["@type"] = { fg = colors.blue2, style = { italic = true } }
    highlights["@class"] = { fg = colors.blue2 }
    highlights["@lsp.type.enum"] = { fg = colors.red }
    highlights["@constructor"] = "@method"

    highlights["@punctuation.delimiter"] = { fg = colors.dark5 }
    --highlights["@punctuation.special"] = { fg = colors.dark5 }
    highlights["@keyword.function"] = { fg = colors.magenta, style = { italic = true } }
    highlights["@boolean"] = { fg = colors.blue2 }


    highlights["@lsp.typemod.class.declaration"] = { style = { bold = true } }
    highlights["@lsp.typemod.interface.declaration"] = { style = { bold = true, italic = false } }
    highlights["@lsp.typemod.enum.declaration"] = { style = { bold = true } }
    highlights["@lsp.typemod.type.declaration"] = { style = { bold = true } }

    highlights["Noise"] = { fg = colors.blue1 }
    highlights["LuaNoise"] = { fg = colors.dark5 }
    highlights["luaFuncParens"] = { fg = colors.londonHue }
    highlights["luaParens"] = { fg = colors.londonHue }
    highlights["luaBraces"] = { fg = colors.blue1 }
    highlights["luaFuncKeyword"] = { fg = colors.red, style = { italic = true } }


    highlights["CmpItemKindFunction"] = "Function"
    highlights["CmpItemKindProperty"] = "@property"
    highlights["CmpItemKindField"] = "@property"
    highlights["CmpItemKindClass"] = "@class"
    highlights["CmpItemKindInterface"] = "@lsp.type.interface"
    highlights["CmpItemKindEnum"] = "@lsp.type.enum"
    highlights["CmpItemKindVariable"] = "@variable"
    highlights["CmpItemKindConstant"] = "@lsp.mod.readonly"
    highlights["CmpItemKindKeyword"] = "@keyword"

    --highlights["NavicIconsFile"] = {}
    --highlights["NavicIconsModule"] = {}
    --highlights["NavicIconsNamespace"] = {}
    highlights["NavicIconsPackage"] = "Statement"
    highlights["NavicIconsClass"] = "@class"
    highlights["NavicIconsMethod"] = "@method"
    highlights["NavicIconsProperty"] = "@property"
    highlights["NavicIconsField"] = "@field"
    highlights["NavicIconsConstructor"] = "@constructor"
    highlights["NavicIconsEnum"] = "@enum"
    highlights["NavicIconsInterface"] = "@lsp.type.interface"
    highlights["NavicIconsFunction"] = "@function"
    highlights["NavicIconsVariable"] = "@variable"
    highlights["NavicIconsConstant"] = "@lsp.mod.readonly"
    highlights["NavicIconsString"] = "String"
    highlights["NavicIconsNumber"] = "Number"
    highlights["NavicIconsBoolean"] = "@boolean"
    highlights["NavicIconsArray"] = "@property"
    highlights["NavicIconsObject"] = "@property"
    --highlights["NavicIconsKey"] = ""
    --highlights["NavicIconsNull"] = {}
    highlights["NavicIconsEnumMember"] = "@enum"
    highlights["NavicIconsStruct"] = "Structure"
    highlights["NavicIconsEvent"] = "CmpItemKindEvent"
    highlights["NavicIconsOperator"] = "@operator"
    --highlights["NavicIconsTypeParameter"] = {}
    highlights["NavicText"] = { bg = colors.black }
    highlights["NavicSeparator"] = { fg = colors.red1 }
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
