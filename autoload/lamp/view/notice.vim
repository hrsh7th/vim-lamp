let s:Floatwin = lamp#view#floatwin#import()

let s:notices = []

let s:timer_id = -1

"
" lamp#view#notice#add
"
function! lamp#view#notice#add(content, ...) abort
  let l:content = a:content
  let l:content.lines = [''] + l:content.lines + ['']
  let s:notices += [s:Notice.new([l:content], get(a:000, 0, {}))]
  call s:update()
endfunction

"
" update
"
function! s:update() abort
  let s:notices = filter(s:notices, { k, v -> !v.outdated() })
  if empty(s:notices)
    call timer_stop(s:timer_id)
    let s:timer_id = -1
    return
  endif

  let l:y = &lines - (&cmdheight + 2)
  for l:notice in s:notices
    let l:y -= l:notice.get_height() + 1
    call l:notice.show([l:y, &columns - l:notice.get_width() - 1])
  endfor

  if s:timer_id == -1
    let s:timer_id = timer_start(100, { -> s:update() }, { 'repeat': -1 })
  endif
endfunction

let s:Notice = {}

"
" new
"
function! s:Notice.new(contents, option) abort
  return extend(deepcopy(s:Notice), {
        \   'option': a:option,
        \   'contents': a:contents,
        \   'started_time': -1,
        \   'floatwin': s:Floatwin.new({ 'max_width': -1, 'max_height': 5 })
        \ })
endfunction

"
" show
"
function! s:Notice.show(position) abort
  if type(self.started_time) != type([])
    let self.started_time = reltime()
  endif
  call self.floatwin.show(a:position, self.contents)
endfunction

"
" outdated
"
function! s:Notice.outdated() abort
  let l:outdated = reltimefloat(reltime(self.started_time)) > 2
  if l:outdated
    call self.floatwin.hide()
  endif
  return l:outdated
endfunction

"
" get_width
"
function! s:Notice.get_width() abort
  return self.floatwin.get_width(self.contents)
endfunction

"
" get_height
"
function! s:Notice.get_height() abort
  return self.floatwin.get_height(self.contents)
endfunction

