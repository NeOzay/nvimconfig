local getRGBH = require("ozay.util").getRGBHighlightGroup

local cursorHi ---@type {fg:string, bg:string}

require("neo-tree").setup({
  filesystem = {
    window = {
      popup = { -- settings that apply to float position only
        size = {
          height = "80%",
          width = "80%",
        },
        position = "50%", -- 50% means center it
      },
    }
  },
  event_handlers = {
      {
        event = "neo_tree_buffer_enter",
        handler = function()
          cursorHi = getRGBH("Cursor")
          -- This effectively hides the cursor
          vim.cmd 'highlight! Cursor blend=100'
        end
      },
      {
        event = "neo_tree_buffer_leave",
        handler = function()
          -- Make this whatever your current Cursor highlight group is.
          vim.cmd (('highlight! Cursor guibg=%s blend=0'):format(cursorHi.bg))
        end
      }
    },
})

vim.api.nvim_set_keymap(
  "n",
  "<space>fx",
  ":NeoTreeFloatToggle<CR>",
  { noremap = true }
)
