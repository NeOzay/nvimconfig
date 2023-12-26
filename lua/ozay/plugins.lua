require "neodev".setup {}
require "ozay.tokyonight"
require "ozay.cmp"
require "ozay.navic"
require "ozay.lspconfig"
require "ozay.lspsaga"
require "ozay.lualine"
require "ozay.autopairs"
require "fidget".setup {
  window = {
    blend = 0,
    border = "rounded"
  }
}
--require "colorizer".setup{
--  user_default_options = {
--    names = false
--  }
--}
require('nvim-highlight-colors').setup {}

require"ozay.trouble"
require "ozay.autocommand"
require "ozay.telescope"
require "neoclip".setup()
require "ozay.treesitter"
require('guess-indent').setup {}
require("ozay.neo-tree")
require "ozay.cokeline"
require('ufo').setup()
require('mini.indentscope').setup({
  options = {
   try_as_border = true
  }
})
--require('indentmini').setup()
require("translate").setup({})

-- This module contains a number of default definitions
local rainbow_delimiters = require 'rainbow-delimiters'

vim.g.rainbow_delimiters = {
    strategy = {
        [''] = rainbow_delimiters.strategy['global'],
        --typescript = rainbow_delimiters.strategy['local'],
    },
    query = {
        [''] = 'rainbow-delimiters',
        lua = 'rainbow-blocks',
    },
    highlight = {
        'RainbowDelimiterRed',
        'RainbowDelimiterYellow',
        'RainbowDelimiterBlue',
        'RainbowDelimiterOrange',
        'RainbowDelimiterGreen',
        'RainbowDelimiterViolet',
        'RainbowDelimiterCyan',
    },
}
require("ozay.miniclue")
-- init.lua
