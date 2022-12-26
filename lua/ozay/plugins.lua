require "tokyonight".setup{}
require "neodev".setup{}
require "ozay.cmp"
require "nvim-navic".setup{highlight = true}
require "ozay.lspconfig"
require "ozay.lualine"
require "ozay.autopairs"
require "fidget".setup{
  window = {
    blend = 0,
    border = "rounded"
  }
}
require "colorizer".setup{
  user_default_options = {
    names = false
  }
}
require "trouble".setup{}
