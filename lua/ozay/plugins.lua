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
require "trouble".setup {}
require "ozay.autocommand"
require "ozay.telescope"
require "neoclip".setup()
require "ozay.treesitter"
require('guess-indent').setup {}
require("ozay.neo-tree")
--require "ozay.bufferline"
--require "ozay.barbar"
--require "ozay.tabby"
--require('tabline').setup({
--    show_index = false,        -- show tab index
--    show_modify = false,       -- show buffer modification indicator
--    show_icon = true,        -- show file extension icon
--    modify_indicator = '[+]', -- modify indicator
--    no_name = 'No name',      -- no name buffer name
--    brackets = { '', '' },  -- file name brackets surrounding
--})
--require "ozay.cokeline"
require "ozay.tabline-framework"
require("indentmini").setup({
  char = "|",
  exclude = {
    "erlang",
    "markdown",
  }
})
vim.cmd.highlight("default link IndentLine Comment")
-- init.lua
