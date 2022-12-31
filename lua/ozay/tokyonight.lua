local palette = require "tokyonight.colors"
local tokyonight = require "tokyonight"


local sonokaiPalette = { black = '#1a181a',
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

  end,
  on_highlights = function(highlights, colors)
    highlights["@function"] = { fg = colors.green}
    highlights["String"] = {fg = colors.cyan}
    highlights["Statement"] = {fg = colors.red}
    highlights["Type"] = { fg = colors.red}
    highlights["@type"] = { fg = colors.blue1}
    highlights["@method"] = { fg = colors.green}
    highlights["@property"] = { fg = "#afaf87" }
    highlights["luaBraces"] = {fg = colors.blue1}
  end
}