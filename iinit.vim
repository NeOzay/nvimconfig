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

"Plug 'Yggdroot/indentLine'
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

"Plug 'nvim-treesitter/nvim-treesitter' ", { 'do': ':TSUpdate' }
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
Plug 'voldikss/vim-translator'

Plug 'nvim-lua/plenary.nvim'
call plug#end()

let $CONFIG = stdpath('config')


source $CONFIG/init/coc.vim
source $CONFIG/init/colorscheme.vim
source $CONFIG/init/translation.vim

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

fu! SaveSess()
	if filewritable(getcwd()."/Session.vim")
    execute 'mksession! ' . getcwd() . '/Session.vim'
	endif
endfunction

fu! RestoreSess()
	if filereadable(getcwd() . '/Session.vim')
    execute 'so ' . getcwd() . '/Session.vim'
	endif
endfunction

function! ResizeSplits()
	let g:lastcursorpos = getcurpos(".")
endfunction

function! ReplaceCursor()
	 if exists("g:lastcursorpos")
		 set winheight=25
		 wincmd =

		 "echo getcurpos(".")
		 call setpos(".", g:lastcursorpos) 
		 if exists("g:thghhh")
			 unlet g:lastcursorpos
			 unlet g:thghhh
		 else
			let g:thghhh = 1
		 endif
	 endif
endfunction

augroup OzayAuto
	autocmd!
	au BufRead,BufNewFile *.tic set filetype=lua
	au BufRead,BufNewFile *.lua setlocal formatoptions-=cro
	au VimLeave * call SaveSess()
	"au VimEnter * nested call RestoreSess()
	au WinEnter * call ResizeSplits()
	au CursorMoved * call ReplaceCursor()
augroup end
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

"" Open explorer where current file is located
"" Only for win for now.
func! File_manager() abort
	" Windows only for now
	if has("win32")
		if exists("b:netrw_curdir")
			let path = substitute(b:netrw_curdir, "/", "\\", "g")
		elseif expand("%:p") == ""
			let path = expand("%:p:h")
		else
			let path = expand("%:p")
		endif
		silent exe '!start explorer.exe /select,' .. path
	else
		echomsg "Not yet implemented!"
	endif
endfunc

command -nargs=0 OpenFileManager :call File_manager()
nnoremap <silent> gof :call File_manager()<CR>

" Function to trim extra whitespace in whole file
function! Trim()
	let l:save = winsaveview()
	keeppatterns %s/\s\+$//e
	call winrestview(l:save)
endfun

command! -nargs=0 Trim call Trim()

function! VisualSelection()
	if mode()=="v"
		let [line_start, column_start] = getpos("v")[1:2]
		let [line_end, column_end] = getpos(".")[1:2]
	else
		let [line_start, column_start] = getpos("'<")[1:2]
		let [line_end, column_end] = getpos("'>")[1:2]
	endif

	if (line2byte(line_start)+column_start) > (line2byte(line_end)+column_end)
		let [line_start, column_start, line_end, column_end] =
					\   [line_end, column_end, line_start, column_start]
	endif
	let lines = getline(line_start, line_end)
	if len(lines) == 0
		return ['']
	endif
	if &selection ==# "exclusive"
		let column_end -= 1 "Needed to remove the last character to make it match the visual selction
	endif
	if visualmode() ==# "\<C-V>"
		for idx in range(len(lines))
			let lines[idx] = lines[idx][: column_end - 1]
			let lines[idx] = lines[idx][column_start - 1:]
		endfor
	else
		let lines[-1] = lines[-1][: column_end - 1]
		let lines[ 0] = lines[ 0][column_start - 1:]
	endif
	"return lines  "use this return if you want an array of text lines
	return join(lines, "\n") "use this return instead if you need a text block
endfunction

function! TabMessage(cmd)
	redir => message
	silent execute a:cmd
	redir END
	if empty(message)
		echoerr "no output"
	else
		" use "new" instead of "tabnew" below if you prefer split windows instead of tabs
		tabnew
		setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nomodified
		silent put=message
	endif
endfunction
command! -nargs=+ -complete=command TabMessage call TabMessage(<q-args>)

if &wildoptions =~ "pum"
	cnoremap <expr> <up> pumvisible() ? "<C-p>" : "<up>"
	cnoremap <expr> <down> pumvisible() ? "<C-n>": "<down>"
endif
command! -range -nargs=0 -bar JsonTool <line1>,<line2>!python -m json.tool

nnoremap  :w
nnoremap <expr> <leader>j SynGroup()
nnoremap <SPACE> <Nop>

nnoremap  <leader>o o<Up>
nnoremap  <leader>p O<Down>
nnoremap <leader>n :tabn<cr>
nnoremap <leader>p :tabp<cr>

nnoremap <nowait> <leader>c ciw

nnoremap <silent> <leader>h :tab help <C-r><C-w><CR>
nnoremap : : <BS>
let g:translator_target_lang = "fr"
let g:translator_default_engines = ["google"]

lua << EOF
__is_log = true

--require "ozay/treesitter"
--require "ozay/cmp"
require "ozay/autopairs"
--require "ozay/indentLine"
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
