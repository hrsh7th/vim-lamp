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
  let l:pos = getpos('.')
  let l:scroll_x = (l:pos[2] + l:pos[3]) - wincol()
  let l:scroll_y = l:pos[1] - winline()
  let l:winpos = win_screenpos(win_getid())
  return [l:winpos[0] + (a:line - l:scroll_y) - 1, l:winpos[1] + (a:col - l:scroll_x) - 1]
endfunction

