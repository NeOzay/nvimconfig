require("nvchad.mappings")

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("n", "<C-j>", "<cmd>Inspect<CR>")
map("n", "gl", vim.diagnostic.open_float, { desc = "Diagnostic sous le curseur" })
map("n", "<leader>o", "o<Esc>")
map("n", "<leader>O", "O<Esc>")
map("n", "<leader>cc", "ciw")
map("n", "<leader>e", "<Cmd>Neotree float<CR>")

map("i", "jk", "<ESC>")

-- Trouble.nvim mappings (voir aussi lazy keys dans plugins/init.lua)
-- <leader>xx - Toggle diagnostics
-- <leader>xX - Buffer diagnostics
-- <leader>cs - Symbols
-- <leader>cl - LSP definitions/references
-- <leader>xL - Location list
-- <leader>xQ - Quickfix list

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
