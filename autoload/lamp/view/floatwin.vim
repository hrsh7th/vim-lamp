"
" lamp#view#floatwin#import
"
function! lamp#view#floatwin#import() abort
  if has('nvim')
    return lamp#view#floatwin#nvim#import()
  endif
    return lamp#view#floatwin#vim#import()
endfunction

"
" lamp#view#floatwin#fix_position_as_tooltip
"
function! lamp#view#floatwin#fix_position_as_tooltip(screenpos, width, height) abort
  let l:screenpos = copy(a:screenpos)
  let l:screenpos[0] -= 1
  let l:screenpos[1] -= 1

  " fix height.
  if l:screenpos[0] - a:height >= 0
    let l:screenpos[0] -= a:height
  else
    let l:screenpos[0] += 1
  endif

  " fix width.
  if &columns < l:screenpos[1] + a:width
    let l:screenpos[1] -= l:screenpos[1] + a:width - &columns
  endif

  return l:screenpos
endfunction

"
" lamp#view#floatwin#screenpos
"
function! lamp#view#floatwin#screenpos(line, col) abort
  let l:screenpos = screenpos(win_getid(), a:line, a:col)
  return [l:screenpos.row, l:screenpos.col]
endfunction

