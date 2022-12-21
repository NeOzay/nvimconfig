
function! s:h(group, style)
	let s:ctermformat = "NONE"
	let s:guiformat = "NONE"
	if has_key(a:style, "format")
		let s:ctermformat = a:style.format
		let s:guiformat = a:style.format
	endif
	if g:monokai_term_italic == 0
		let s:ctermformat = substitute(s:ctermformat, ",italic", "", "")
		let s:ctermformat = substitute(s:ctermformat, "italic,", "", "")
		let s:ctermformat = substitute(s:ctermformat, "italic", "", "")
	endif
	if g:monokai_gui_italic == 0
		let s:guiformat = substitute(s:guiformat, ",italic", "", "")
		let s:guiformat = substitute(s:guiformat, "italic,", "", "")
		let s:guiformat = substitute(s:guiformat, "italic", "", "")
	endif
	if g:monokai_termcolors == 16
		let l:ctermfg = (has_key(a:style, "fg") ? a:style.fg.cterm16 : "NONE")
		let l:ctermbg = (has_key(a:style, "bg") ? a:style.bg.cterm16 : "NONE")
	else
		let l:ctermfg = (has_key(a:style, "fg") ? a:style.fg.cterm : "NONE")
		let l:ctermbg = (has_key(a:style, "bg") ? a:style.bg.cterm : "NONE")
	end
	execute "highlight" a:group
				\ "guifg="   (has_key(a:style, "fg")      ? a:style.fg.gui   : "NONE")
				\ "guibg="   (has_key(a:style, "bg")      ? a:style.bg.gui   : "NONE")
				\ "guisp="   (has_key(a:style, "sp")      ? a:style.sp.gui   : "NONE")
				\ "gui="     (!empty(s:guiformat) ? s:guiformat   : "NONE")
				\ "ctermfg=" . l:ctermfg
				\ "ctermbg=" . l:ctermbg
				\ "cterm="   (!empty(s:ctermformat) ? s:ctermformat   : "NONE")
endfunction

" Palettes
" --------

let s:white       = { "gui": "#E8E8E3", "cterm": "252" }
let s:white2      = { "gui": "#d8d8d3", "cterm": "250" }
let s:black       = { "gui": "#272822", "cterm": "234" }
let s:lightblack  = { "gui": "#2D2E27", "cterm": "235" }
let s:lightblack2 = { "gui": "#383a3e", "cterm": "236" }
let s:lightblack3 = { "gui": "#3f4145", "cterm": "237" }
let s:darkblack   = { "gui": "#211F1C", "cterm": "233" }
let s:grey        = { "gui": "#8F908A", "cterm": "243" }
let s:lightgrey   = { "gui": "#575b61", "cterm": "237" }
let s:darkgrey    = { "gui": "#64645e", "cterm": "239" }
let s:warmgrey    = { "gui": "#75715E", "cterm": "59" }

let s:pink        = { "gui": "#F92772", "cterm": "197" }
let s:green       = { "gui": "#A6E22D", "cterm": "148" }
let s:aqua        = { "gui": "#66d9ef", "cterm": "81" }
let s:yellow      = { "gui": "#E6DB74", "cterm": "186" }
let s:orange      = { "gui": "#FD9720", "cterm": "208" }
let s:purple      = { "gui": "#ae81ff", "cterm": "141" }
let s:red         = { "gui": "#e73c50", "cterm": "196" }
let s:purered     = { "gui": "#ff0000", "cterm": "52" }
let s:darkred     = { "gui": "#5f0000", "cterm": "52" }

let s:addfg       = { "gui": "#d7ffaf", "cterm": "193" }
let s:addbg       = { "gui": "#5f875f", "cterm": "65" }
let s:delfg       = { "gui": "#ff8b8b", "cterm": "210" }
let s:delbg       = { "gui": "#f75f5f", "cterm": "124" }
let s:changefg    = { "gui": "#d7d7ff", "cterm": "189" }
let s:changebg    = { "gui": "#5f5f87", "cterm": "60" }

let s:cyan        = { "gui": "#A1EFE4" }
let s:br_green    = { "gui": "#9EC400" }
let s:br_yellow   = { "gui": "#E7C547" }
let s:br_blue     = { "gui": "#7AA6DA" }
let s:br_purple   = { "gui": "#B77EE0" }
let s:br_cyan     = { "gui": "#54CED6" }
let s:br_white    = { "gui": "#FFFFFF" }

" Highlighting 
" ------------
hi link luaLocal Statement
hi link luaFuncKeyword Statement
hi link luaBuiltIn Type 
hi link luaFuncArgName TODO

hi luaFuncName cterm=bold ctermfg=148
hi luaDocTag ctermfg=222
hi luaField ctermfg=144
hi Operator ctermfg=168

