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
call plug#end() 

lua << EOF 

--require "ozay/cmp" 
require "ozay/autopairs" 
--require "ozay/indentLine"
--require "ozay/treesitter" 

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

if has('termguicolors') 
	set termguicolors 
endif 

let g:sonokai_style = 'shusia' 
"unlet g:sonokai_style 
let g:sonokai_enable_italic = 0 
"let g:sonokai_disable_italic_comment = 1 
let g:airline_theme = 'sonokai' 
"let g:lightline.colorscheme = 'sonokai' 
colorscheme sonokai 



hi link vimEnvvar PurpleItalic 
hi link luaFuncArgName Identifier 
hi luaField guifg=#afaf87 
hi Normal  guibg=#10120e 
hi EndOfBuffer guibg=#191a14 
autocmd FileType json syntax match Comment +\/\/.\+$+

hi clear CursorLine 


hi CocSemDocumentationComment guifg=#AB9DF2
hi CocSemDocumentationKeyword guifg=#AB9DF2
hi link CocSemParameter Identifier
hi CocSemStaticVariable guifg=#8a4dab
hi link CocSemDefinitionVariable BlueItalic 
hi link CocSemClass Blue
hi link CocSemDeclarationClass GreenItalic
hi link CocSemProperty luaField
" Set internal encoding of vim, not needed on neovim, since coc.nvim using some
" unicode characters in the file autoload/float.vim
set encoding=utf-8

" Give more space for displaying messages.
set cmdheight=1

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup

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


" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
			\ pumvisible() ? "\<C-n>" :
			\ <SID>check_back_space() ? "\<TAB>" :
			\ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
	let col = col('.') - 1
	return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
if has('nvim')
	inoremap <silent><expr> <c-space> coc#refresh()
else
	inoremap <silent><expr> <c-@> coc#refresh()
endif

" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
			\: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"


" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)


" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
	if (index(['vim','help'], &filetype) >= 0)
		execute 'h '.expand('<cword>')
	elseif (coc#rpc#ready())
		call CocActionAsync('doHover')
	else
		execute '!' . &keywordprg . " " . expand('<cword>')
	endif
endfunction

" Highlight the symbol and its references when holding the cursor.
"autocmd CursorHold * silent call CocActionAsync('highlight')


" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)



" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Remap <C-f> and <C-b> for scroll float windows/popups.
if has('nvim-0.4.0') || has('patch-8.2.0750')
	nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
	nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
	inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
	inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
	vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
	vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif


" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocActionAsync('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocActionAsync('runCommand', 'editor.action.organizeImport')

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

au BufRead,BufNewFile *.tic set filetype=lua
"set t_Co=256 
"set termguicolors 



lua vim.diagnostic.config{signs=false}

let $SCRIPT = $HOME."/internalStorage/Script"
let $CONFIG = $HOME."/.config/nvim"
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
