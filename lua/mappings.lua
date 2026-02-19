-- require("nvchad.mappings")
local utils = require("utils")

local map = vim.keymap.set
local del = vim.keymap.del

-- Nvchad mappings
map("i", "<C-b>", "<ESC>^i", { desc = "move beginning of line" })
map("i", "<C-e>", "<End>", { desc = "move end of line" })
map("i", "<C-h>", "<Left>", { desc = "move left" })
map("i", "<C-l>", "<Right>", { desc = "move right" })
map("i", "<C-j>", "<Down>", { desc = "move down" })
map("i", "<C-k>", "<Up>", { desc = "move up" })

-- map("n", "<C-h>", "<C-w>h", { desc = "switch window left" })
-- map("n", "<C-l>", "<C-w>l", { desc = "switch window right" })
-- map("n", "<C-j>", "<C-w>j", { desc = "switch window down" })
-- map("n", "<C-k>", "<C-w>k", { desc = "switch window up" })

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "general clear highlights" })

map("n", "<C-s>", "<cmd>w<CR>", { desc = "general save file" })
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "general copy whole file" })

map("n", "<leader>n", "<cmd>set nu!<CR>", { desc = "toggle line number" })
map("n", "<leader>rn", "<cmd>set rnu!<CR>", { desc = "toggle relative number" })
map("n", "<leader>ch", "<cmd>NvCheatsheet<CR>", { desc = "toggle nvcheatsheet" })

map({ "n", "x" }, "<leader>fm", function()
	require("conform").format({ lsp_fallback = true })
end, { desc = "general format file" })

-- Comment
map("n", "<leader>/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "toggle comment", remap = true })

-- nvimtree
-- map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
-- map("n", "<leader>e", "<cmd>NvimTreeFocus<CR>", { desc = "nvimtree focus window" })

-- -- terminal
-- map("t", "<C-x>", "<C-\\><C-N>", { desc = "terminal escape terminal mode" })
--
-- -- new terminals
-- map("n", "<leader>h", function()
--   require("nvchad.term").new { pos = "sp" }
-- end, { desc = "terminal new horizontal term" })
--
-- map("n", "<leader>v", function()
--   require("nvchad.term").new { pos = "vsp" }
-- end, { desc = "terminal new vertical term" })
--
-- -- toggleable
-- map({ "n", "t" }, "<A-v>", function()
--   require("nvchad.term").toggle { pos = "vsp", id = "vtoggleTerm" }
-- end, { desc = "terminal toggleable vertical term" })
--
-- map({ "n", "t" }, "<A-h>", function()
--   require("nvchad.term").toggle { pos = "sp", id = "htoggleTerm" }
-- end, { desc = "terminal toggleable horizontal term" })
--
-- map({ "n", "t" }, "<A-i>", function()
--   require("nvchad.term").toggle { pos = "float", id = "floatTerm" }
-- end, { desc = "terminal toggle floating term" })

-- whichkey
map("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "whichkey all keymaps" })

map("n", "<leader>wk", function()
	vim.cmd("WhichKey " .. vim.fn.input("WhichKey: "))
end, { desc = "whichkey query lookup" })

-- add yours here --

-- global lsp mappings
map("n", "<leader>ds", vim.diagnostic.setloclist, { desc = "LSP diagnostic loclist" })

-- del("n", "<leader>e")
-- del("n", "<C-n>")

map("n", ";", ":", { desc = "CMD enter command mode" })
map("n", "<C-j>", "<cmd>Inspect<CR>")
map("n", "gl", vim.diagnostic.open_float, { desc = "Diagnostic sous le curseur" })
map("n", "<leader>o", "o<Esc>k")
map("n", "<leader>O", "O<Esc>j")
map("n", "<leader>cc", "ciw")
map("n", "<leader>ee", "<Cmd>Neotree position=float<CR>")
map("n", "<leader>ec", "<Cmd>Neotree reveal=true position=float<CR>")
map("n", "<leader>eb", "<Cmd>Neotree source=buffers position=float<CR>")

-- map({ "n", "v" }, "<C-i>", "k", { desc = "move up" })
-- map({ "n", "v" }, "<C-k>", "j", { desc = "move down" })
-- map({ "n", "v" }, "<C-j>", "h", { desc = "move left" })
-- map({ "n", "v" }, "<C-l>", "l", { desc = "move right" })
map("n", "<M-Left>", "<C-w>h", { desc = "switch window left" })
map("n", "<M-h>", "<C-w>h", { desc = "switch window left" })
map("n", "<M-Right>", "<C-w>l", { desc = "switch window right" })
map("n", "<M-l>", "<C-w>l", { desc = "switch window right" })
map("n", "<M-Down>", "<C-w>j", { desc = "switch window down" })
map("n", "<M-j>", "<C-w>j", { desc = "switch window down" })
map("n", "<M-Up>", "<C-w>k", { desc = "switch window up" })
map("n", "<M-k>", "<C-w>k", { desc = "switch window up" })

map("i", "jk", "<ESC>")

-- Auto-indent quand on entre en mode insertion sur une ligne vide
map("n", "i", function()
	if utils.current_line_is_blanc() then
		return [["_cc]]
	else
		return "i"
	end
end, { expr = true, desc = "Insert avec auto-indent" })

map("n", "a", function()
	if utils.current_line_is_blanc() then
		return [["_cc]]
	else
		return "a"
	end
end, { expr = true, desc = "Append avec auto-indent" })

map("n", "A", function()
	if utils.current_line_is_blanc() then
		return [["_cc]]
	else
		return "A"
	end
end, { expr = true, desc = "Append fin de ligne avec auto-indent" })

map("i", "<tab>", function()
	if utils.current_line_is_blanc() then
		return [[<C-O>"_cc]]
	else
		return "<tab>"
	end
end, { expr = true })
-- vim.keymap.set("n", "<LeftDrag>", "<Nop>")
-- vim.keymap.set("n", "<LeftMouse>", "<Nop>")
-- vim.keymap.set("v", "<LeftDrag>", "<Nop>")
