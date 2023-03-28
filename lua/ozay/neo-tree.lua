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
  }
})

vim.api.nvim_set_keymap(
  "n",
  "<space>fb",
  ":NeoTreeFloatToggle<CR>",
  { noremap = true }
)
