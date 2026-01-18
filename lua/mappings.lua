require("nvchad.mappings")

-- add yours here

local map = vim.keymap.set
local del = vim.keymap.del

del("n", "<leader>e")
del("n", "<C-n>")

map("n", ";", ":", { desc = "CMD enter command mode" })
map("n", "<C-j>", "<cmd>Inspect<CR>")
map("n", "gl", vim.diagnostic.open_float, { desc = "Diagnostic sous le curseur" })
map("n", "<leader>o", "o<Esc>")
map("n", "<leader>O", "O<Esc>")
map("n", "<leader>cc", "ciw")
map("n", "<leader>ee", "<Cmd>Neotree position=float<CR>")
map("n", "<leader>ec", "<Cmd>Neotree reveal=true position=float<CR>")
map("n", "<leader>eb", "<Cmd>Neotree source=buffers position=float<CR>")
map("n", "<F3>", "<cmd>Telescope find_files<cr>", { desc = "telescope find files" })

map("i", "jk", "<ESC>")

-- map({ "o", "x" }, "i.", function()
--   local line = vim.api.nvim_get_current_line()
--   local col = vim.fn.col(".") -- col est 1-based
--
--   local start = col
--   local finish = col
--
--   -- Étend à gauche
--   while start > 1 and line:sub(start - 1, start - 1):match("[%w_.]") do
--     start = start - 1
--   end
--
--   -- Étend à droite
--   while finish <= #line and line:sub(finish, finish):match("[%w_.]") do
--     finish = finish + 1
--   end
--
--   -- finish pointe maintenant sur le 1er caractère NON valide
--   finish = finish - 1
--
--   vim.fn.setpos("'<", { 0, vim.fn.line("."), start, 0 })
--   vim.fn.setpos("'>", { 0, vim.fn.line("."), finish, 0 })
--   vim.cmd("normal! gv")
-- end, { desc = "inner dotted identifier" })
-- Trouble.nvim mappings (voir aussi lazy keys dans plugins/init.lua)
-- <leader>xx - Toggle diagnostics
-- <leader>xX - Buffer diagnostics
-- <leader>cs - Symbols
-- <leader>cl - LSP definitions/references
-- <leader>xL - Location list
-- <leader>xQ - Quickfix list

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
