local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

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

-- Install your plugins here
return packer.startup(function(use)
  -- Only required if you have packer configured as `opt`
  use "wbthomason/packer.nvim"
  use "nvim-lua/plenary.nvim"
  use "Konfekt/vim-alias"

  --use "EdenEast/nightfox.nvim"
  --use{"cpea2506/one_monokai.nvim", config = one_monokai}
  --use 'https://gitlab.com/__tpb/monokai-pro.nvim'
  use { "sainnhe/sonokai" }
  use 'folke/tokyonight.nvim'
  use "folke/neodev.nvim"
  --use "vim-airline/vim-airline"
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons' }
  }
  use { "windwp/nvim-autopairs" }
  use "mroavi/vim-pasta"

  use { "neovim/nvim-lspconfig" }

  use "onsails/lspkind.nvim"
  use 'hrsh7th/nvim-cmp'     -- Autocompletion plugin
  use 'hrsh7th/cmp-nvim-lsp' -- LSP source for nvim-cmp
  use 'hrsh7th/cmp-buffer'
  use 'FelipeLema/cmp-async-path'
  use 'saadparwaiz1/cmp_luasnip' -- Snippets source for nvim-cmp
  use 'L3MON4D3/LuaSnip'         -- Snippets plugin

  use { 'j-hui/fidget.nvim', tag = 'legacy' }
  use {
    "SmiteshP/nvim-navic",
    requires = "neovim/nvim-lspconfig"
  }
  use {
    "folke/trouble.nvim",
    requires = "kyazdani42/nvim-web-devicons",
  }
  --use 'NvChad/nvim-colorizer.lua'
  use 'brenoprata10/nvim-highlight-colors'
  use({
    "nvimdev/lspsaga.nvim",
    branch = "main",
    --after = "nvim-lspconfig",
    requires = { { "nvim-tree/nvim-web-devicons" } }
  })
  use {
    'nvim-telescope/telescope.nvim', branch = '0.1.x',
    -- or                          , branch = '0.1.x',
    requires = { { 'nvim-lua/plenary.nvim' } }
  }
  use {
    'nvim-telescope/telescope-fzf-native.nvim',
    run =
    'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build'
  }
  use {
    "AckslD/nvim-neoclip.lua",
    require = "nvim-telescope/telescope.nvim"
  }
  use { "nvim-treesitter/nvim-treesitter" }
  --use { "nvim-telescope/telescope-file-browser.nvim" }

  use {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v2.x",
    requires = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",     -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
    }
  }
  use "nmac427/guess-indent.nvim"
  --use "akinsho/bufferline.nvim"
  use { 'romgrk/barbar.nvim', requires = 'nvim-web-devicons' }
  --use 'nanozuki/tabby.nvim'
  use 'crispgm/nvim-tabline'
  use 'willothy/nvim-cokeline'
  use '~/project/tabline-framework.nvim'
  use 'nvimdev/indentmini.nvim'
  --use "lukas-reineke/indent-blankline.nvim"
  use { 'kevinhwang91/nvim-ufo', requires = 'kevinhwang91/promise-async' }
  use 'echasnovski/mini.indentscope'
  use 'uga-rosa/translate.nvim'

  use "b0o/schemastore.nvim"
  use "hiphish/rainbow-delimiters.nvim"
  if packer_bootstrap then
    packer.sync()
  end
end)
