local utils = require("utils")

local map = vim.keymap.set
local del = vim.keymap.del

-- Base mappings
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
-- map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "general copy whole file" })

map("n", "<leader>n", "<cmd>set nu!<CR>", { desc = "toggle line number" })
map("n", "<leader>rn", "<cmd>set rnu!<CR>", { desc = "toggle relative number" })
map("n", "<leader>ts", "<cmd>StlToggle<CR>", { desc = "toggle statusline" })
map("n", "<leader>tl", "<cmd>LualineReload<CR>", { desc = "recharger lualine" })

map({ "n", "x" }, "<leader>fm", function()
	require("conform").format({ lsp_fallback = true })
end, { desc = "general format file" })

-- Comment
map("n", "<leader>/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "toggle comment", remap = true })

-- nvimtree
-- map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
-- map("n", "<leader>e", "<cmd>NvimTreeFocus<CR>", { desc = "nvimtree focus window" })


-- whichkey
map("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "whichkey all keymaps" })

map("n", "<leader>wk", function()
	vim.cmd("WhichKey " .. vim.fn.input("WhichKey: "))
end, { desc = "whichkey query lookup" })

-- add yours here --

-- del("n", "<leader>e")
-- del("n", "<C-n>")

map("n", ";", ":", { desc = "CMD enter command mode" })
map("n", "<C-j>", "<cmd>Inspect<CR>")
map("n", "<leader>X", vim.diagnostic.open_float, { desc = "Diagnostic sous le curseur" })
map("n", "<leader>o", "]<space>", { remap = true })
map("n", "<leader>O", "[<space>", { remap = true })
map("n", "<leader>cc", "ciw")

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

-- On définit les options pour le pont récursif
local recursive_map = { remap = true, silent = true }

-- Le pont pour les crochets (utilisés par 90% des plugins comme Gitsigns, Diagnostic, etc.)
-- On utilise souvent 'à' pour ']' et '^' (ou une autre touche) pour '['
map({ "n", "v", "o" }, "ç", "[", recursive_map)
map({ "n", "v", "o" }, "à", "]", recursive_map)

-- Le pont pour les accolades (Paragraphes et structures)
map({ "n", "v", "o" }, "é", "{", recursive_map)
map({ "n", "v", "o" }, "è", "}", recursive_map)
