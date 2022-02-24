syntax sync fromstart
syntax match testString /"[^"]*"/

syntax match txtField /\.\@<=\(\k\+\)\@>\s*\%([^({"']\)\@=/ 
syntax match txtFuncCall /\k\+\%(\s*[{('"]\)\@=/


hi link testString String
hi link txtField Statement
hi link txtFuncCall Function

