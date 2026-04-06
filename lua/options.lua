local o = vim.o

o.laststatus = 3
o.showmode = false
o.splitkeep = "screen"
o.number = true
o.numberwidth = 2
o.ruler = false
o.signcolumn = "yes"
o.splitbelow = true
o.splitright = true
o.timeoutlen = 400
o.undofile = true
o.updatetime = 250
o.ignorecase = true
o.smartcase = true
o.smartindent = true
vim.opt.shortmess:append("sI")
vim.opt.whichwrap:append("<>[]hl")

-- Disable default providers
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Add mason binaries to PATH
local sep = vim.fn.has("win32") ~= 0 and "\\" or "/"
local delim = vim.fn.has("win32") ~= 0 and ";" or ":"
vim.env.PATH = table.concat({ vim.fn.stdpath("data"), "mason", "bin" }, sep) .. delim .. vim.env.PATH

-- Custom options
o.wrap = false
vim.opt_global.scrolloff = 5
o.mousescroll = "ver:5,hor:5"
vim.opt_global.sidescrolloff = 15
o.cursorline = true
-- o.showmatch = true
-- o.matchtime = 1
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

o.clipboard = "unnamed"
-- vim.g.clipboard = "wl-copy"

-- Session : ne restaurer que les buffers visibles dans une fenêtre
vim.opt.sessionoptions:remove("buffers")

-- Options pour nvim-ufo (folding)
o.foldcolumn = "1"
o.foldlevel = 99
o.foldlevelstart = 99
o.foldenable = true
o.fillchars = "eob: ,fold: ,foldopen:▾,foldsep:│,foldclose:▸"
