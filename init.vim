let mapleader = ' '
"finish 
set langmenu=en_US 
let $LANG = 'en_US' 
source $VIMRUNTIME/delmenu.vim 
source $VIMRUNTIME/menu.vim 

filetype plugin on 
syntax on 

scriptencoding utf-8 

call plug#begin() 
"Plug 'lifepillar/vim-mucomplete' 
"Plug 'luochen1990/rainbow' 
Plug 'Konfekt/vim-alias' 
"Plug 'jiangmiao/auto-pairs' 

Plug 'Yggdroot/indentLine'
"Plug 'lukas-reineke/indent-blankline.nvim'

Plug 'folke/lua-dev.nvim'
"Plug 'neovim/nvim-lspconfig' 

"Plug 'hrsh7th/cmp-nvim-lsp' 
"Plug 'hrsh7th/cmp-buffer' 
"Plug 'hrsh7th/cmp-path' 
"Plug 'hrsh7th/cmp-cmdline' 
"Plug 'hrsh7th/nvim-cmp' 
"Plug 'neovim/nvim-lspconfig' 
"Plug 'neoclide/jsonc.vim'

" For vsnip users. 
"Plug 'hrsh7th/cmp-vsnip' 
"Plug 'hrsh7th/vim-vsnip' 

"Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' } 
"Plug 'nvim-treesitter/playground' 

" Use release branch (recommend)

Plug 'Shougo/neco-vim'
Plug 'neoclide/coc-neco'

Plug 'neoclide/coc.nvim', {'branch': 'release'}

Plug 'vim-airline/vim-airline' 

Plug 'windwp/nvim-autopairs' 

Plug 'sainnhe/sonokai' 

Plug 'alec-gibson/nvim-tetris'
Plug 'aserowy/tmux.nvim'
Plug 'mroavi/vim-pasta'
call plug#end() 

let $CONFIG = $HOME."/.config/nvim"

lua << EOF 

--require "ozay/cmp" 
require "ozay/autopairs" 
--require "ozay/indentLine"
--require "ozay/treesitter" 
require "ozay/tmux"
function _G.put(...) 
	local objects = {} 
	for i = 1, select('#', ...) do 
		local v = select(i, ...) 
		table.insert(objects, vim.inspect(v)) 
	end 

	print(table.concat(objects, '\n')) 
	return ... 
end 

EOF 

source $CONFIG/init/coc.vim
source $CONFIG/init/colorscheme.vim

" Set internal encoding of vim, not needed on neovim, since coc.nvim using some
" unicode characters in the file autoload/float.vim
set encoding=utf-8

" Give more space for displaying messages.
set cmdheight=1

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c


set fileformats=unix,dos,mac 

" TextEdit might fail if hidden is not set. 
set hidden 

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("nvim-0.5.0") || has("patch-8.1.1564")
	" Recently vim can merge signcolumn and number column into one
	set signcolumn=number
else
	set signcolumn=yes
endif


set virtualedit=block 
set whichwrap=b,s,[,],<,> 

set ignorecase 
set smartcase 
set formatoptions+=mMj 

set number 
set rnu
"set omnifunc=syntaxcomplete#Complete 

set mouse=a 

set cursorline 
set autoindent 
set noexpandtab 
set tabstop=2 
set shiftwidth=2 
set smartindent 

set nowrap 
set scrolloff=2 
set sidescrolloff=15 

set foldmethod=indent
set foldlevelstart=20

let g:vimsyn_embed = 'l' 

au BufRead,BufNewFile *.tic set filetype=lua
"set t_Co=256 
"set termguicolors 

lua vim.diagnostic.config{signs=false}

let $SCRIPT = $HOME."/internalStorage/Script"
let g:rainbow_active = 1 "set to 0 if you want to enable it later via :RainbowToggle


"set completeopt+=menuone
"set completeopt+=noinsert
set completeopt=menu,menuone,noselect


"set shortmess+=c   " Shut off completion messages 
"set belloff+=ctrlg " Add only if Vim beeps during completion 

"let g:mucomplete#enable_auto_at_startup = 1 

function! SynGroup()
	let l:y = col('.')
	let l:s = synID(line('.'), col('.'), 1)
	echo synIDattr(l:s, 'name') . ' -> ' . synIDattr(synIDtrans(l:s), 'name').l:y
endfun

"smart indent when entering insert mode with i on empty lines 
function! IndentWithI()
	if len(getline('.')) == 0
		return "\"_cc"
	else
		return "i"
	endif
endfunction
noremap <expr> i IndentWithI()

if &wildoptions =~ "pum"
	cnoremap <expr> <up> pumvisible() ? "<C-p>" : "<up>"
	cnoremap <expr> <down> pumvisible() ? "<C-n>": "<down>"
endif
nnoremap  :w 
nnoremap <expr> <leader>j SynGroup()
nnoremap <SPACE> <Nop>

nnoremap  <leader>o o<Up>
nnoremap  <leader>p O<Down>
nnoremap  <leader>c ciw

nnoremap gp p`[v`]=^
