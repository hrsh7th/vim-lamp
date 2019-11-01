let s:id = 0

function! lamp#view#floatwin#nvim#import() abort
  return s:Floatwin
endfunction

let s:Floatwin = {}

"
" new.
"
function! s:Floatwin.new(option) abort
  let s:id += 1
  let l:bufname = printf('lamp-floatwin-%s.md', s:id)
  let l:bufnr = bufnr(l:bufname, v:true)
  call setbufvar(l:bufnr, '&buflisted', v:true)
  call setbufvar(l:bufnr, '&filetype', 'markdown')
  call setbufvar(l:bufnr, '&buftype', 'nofile')
  return extend(deepcopy(s:Floatwin), {
        \   'window': v:null,
        \   'bufnr': l:bufnr,
        \   'max_width': get(a:option, 'max_width', float2nr(&columns / 3)),
        \   'max_height': get(a:option, 'max_height', float2nr(&lines / 2)),
        \   'nofix': get(a:option, 'nofix', v:false),
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
  call self.show(l:screenpos, a:contents)
endfunction

"
" show.
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
function! s:Floatwin.is_showing() abort
  call self.sync()
  return !empty(self.window)
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
    call nvim_win_close(self.window, v:true)
    let self.window = v:null
  endif
endfunction

"
" winnr.
"
function! s:Floatwin.winnr() abort
  if self.is_showing()
    return nvim_win_get_number(self.window)
  endif
  return -1
endfunction

"
" sync.
"
function! s:Floatwin.sync() abort
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
function! s:Floatwin.get_config() abort
  return {
        \   'relative': 'editor',
        \   'width': self.get_width(self.state.contents),
        \   'height': self.get_height(self.state.contents),
        \   'row': self.state.screenpos[0],
        \   'col': self.state.screenpos[1],
        \   'focusable': v:true,
        \   'style': 'minimal'
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

