vim.g.barbar_auto_setup = false -- disable auto-setup
require 'barbar'.setup {
  -- Enable/disable current/total tabpages indicator (top right corner)
  tabpages = false,
  -- Hide inactive buffers and file extensions. Other options are `alternate`, `current`, and `visible`.
  exclude_ft = {},
  hide = {
    extensions = true,
    current = false,
  },

  icons = {
    -- Configure the base icons on the bufferline.
    buffer_index = false,
    buffer_number = false,
    button = '',
    -- Enables / disables diagnostic symbols
    --diagnostics = {
    --  [vim.diagnostic.severity.ERROR] = { enabled = true, icon = 'ﬀ' },
    --  [vim.diagnostic.severity.WARN] = { enabled = false },
    --  [vim.diagnostic.severity.INFO] = { enabled = false },
    --  [vim.diagnostic.severity.HINT] = { enabled = true },
    --},
    filetype = {
      -- Sets the icon's highlight group.
      -- If false, will use nvim-web-devicons colors
      custom_colors = false,

      -- Requires `nvim-web-devicons` if `true`
      enabled = true,
    },
    separator = { left = '', right = '' },

    -- Configure the icons on the bufferline when modified or pinned.
    -- Supports all the base icon options.
    modified = { button = '' },
    pinned = { button = '車', filename = true, separator = { right = '' } },

    -- Configure the icons on the bufferline based on the visibility of a buffer.
    -- Supports all the base icon options, plus `modified` and `pinned`.
    alternate = { filetype = { enabled = false } },
    current = { buffer_index = false },
    inactive = { button = '',  separator = { left = '', right = '' }},
    visible = { modified = { buffer_number = false } },
  },
  minimum_padding = 1,
  maximum_padding = 2,

}
