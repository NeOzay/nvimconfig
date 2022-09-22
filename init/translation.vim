function! <SID>PrintGivenRange() range
	exe a:firstline.",".a:lastline."y a"
	if ! exists("s:temp")
		echo "make temp"
		let s:temp = bufadd('translation')
		call bufload(s:temp)
		"echo s:temp
		call setbufvar(s:temp, '&buftype', 'nofile')
		call setbufvar(s:temp, '&ft', 'help')
	endif
	if ! get(win_findbuf(s:temp),0)
		exe "tab sb ".s:temp
		let s:trwin = win_findbuf(s:temp)[0]
		call win_execute(s:trwin, "set wrap | set linebreak | set nonumber | set norelativenumber")
	endif
	call win_gotoid(s:trwin)
	call win_execute(s:trwin, "%d _")
	call win_gotoid(s:trwin)
	"echo @a
	call setbufline(s:temp, 1, @a)
	normal ggVG rgg
	echo g:translator_status
	while g:translator_status == "translating"
		sleep 100m
	endwhile
	call win_execute(s:trwin, "silent %s/\\\\\"/\"/g")
endfunction

command! -range PassRange <line1>,<line2>call <SID>PrintGivenRange()

""" Configuration example
" Echo translation in the cmdline
nmap <silent> <Leader>t <Plug>Translate
vmap <silent> <Leader>t :PassRange<CR>
" Display translation in a window
nmap <silent> <Leader>w <Plug>TranslateW
vmap <silent> <Leader>w <Plug>TranslateWV
" Replace the text with translation
nmap <silent> <Leader>r <Plug>TranslateR
vmap <silent> <Leader>r <Plug>TranslateRV
" Translate the text in clipboard
nmap <silent> <Leader>x <Plug>TranslateX
