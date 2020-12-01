let s:floatwin_id = 0
let s:floatwins = {}

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
" lamp#view#floatwin#show
"
function! lamp#view#floatwin#configure(name, config) abort
  if !has_key(s:floatwins, a:name)
    let s:floatwins[a:name] = s:Floatwin.new(a:config)
  else
    for [l:key, l:value] in items(a:config)
      let s:floatwins[a:name][l:key] = l:value
    endfor
  endif
endfunction

"
" lamp#view#floatwin#get
"
function! lamp#view#floatwin#get(name) abort
  if !has_key(s:floatwins, a:name)
    let s:floatwins[a:name] = s:Floatwin.new({})
  endif
  return s:floatwins[a:name]
endfunction

"
" lamp#view#floatwin#show
"
function! lamp#view#floatwin#show(name, pos, contents, ...) abort
  let l:option = extend(get(a:000, 0, {}), {
  \   'tooltip': v:false,
  \ }, 'keep')

  if !has_key(s:floatwins, a:name)
    let s:floatwins[a:name] = s:Floatwin.new({})
  endif

  let l:target = s:floatwins[a:name]
  for [l:name, l:win] in items(s:floatwins)
    if l:win.is_keep() && l:win.is_showing() && l:target.get_priority() < l:win.get_priority()
      return
    endif
  endfor

  if !l:target.is_keep()
    for [l:name, l:win] in items(s:floatwins)
      if l:target isnot# l:win
        call l:win.hide()
      endif
    endfor
  endif

  if l:option.tooltip
    call l:target.show_tooltip(a:pos, a:contents)
  else
    call l:target.show(a:pos, a:contents)
  endif
endfunction

"
" lamp#view#floatwin#hide
"
function! lamp#view#floatwin#hide(name) abort
  if !has_key(s:floatwins, a:name)
    let s:floatwins[a:name] = s:Floatwin.new({})
  endif
  call s:floatwins[a:name].hide()
endfunction

"
" lamp#view#floatwin#is_showing
"
function! lamp#view#floatwin#is_showing(name) abort
  if !has_key(s:floatwins, a:name)
    let s:floatwins[a:name] = s:Floatwin.new({})
  endif
  return s:floatwins[a:name].is_showing()
endfunction

"
" lamp#view#floatwin#enter
"
function! lamp#view#floatwin#enter(name) abort
  if !has_key(s:floatwins, a:name)
    let s:floatwins[a:name] = s:Floatwin.new({})
  endif
  return s:floatwins[a:name].enter()
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
  call setbufvar(l:bufnr, '&buflisted', 0)
  call setbufvar(l:bufnr, '&filetype', 'lamp_floatwin')
  call setbufvar(l:bufnr, '&buftype', 'nofile')
  return extend(deepcopy(s:Floatwin), {
  \   'bufnr': l:bufnr,
  \   'max_width': get(a:option, 'max_width', &columns / 2),
  \   'max_height': get(a:option, 'max_height', &lines / 2),
  \   'priority': get(a:option, 'priority', 0),
  \   'keep': get(a:option, 'keep', v:true),
  \   'fix': get(a:option, 'fix', v:true),
  \   'screenpos': [0, 0],
  \   'contents': []
  \ })
endfunction

"
" show_tooltip
"
function! s:Floatwin.show_tooltip(screenpos, contents) abort
  let l:contents = self.fix_contents(a:contents)
  call self.show(
  \   lamp#view#floatwin#fix_position_as_tooltip(
  \     a:screenpos,
  \     self.get_width(l:contents),
  \     self.get_height(l:contents)
  \   ),
  \   l:contents
  \ )
endfunction

"
" show
"
function! s:Floatwin.show(screenpos, contents) abort
  if getcmdwintype() !=# ''
    return
  endif

  let l:contents = self.fix_contents(a:contents)
  if self.is_showing() && self.screenpos == a:screenpos && self.contents == l:contents
    return
  endif

  let self.screenpos = a:screenpos
  let self.contents = l:contents

  " create lines.
  let l:lines = []
  for l:content in a:contents
    let l:lines += l:content.lines
    if l:content isnot a:contents[-1]
      let l:lines += [repeat("\u2015", self.get_width(a:contents) / (&ambiwidth ==# 'double' ? 2 : 1))]
    endif
  endfor

  " @see ftplugin/lamp_floatwin.vim
  call setbufvar(self.bufnr, 'lamp_floatwin_lines', l:lines)

  " show or move
  call lamp#view#floatwin#{s:namespace}#show(self)
  call setwinvar(self.winid(), '&wrap', 1)
  call setwinvar(self.winid(), '&conceallevel', 2)

  " write lines
  call lamp#view#floatwin#{s:namespace}#write(self, l:lines)

  " update syntax highlight for nvim.
  " NOTE: if vim, use autocmd to apply syntax in ftplugin/lamp_floatwin.vim.
  if has('nvim') && LampFloatwinSyntaxShouldUpdate(self.bufnr)
    call lamp#view#window#do(self.winid(), { -> LampFloatwinSyntaxUpdate() })
  endif
endfunction

"
" hide
"
function! s:Floatwin.hide() abort
  if win_getid() == self.winid()
    return
  endif
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
" winid
"
function! s:Floatwin.winid() abort
  return lamp#view#floatwin#{s:namespace}#winid(self)
endfunction

"
" get_priority
"
function! s:Floatwin.get_priority() abort
  return self.priority
endfunction

"
" is_keep
"
function! s:Floatwin.is_keep() abort
  return self.keep
endfunction

"
" fix_contents
"
function! s:Floatwin.fix_contents(contents) abort
  return a:contents
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

