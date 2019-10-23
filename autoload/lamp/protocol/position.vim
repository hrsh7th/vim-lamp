function! lamp#protocol#position#get() abort
  let l:curpos = getcurpos()
  return {
        \   'line': l:curpos[1] - 1,
        \   'character': l:curpos[2] - 1
        \ }
endfunction

