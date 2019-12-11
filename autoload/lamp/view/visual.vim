"
" lamp#view#visual#range
"
function! lamp#view#visual#range() abort
  let l:start = getpos("'<")
  let l:end = getpos("'>")
  return {
        \   'start': {
        \     'line': l:start[1] - 1,
        \     'character': 0
        \   },
        \   'end': {
        \     'line': l:end[1],
        \     'character': 0
        \   }
        \ }
endfunction

