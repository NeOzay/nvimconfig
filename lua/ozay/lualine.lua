local lualine = require "lualine"
--local winbar = require('lspsaga.symbolwinbar')
local navic = require "nvim-navic"

local setting = {
  options = {
    icons_enabled = true,
    theme = 'tokyonight',
    component_separators = { left = '', right = '' },
    section_separators = { left = '', right = '' },
    disabled_filetypes = {
      statusline = {},
      winbar = {},
    },
    ignore_focus = {},
    always_divide_middle = true,
    globalstatus = false,
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
    }
  },
  sections = {
    lualine_a = { { 'mode', fmt = function(str) return str:sub(1, 1) end } },
    lualine_b = {},
    lualine_c = { 'filename' },
    lualine_x = { 'filetype' },
    lualine_y = {},
    lualine_z = { 'location' }
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { 'filename' },
    lualine_x = { 'location' },
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {
  },

  winbar = {
    lualine_c = { {
      --function()
      --  return winbar:get_winbar() or ""
      --end
      function()
        local location = navic.is_available() and navic.get_location() or ">"
        local bar = location ~= "" and location or ">"
        --vim.notify(bar)
        return bar
      end,
      cond = function()
        return navic.is_available()
      end,
      fmt = function (str)
        return str.."%<%#lualine_c_normal#"
      end
    } },
    lualine_y = { {"diagnostics", on_click = function ()
      vim.cmd[[Trouble document_diagnostics]]
    end} }
  },
  inactive_winbar = {},
  extensions = {}
}
lualine.setup(setting)
