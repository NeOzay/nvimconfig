vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46/"
vim.g.mapleader = " "

---@return any, boolean
function pRequire(module)
	local status, lib = pcall(require, module)
	if not status then
		vim.notify("Failed to load " .. module .. "\n\n" .. lib, vim.log.levels.WARN)
		return nil, status
	end
	return lib, status
end

local UserAutocmds = vim.api.nvim_create_augroup("UserAutocmds", { clear = true })

---@param event vim.api.keyset.events|vim.api.keyset.events[]
---@param opts vim.api.keyset.create_autocmd
---@return integer
function Userautocmd(event, opts)
	opts = opts or {}
	opts.group = opts.group or UserAutocmds
	return vim.api.nvim_create_autocmd(event, opts)
end

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
	local repo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath })
end

vim.opt.rtp:prepend(lazypath)

---@type LazyConfig
local lazy_config = require("lazy-conf")

-- load plugins
require("lazy").setup({
	{
		"NvChad/NvChad",
		lazy = false,
		branch = "v2.5",
		import = "nvchad.plugins",
	},

	{ import = "plugins.aerial" },
	{ import = "plugins.auto-pairs" },
	{ import = "plugins.blink-cmp" },
	{ import = "plugins.cokeline" },
	{ import = "plugins.conform" },
	{ import = "plugins.copilot" },
	{ import = "plugins.dap" },
	{ import = "plugins.codediff" },
	{ import = "plugins.codecompanion" },
	{ import = "plugins.fidget" },
	{ import = "plugins.gitsigns" },
	{ import = "plugins.harpoon" },
	{ import = "plugins.hover" },
	{ import = "plugins.hover-translator" },
	{ import = "plugins.illuminate" },
	{ import = "plugins.indent-blankline" },
	{ import = "plugins.lspconfig" },
	{ import = "plugins.lsp-endhints" },
	{ import = "plugins.navic" },
	{ import = "plugins.markview" },
	{ import = "plugins.neo-tree" },
	{ import = "plugins.neogit" },
	{ import = "plugins.nvim-cmp" },
	{ import = "plugins.persistence" },
	{ import = "plugins.satellite" },
	{ import = "plugins.schemastore" },
	{ import = "plugins.statuscol" },
	{ import = "plugins.telescope" },
	{ import = "plugins.treesitter" },
	{ import = "plugins.treesitter-context" },
	{ import = "plugins.treesitter-textobjects" },
	{ import = "plugins.trouble" },
	{ import = "plugins.snacks" },
	{ import = "plugins.ufo" },
	{ "lambdalisue/vim-suda", lazy = false },
	{ import = "plugins.wezterm-types" },
}, lazy_config)

require("nvchad.plugins")

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require("options")
require("autocmds")
require("cmd")
require("highlights")

vim.schedule(function()
	require("mappings")
end)
