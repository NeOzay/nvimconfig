local palette = require "tokyonight.colors"
local tokyonight = require "tokyonight"
local util = require "ozay.util"
local getHighlightGroup = util.getRGBHighlightColors
local getHighlightGroupLink = util.getHighlightGroupLink
local getFgColor = util.getRGBHighlightFg
local getBgColor = util.getRGBHighlightBg
local isColor = util.isRGBColor

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

  on_highlights = function(highlights, colors)
    vim.cmd [[colorscheme tokyonight-night]]
    local h = {}
    setmetatable(h, {
      __newindex = function(t, k, v)
        if type(v) == "table" then
          highlights[k] = v
        else
          highlights[k] = h[v] or getHighlightGroup(v)
        end
      end,
      __index = function (t, k)
        if k == nil then return end
        --vim.notify(k)

        local v = highlights[k]
        if v then
          return v
        else
          return t[getHighlightGroupLink(k)]
        end
      end,
      ---@param t table
      ---@param fg string
      ---@param bg string
      ---@param styles? table
      __call = function (t, fg, bg, styles)
        --vim.notify(tostring(fg).." is color: "..tostring(isColor(fg)))
        if not isColor(fg) then
          fg = h[fg] and h[fg].fg or getFgColor(fg)
        end
        if not isColor(bg) then
          bg = h[bg] and h[bg].bg or getBgColor(bg)
        end

        return {
          fg = fg,
          bg = bg,
          style = styles
        }
      end
    })
    local n = 1

    h["String"] = { fg = sonokaiPalette.yellow }
    h["Constant"] = { fg = colors.magenta }
    h["@lsp.mod.readonly"] = { fg = colors.londonHue2 }

    h["@method"] = { fg = colors.green }
    h["@lsp.type.method"] = { fg = colors.green }

    h["Function"] = { fg = colors.green }
    h["@function"] = "Function"
    h["@function.builtin"] = "Function"
    h["@lsp.type.function"] = { fg = colors.green }
    h["@lsp.typemod.function.defaultLibrary"] = { fg = colors.green, style = { italic = true } }
    h["@lsp.typemod.function.global"] = { fg = colors.green, style = { italic = true } }

    h["@lsp.typemod.variable.global"] = { style = { italic = true } }

    h["@property"] = { fg = colors.neutralGreen }
    h["@field"] = { fg = colors.neutralGreen }
    h["@member"] = { fg = colors.green }
    h["@parameter"] = { fg = colors.orange }

    h["Type"] = { fg = colors.blue2, style = { italic = true } }
    h["@type"] = { fg = colors.blue2, style = { italic = true } }
    h["@class"] = { fg = colors.blue2 }
    h["@lsp.type.enum"] = { fg = colors.red }
    h["@constructor"] = "@method"

    h["@punctuation.delimiter"] = { fg = colors.dark5 }
    --highlights["@punctuation.special"] = { fg = colors.dark5 }
    h["@keyword.function"] = { fg = colors.magenta, style = { italic = true } }
    h["@boolean"] = { fg = colors.blue2 }


    h["@lsp.typemod.class.declaration"] = { style = { bold = true } }
    h["@lsp.typemod.interface.declaration"] = { style = { bold = true, italic = false } }
    h["@lsp.typemod.enum.declaration"] = { style = { bold = true } }
    h["@lsp.typemod.type.declaration"] = { style = { bold = true } }

    h["Noise"] = { fg = colors.blue1 }
    h["LuaNoise"] = { fg = colors.dark5 }
    h["luaFuncParens"] = { fg = colors.londonHue }
    h["luaParens"] = { fg = colors.londonHue }
    h["luaBraces"] = { fg = colors.blue1 }
    h["luaFuncKeyword"] = { fg = colors.red, style = { italic = true } }


    h["CmpItemKindFunction"] = "Function"
    h["CmpItemKindProperty"] = "@property"
    h["CmpItemKindField"] = "@property"
    h["CmpItemKindClass"] = "@class"
    h["CmpItemKindInterface"] = "@lsp.type.interface"
    h["CmpItemKindEnum"] = "@lsp.type.enum"
    h["CmpItemKindVariable"] = "@variable"
    h["CmpItemKindConstant"] = "@lsp.mod.readonly"
    h["CmpItemKindKeyword"] = "@keyword"

    local black = colors.black
    --highlights["NavicIconsFile"] = {}
    --highlights["NavicIconsModule"] = {}
    --highlights["NavicIconsNamespace"] = {}
    h["NavicIconsPackage"] = h("Statement", black)
    h["NavicIconsClass"] = h("@class", black)
    h["NavicIconsMethod"] = h("@method", black)
    h["NavicIconsProperty"] = h("@property", black)
    h["NavicIconsField"] = h("@field", black)
    h["NavicIconsConstructor"] = h("@constructor", black)
    h["NavicIconsEnum"] = h("@lsp.type.enum", black)
    h["NavicIconsInterface"] = h("@lsp.type.interface", black)
    h["NavicIconsFunction"] = h("@function", black)
    h["NavicIconsVariable"] = h("@variable", black)
    h["NavicIconsConstant"] = h("@lsp.mod.readonly", black)
    h["NavicIconsString"] = h("String", black)
    h["NavicIconsNumber"] = h("Number", black)
    h["NavicIconsBoolean"] = h("@boolean", black)
    h["NavicIconsArray"] = h("@property", black)
    h["NavicIconsObject"] = h("@property", black)
    --highlights["NavicIconsKey"] = ""
    --highlights["NavicIconsNull"] = {}
    h["NavicIconsEnumMember"] = h("@lsp.type.enum", black)
    h["NavicIconsStruct"] = h("Structure", black)
    h["NavicIconsEvent"] = h("CmpItemKindEvent", black)
    h["NavicIconsOperator"] = h("@operator", black)
    --highlights["NavicIconsTypeParameter"] = {}
    h["NavicText"] = { bg = black }
    h["NavicSeparator"] = h(colors.red1, black)
  end,
  styles = {
    ["comments"] = { italic = false },
  }
}
y = [[%<%#NavicIconsClass# 󰠱 %*%#NavicText#Logger%*%#NavicSeparator#> %*%#NavicIconsProperty#󰜢 %*%#NavicText#name%*]]

vim.cmd([[
  augroup reload_colorscheme
  autocmd!
  autocmd BufWritePost tokyonight.lua nested source <afile>
  augroup end
  ]])

vim.cmd [[colorscheme tokyonight-night]]
