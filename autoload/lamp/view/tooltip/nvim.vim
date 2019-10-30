function! lamp#view#tooltip#nvim#import() abort
  return s:Tooltip
endfunction

let s:Tooltip = {}

"
" new.
"
function! s:Tooltip.new(option) abort
  let l:bufnr = nvim_create_buf(v:false, v:true)
  call setbufvar(l:bufnr, '&filetype', 'markdown')
  return extend(deepcopy(s:Tooltip), {
        \   'window': v:null,
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
  call nvim_buf_set_lines(self.bufnr, 0, -1, v:true, l:lines)

  if !self.is_showing()
    let self.window = nvim_open_win(self.bufnr, v:false, self.get_config())
    call setwinvar(self.winnr(), '&wrap', 1)
    call setwinvar(self.winnr(), '&conceallevel', 3)
  else
    call nvim_win_set_config(self.window, self.get_config())
  endif
endfunction

"
" is_showing.
"
function! s:Tooltip.is_showing() abort
  call self.sync()
  return !empty(self.window)
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
    call nvim_win_close(self.window, v:true)
    let self.window = v:null
  endif
endfunction

"
" winnr.
"
function! s:Tooltip.winnr() abort
  if self.is_showing()
    return nvim_win_get_number(self.window)
  endif
  return -1
endfunction

"
" sync.
"
function! s:Tooltip.sync() abort
  if empty(self.window)
    return
  endif

  if !nvim_win_is_valid(self.window)
    try
      call nvim_win_close(self.window, v:true)
    catch /.*/
    endtry
    let self.window = v:null
  endif
endfunction

"
" config.
"
function! s:Tooltip.get_config() abort
  return {
        \   'relative': 'win',
        \   'width': self.get_width(self.state.contents),
        \   'height': self.get_height(self.state.contents),
        \   'row': self.state.winpos[0],
        \   'col': self.state.winpos[1],
        \   'focusable': v:true,
        \   'style': 'minimal'
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

