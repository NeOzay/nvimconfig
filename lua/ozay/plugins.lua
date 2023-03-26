require "ozay.tokyonight"
require "neodev".setup{}
require "ozay.cmp"
--require "nvim-navic".setup{highlight = true}
require "ozay.lspconfig"
require "ozay.lspsaga"
require "ozay.lualine"
require "ozay.autopairs"
require "fidget".setup{
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
require "trouble".setup{}
require "ozay.autocommand"
require "ozay.telescope"
require "neoclip".setup()
require "ozay.treesitter"

-- init.lua
