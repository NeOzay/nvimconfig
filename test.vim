function! GetCaracter() abort
	echo getline(".")
	return getline('.')[col('.')-2]
endfunction

function! Getrline(n) abort
	return getline(line(".")+a:n)
endfunction

let g:test = []
function! Test() abort
	call add(g:test, v:char)
endfunction

augroup InterceptKeyPress
    autocmd!
    autocmd InsertCharPre * call Test()
		autocmd InsertLeave * echo g:test|let g:test = []
augroup END
