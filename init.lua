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
	{ import = "plugins.diffview" },
	{ import = "plugins.fidget" },
	{ import = "plugins.gitsigns" },
	{ import = "plugins.harpoon" },
	{ import = "plugins.hover" },
	{ import = "plugins.hover-translator" },
	{ import = "plugins.illuminate" },
	{ import = "plugins.indent-blankline" },
	{ import = "plugins.init" },
	{ import = "plugins.lspconfig" },
	{ import = "plugins.navic" },
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
	{ import = "plugins.ufo" },
	{ "lambdalisue/vim-suda", lazy = false },
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
