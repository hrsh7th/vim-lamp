let s:floatwin_id = 0

let s:namespace = has('nvim') ? 'nvim' : 'vim'

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

"
" lamp#view#floatwin#import
"
function! lamp#view#floatwin#import() abort
  return s:Floatwin
endfunction

let s:Floatwin = {}

"
" new
"
function! s:Floatwin.new(option) abort
  let s:floatwin_id += 1
  let l:bufname = printf('lamp-floatwin-%s.lamp_floatwin', s:floatwin_id)
  let l:bufnr = bufnr(l:bufname, v:true)
  call setbufvar(l:bufnr, '&buflisted', v:true)
  call setbufvar(l:bufnr, '&filetype', 'lamp_floatwin')
  call setbufvar(l:bufnr, '&buftype', 'nofile')
  return extend(deepcopy(s:Floatwin), {
        \   'bufnr': l:bufnr,
        \   'max_width': get(a:option, 'max_width', &columns / 3),
        \   'max_height': get(a:option, 'max_height', &lines / 2),
        \   'screenpos': [0, 0],
        \   'contents': []
        \ })
endfunction

"
" show_tooltip
"
function! s:Floatwin.show_tooltip(screenpos, contents) abort
  call self.show(
        \   lamp#view#floatwin#fix_position_as_tooltip(
        \     a:screenpos,
        \     self.get_width(a:contents),
        \     self.get_height(a:contents)
        \   ),
        \   a:contents
        \ )
endfunction

"
" show
"
function! s:Floatwin.show(screenpos, contents) abort
  let self.screenpos = a:screenpos
  let self.contents = a:contents

  " create lines.
  let l:lines = []
  for l:content in a:contents
    let l:lines += l:content.lines
    if l:content isnot a:contents[-1]
      let l:lines += [repeat("\u2015", self.get_width(a:contents) / 2)]
    endif
  endfor

  " write lines
  " NOTE: vim's popup window is not display texts if write before show.
  if has('nvim')
    call lamp#view#floatwin#{s:namespace}#write(self, l:lines)
  endif

  " show or move
  call lamp#view#floatwin#{s:namespace}#show(self)
  call setwinvar(self.winnr(), '&wrap', 1)
  call setwinvar(self.winnr(), '&conceallevel', 3)

  " write lines
  " NOTE: vim's popup window is not display texts if write before show.
  if !has('nvim')
    call lamp#view#floatwin#{s:namespace}#write(self, l:lines)
  endif
endfunction

"
" hide
"
function! s:Floatwin.hide() abort
  call lamp#view#floatwin#{s:namespace}#hide(self)
endfunction

"
" enter
"
function! s:Floatwin.enter() abort
  call lamp#view#floatwin#{s:namespace}#enter(self)
endfunction

"
" is_showing
"
function! s:Floatwin.is_showing() abort
  return lamp#view#floatwin#{s:namespace}#is_showing(self)
endfunction

"
" winnr
"
function! s:Floatwin.winnr() abort
  return lamp#view#floatwin#{s:namespace}#winnr(self)
endfunction

"
" get_width
"
function! s:Floatwin.get_width(contents) abort
  let l:width = 0
  for l:content in a:contents
    let l:width = max([l:width] + map(copy(l:content.lines), { k, v -> strdisplaywidth(v) }))
  endfor

  if self.max_width != -1
    return max([min([self.max_width, l:width]), 1])
  endif
  return max([l:width, 1])
endfunction

"
" get_height
"
function! s:Floatwin.get_height(contents) abort
  let l:width = self.get_width(a:contents)

  let l:height = len(a:contents) - 1
  for l:content in a:contents
    for l:line in l:content.lines
      let l:height += max([1, float2nr(ceil(strdisplaywidth(l:line) / str2float('' . l:width)))])
    endfor
  endfor

  if self.max_height != -1
    return max([min([self.max_height, l:height]), 1])
  endif
  return max([l:height, 1])
endfunction

