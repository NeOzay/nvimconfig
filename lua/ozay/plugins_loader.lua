vim.cmd [[packadd packer.nvim]]
-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins_loader.lua source <afile> | PackerSync
  augroup end
]])

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

-- Have packer use a popup window
packer.init({
  display = {
    open_fn = function()
      return require('packer.util').float({ border = 'single' })
    end
  }
}
)

local function one_monokai()
  require "one_monokai".setup {
    transparent = true,
    colors = {},
    themes = function(colors)
      return {}
    end,
  }
end

-- Install your plugins here
return packer.startup(function(use)
  -- Only required if you have packer configured as `opt`
  use "wbthomason/packer.nvim"
  use "nvim-lua/plenary.nvim"
  use "Konfekt/vim-alias"

  --use "EdenEast/nightfox.nvim"
  --use{"cpea2506/one_monokai.nvim", config = one_monokai}
  --use 'https://gitlab.com/__tpb/monokai-pro.nvim'
  --use{"sainnhe/sonokai"}
  use 'folke/tokyonight.nvim'
  use "folke/neodev.nvim"
  --use "vim-airline/vim-airline"
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true },
    config = function ()
      require("ozay.evil_lualine")
      --require"lualine".setup{option = {theme = "evil_lualine"}}
    end
  }
  use { "windwp/nvim-autopairs", config = function() --[[require"ozay/autopairs"]] end }
  use "mroavi/vim-pasta"

  use { "neovim/nvim-lspconfig", config = function() require "ozay/lspconfig" end }

  use "onsails/lspkind.nvim"
  use 'hrsh7th/nvim-cmp' -- Autocompletion plugin
  use 'hrsh7th/cmp-nvim-lsp' -- LSP source for nvim-cmp
  use 'saadparwaiz1/cmp_luasnip' -- Snippets source for nvim-cmp
  use 'L3MON4D3/LuaSnip' -- Snippets plugin
  use {'j-hui/fidget.nvim', config = function() require "fidget".setup() end}

end)
