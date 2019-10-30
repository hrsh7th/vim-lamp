let s:id = 0

function! lamp#view#tooltip#vim#import() abort
  return s:Tooltip
endfunction

let s:Tooltip = {}

"
" new.
"
function! s:Tooltip.new(option) abort
  let s:id += 1
  let l:bufname = printf('lamp-tooltip-%s', s:id)
  call bufadd(l:bufname)
  let l:bufnr = bufnr(l:bufname)
  call setbufvar(l:bufnr, '&filetype', 'markdown')
  call setbufvar(l:bufnr, '&buftype', 'nofile')
  return extend(deepcopy(s:Tooltip), {
        \   'winid': v:null,
        \   'bufnr': l:bufnr,
        \   'max_width': get(a:option, 'max_width', float2nr(&columns / 3)),
        \   'max_height': get(a:option, 'max_height', float2nr(&lines / 2)),
        \   'state': {
        \     'winpos': [0, 0],
        \     'contents': [],
        \   }
        \ })
endfunction

"
" bufpos2winpos.
"
function! s:Tooltip.bufpos2winpos(bufpos) abort
  let l:pos = getpos('.')
  return [a:bufpos[0] - line('w0') - 1, a:bufpos[1] - ((l:pos[2] + l:pos[3]) - wincol()) - 1]
endfunction

"
" fixpos.
"
function! s:Tooltip.fixpos(winpos, width, height) abort
  let l:winpos = copy(a:winpos)

  " fix height.
  if l:winpos[0] - a:height >= 0
    let l:winpos[0] -= a:height - 1
  else
    let l:winpos[0] += 2
  endif

  " fix width.
  if winwidth(0) < l:winpos[1] + a:width
    let l:winpos[1] -= (l:winpos[1] + a:width) - winwidth(0)
  endif

  return l:winpos
endfunction

"
" show_at_cursor.
"
function! s:Tooltip.show_at_cursor(contents) abort
  let l:curpos = getpos('.')
  call self.show([l:curpos[1], l:curpos[2] + l:curpos[3]], a:contents)
endfunction

"
" open.
"
function! s:Tooltip.show(bufpos, contents) abort
  let l:width = self.get_width(a:contents)
  let l:height = self.get_height(a:contents)
  let self.state.winpos = s:Tooltip.bufpos2winpos(a:bufpos)
  let self.state.winpos = s:Tooltip.fixpos(self.state.winpos, l:width, l:height)
  let self.state.contents = a:contents

  let l:lines = []
  for l:content in a:contents
    let l:lines += l:content.lines
    if l:content isnot a:contents[-1]
      let l:lines += [repeat('-', l:width)]
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
function! s:Tooltip.is_showing() abort
  call self.sync()
  return !empty(self.winid)
endfunction

"
" enter.
"
function! s:Tooltip.enter() abort
  if self.is_showing()
    execute printf('%swincmd w', self.winnr())
  endif
endfunction

"
" close
"
function! s:Tooltip.hide() abort
  if self.is_showing()
    call popup_hide(self.winid)
    let self.winid = v:null
  endif
endfunction

"
" winnr.
"
function! s:Tooltip.winnr() abort
  if self.is_showing()
    return win_id2win(self.winid)
  endif
  return -1
endfunction

"
" sync.
"
function! s:Tooltip.sync() abort
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
function! s:Tooltip.get_config() abort
  return {
        \   'line': self.state.winpos[0] + 1,
        \   'col':  self.state.winpos[1] + 1,
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
function! s:Tooltip.get_width(contents) abort
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
function! s:Tooltip.get_height(contents) abort
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


