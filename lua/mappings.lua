require("nvchad.mappings")
local utils = require("utils")

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
map("n", "<leader>fj", require("pickers").jumplist, { desc = "Telescope jumplist" })

-- map({ "n", "v" }, "<C-i>", "k", { desc = "move up" })
-- map({ "n", "v" }, "<C-k>", "j", { desc = "move down" })
-- map({ "n", "v" }, "<C-j>", "h", { desc = "move left" })
-- map({ "n", "v" }, "<C-l>", "l", { desc = "move right" })

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

map("i", "@", function()
	if utils.current_line_is_blanc() then
		return [[---@]]
	else
		return "@"
	end
end, { expr = true })

-- Cokeline mappings
map("n", "<Tab>", "<Plug>(cokeline-focus-next)", { desc = "Buffer suivant" })
map("n", "<S-Tab>", "<Plug>(cokeline-focus-prev)", { desc = "Buffer précédent" })
map("n", "<leader>bp", "<Plug>(cokeline-pick-focus)", { desc = "Pick buffer" })
map("n", "<leader>bc", "<Plug>(cokeline-pick-close)", { desc = "Pick close buffer" })
map("n", "<leader>x", "<Plug>(cokeline-pick-close)", { desc = "Pick close buffer" })

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
