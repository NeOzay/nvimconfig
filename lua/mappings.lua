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

map({ "n", "x" }, "Y", '"+y', { desc = "yank vers le presse-papier système" })

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

-- Auto-indent après paste dans un buffer fichier réel
local function paste_with_indent(key)
	return function()
		if vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) ~= "" then
			return key .. "`[=`]"
		end
		return key
	end
end

map("n", "p", paste_with_indent("p"), { expr = true, desc = "Paste avec auto-indent" })
map("n", "P", paste_with_indent("P"), { expr = true, desc = "Paste avant avec auto-indent" })

-- Indentation en mode visuel
map("v", "<Tab>", ">gv", { desc = "Indenter la sélection" })
map("v", "<S-Tab>", "<gv", { desc = "Désindenter la sélection" })

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

local function char_type(c)
	if c == "" or c:match("%s") then
		return "space"
	end
	if c:match("[%w_]") then
		return "word"
	end
	return "punct"
end

map({ "n", "v", "o", "i" }, "<S-Right>", function()
	local mode = vim.api.nvim_get_mode().mode
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
	-- En insert le curseur est après col, donc on recule d'un cran
	local off = mode == "i" and 0 or 1
	local cur = line:sub(col + off, col + off)
	local nxt = line:sub(col + off + 1, col + off + 1)
	-- À la fin d'un mot : char non-espace dont la catégorie diffère du suivant (ou fin de ligne)
	local at_word_end = char_type(cur) ~= "space" and char_type(cur) ~= char_type(nxt)
	if mode == "i" then
		-- <C-o>w : début du mot suivant (position correcte en insert)
		-- <Esc>ea : fin du mot + append (repositionne après le dernier char, re-entre en insert)
		return at_word_end and "\x0fw" or "\x1bea"
	end
	return at_word_end and "w" or "e"
end, { expr = true })

map({ "n", "v", "o", "i" }, "<S-Left>", function()
	local mode = vim.api.nvim_get_mode().mode
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
	-- En insert le curseur est après col, donc on recule d'un cran
	local off = mode == "i" and 0 or 1
	local cur = line:sub(col + off, col + off)
	local prv = (col + off > 1) and line:sub(col + off - 1, col + off - 1) or ""
	-- Au début d'un mot : char non-espace dont la catégorie diffère du précédent (ou début de ligne)
	local at_word_start = char_type(cur) ~= "space" and char_type(cur) ~= char_type(prv)
	local key = at_word_start and "ge" or "b"
	local prefix = mode == "i" and "\x0f" or ""
	return prefix .. key
end, { expr = true })
