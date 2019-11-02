let s:id = 0

function! lamp#view#floatwin#vim#import() abort
  return s:Floatwin
endfunction

let s:Floatwin = {}

"
" new.
"
function! s:Floatwin.new(option) abort
  let s:id += 1
  let l:bufname = printf('lamp-floatwin-%s.lamp_floatwin', s:id)
  let l:bufnr = bufnr(l:bufname, v:true)
  call setbufvar(l:bufnr, '&buflisted', v:true)
  call setbufvar(l:bufnr, '&filetype', 'lamp_floatwin')
  call setbufvar(l:bufnr, '&buftype', 'nofile')
  return extend(deepcopy(s:Floatwin), {
        \   'winid': v:null,
        \   'bufnr': l:bufnr,
        \   'max_width': get(a:option, 'max_width', float2nr(&columns / 3)),
        \   'max_height': get(a:option, 'max_height', float2nr(&lines / 2)),
        \   'state': {
        \     'screenpos': [0, 0],
        \     'contents': [],
        \   }
        \ })
endfunction

"
" show_tooltip.
"
" NOTE: tooltip is displaying to above of position.
"
function! s:Floatwin.show_tooltip(screenpos, contents) abort
  let l:width = self.get_width(a:contents)
  let l:height = self.get_height(a:contents)
  let l:screenpos = lamp#view#floatwin#fix_position_as_tooltip(a:screenpos, l:width, l:height)
  call self.show(screenpos, a:contents)
endfunction

"
" open.
"
function! s:Floatwin.show(screenpos, contents) abort
  let self.state.screenpos = a:screenpos
  let self.state.contents = a:contents

  let l:lines = []
  for l:content in a:contents
    let l:lines += l:content.lines
    if l:content isnot a:contents[-1]
      let l:lines += [repeat("\u2015", self.get_width(a:contents) / 2)]
    endif
  endfor

  if !self.is_showing()
    let self.winid = popup_create(self.bufnr, self.get_config())
    call setwinvar(self.winnr(), '&wrap', 1)
    call setwinvar(self.winnr(), '&conceallevel', 3)
  else
    call popup_move(self.winid, self.get_config())
  endif

  call deletebufline(self.bufnr, '^', '$')
  for l:line in reverse(l:lines)
    call appendbufline(self.bufnr, 0, l:line)
  endfor
  call deletebufline(self.bufnr, '$')
endfunction

"
" is_showing.
"
function! s:Floatwin.is_showing() abort
  call self.sync()
  return !empty(self.winid)
endfunction

"
" enter.
"
function! s:Floatwin.enter() abort
  if self.is_showing()
    execute printf('%swincmd w', self.winnr())
  endif
endfunction

"
" close
"
function! s:Floatwin.hide() abort
  if self.is_showing()
    call popup_hide(self.winid)
    let self.winid = v:null
  endif
endfunction

"
" winnr.
"
function! s:Floatwin.winnr() abort
  if self.is_showing()
    return win_id2win(self.winid)
  endif
  return -1
endfunction

"
" sync.
"
function! s:Floatwin.sync() abort
  if empty(self.winid)
    return
  endif

  if empty(popup_getpos(self.winid))
    try
      call popup_hide(self.winid)
    catch /.*/
    endtry
    let self.winid = v:null
  endif
endfunction

"
" config.
"
function! s:Floatwin.get_config() abort
  return {
        \   'line': self.state.screenpos[0] + 1,
        \   'col':  self.state.screenpos[1] + 1,
        \   'pos': 'topleft',
        \   'moved': [0, 100000],
        \   'scrollbar': 0,
        \   'maxwidth': self.get_width(self.state.contents),
        \   'maxheight': self.get_height(self.state.contents),
        \   'minwidth': self.get_width(self.state.contents),
        \   'minheight': self.get_height(self.state.contents),
        \   'tabpage': 0
        \ }
endfunction

"
" width.
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
" height.
"
function! s:Floatwin.get_height(contents) abort
  let l:width = self.get_width(a:contents)

  let l:height = len(a:contents) - 1
  for l:content in a:contents
    for l:line in l:content.lines
      if l:line ==# ''
        let l:height += 1
      else
        let l:height += float2nr(ceil(strdisplaywidth(l:line) / str2float('' . l:width)))
      endif
    endfor
  endfor

  if self.max_height != -1
    return max([min([self.max_height, l:height]), 1])
  endif
  return max([l:height, 1])
endfunction


