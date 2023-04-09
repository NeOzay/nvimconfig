require("neo-tree").setup({
  filesystem = {
    window = {
      popup = {
        -- settings that apply to float position only
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
        -- This effectively hides the cursor
        vim.cmd 'highlight! Cursor blend=100'
      end
    },
    {
      event = "neo_tree_buffer_leave",
      handler = function()
        -- Make this whatever your current Cursor highlight group is.
        --vim.notify("leave", vim.log.levels.ERROR)
        --vim.cmd 'highlight Cursor blend=0'
      end
    }
  },
  window = {
    mappings = {
      ["<Right>"] = "toggle_node"
    }
  }
})

vim.api.nvim_set_keymap(
  "n",
  "<space>fx",
  ":NeoTreeFloatToggle<CR>",
  { noremap = true }
)
vim.cmd[[
augroup ozay_neo_tree
autocmd!
autocmd BufLeave neo-tree* hi Cursor blend=0
augroup END
]]