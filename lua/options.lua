require("nvchad.options")

-- add yours here!

local o = vim.o
--o.cursorlineopt = "both" -- to enable cursorline!
o.wrap = false
o.scrolloff = 5
o.mousescroll = "ver:5,hor:5"
o.sidescrolloff = 15
o.cursorline = true
o.showmatch = true
o.mouse = "a"
o.exrc = true
o.virtualedit = "block"
o.mousemoveevent = true

-- Indentation avec espaces uniquement
o.expandtab = true
o.tabstop = 2
o.shiftwidth = 2
o.softtabstop = 2
o.autoindent = true

vim.g.clipboard = ""

-- Options pour nvim-ufo (folding)
o.foldcolumn = "1"
o.foldlevel = 99
o.foldlevelstart = 99
o.foldenable = true
o.fillchars = "eob: ,fold: ,foldopen:▾,foldsep: ,foldclose:▸"
