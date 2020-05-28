"
" lamp#protocol#position#in_range
"
function! lamp#protocol#position#in_range(position, range) abort
  return lamp#protocol#position#after(a:range.start, a:position) &&
        \ lamp#protocol#position#after(a:position, a:range.end)
endfunction

"
" lamp#protocol#position#after
"
function! lamp#protocol#position#after(position1, position2) abort
  return a:position1.line < a:position2.line || (
  \   a:position1.line == a:position2.line && a:position1.character <= a:position2.character
  \ )
endfunction

"
" lamp#protocol#position#same
"
function! lamp#protocol#position#same(position1, position2) abort
  return a:position1.line == a:position2.line && a:position1.character == a:position2.character
endfunction
