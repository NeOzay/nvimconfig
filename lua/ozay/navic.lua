local lspkind = require "lspkind"
local symbol_map = lspkind.symbol_map
local icons = {
  File          = " ",
  Module        = " ",
  Namespace     = " ",
  Package       = " ",
  Class         = " ",
  Method        = " ",
  Property      = " ",
  Field         = " ",
  Constructor   = " ",
  Enum          = "練",
  Interface     = "練",
  Function      = " ",
  Variable      = " ",
  Constant      = " ",
  String        = " ",
  Number        = " ",
  Boolean       = "◩ ",
  Array         = " ",
  Object        = " ",
  Key           = " ",
  Null          = "󰟢 ",
  EnumMember    = " ",
  Struct        = " ",
  Event         = " ",
  Operator      = " ",
  TypeParameter = " ",
}
for key, icon in pairs(symbol_map) do
  if icons[key] then
    icons[key] = icon.." "
  end
end
require "nvim-navic".setup {
  highlight = true,
  icons = icons,
  separator = "> "
}
