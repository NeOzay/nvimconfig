if has('termguicolors') 
	set termguicolors 
endif 

let g:sonokai_style = 'shusia' 
"unlet g:sonokai_style 
if has("win32")
	let g:sonokai_enable_italic = 1 
	let g:sonokai_disable_italic_comment = 0
else
	let g:sonokai_enable_italic = 0
	let g:sonokai_disable_italic_comment = 1 
endif
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
hi CocSemGlobalVariable guifg=#8a4dab
hi link CocSemDefinitionVariable BlueItalic 
hi link CocSemClass Blue
hi link CocSemDeclarationClass GreenItalic
hi link CocSemProperty luaField
