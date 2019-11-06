"
" lamp#protocol#position#get
"
function! lamp#protocol#position#get() abort
  let l:curpos = getcurpos()
  return {
        \   'line': l:curpos[1] - 1,
        \   'character': l:curpos[2] - 1
        \ }
endfunction

"
" lamp#protocol#position#to_vim
"
function! lamp#protocol#position#to_vim(position) abort
  return {
        \   'line': a:position.line + 1,
        \   'character': a:position.character + 1
        \ }
endfunction

"
" lamp#protocol#position#after
"
function! lamp#protocol#position#after(position1, position2) abort
  return a:position1.line <= a:position2.line && a:position1.character <= a:position2.character
endfunction

