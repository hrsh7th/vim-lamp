let s:initialized = v:false
let s:buf_highlights = {}
let s:win_highlights = {}

let s:colors = reverse([
      \   'DarkBlue',
      \   'DarkGreen',
      \   'DarkCyan',
      \   'DarkRed',
      \   'DarkMagenta',
      \   'DarkYellow',
      \   'LightGray',
      \   'DarkGray',
      \   'Blue',
      \   'Green',
      \   'Cyan',
      \   'Red',
      \   'Magenta',
      \   'Yellow',
      \ ])

"
" lamp#view#highlight#nr2color
"
function! lamp#view#highlight#nr2color(nr) abort
  return s:colors[a:nr % len(s:colors)]
endfunction

"
" lamp#view#highlight#get_by_position
"
" Returns buf_highlights that related current bufnr.
"
function! lamp#view#highlight#get_by_position(position) abort
  let l:target = {}
  for [l:namespace, l:highlight_map] in items(s:buf_highlights)
    for [l:bufnr, l:highlights] in items(l:highlight_map)
      if l:bufnr != bufnr('%')
        continue
      endif

      for l:highlight in l:highlights
        if lamp#protocol#position#in_range(a:position, l:highlight.range)
          let l:target[l:namespace] = get(l:target, l:namespace, [])
          let l:target[l:namespace] += [l:highlight]
        endif
      endfor
    endfor
  endfor
  return l:target
endfunction

"
" lamp#view#highlight#remove
"
function! lamp#view#highlight#remove(namespace, ...) abort
  if len(a:000) > 0
    if has_key(s:buf_highlights, a:namespace) && has_key(s:buf_highlights[a:namespace], a:000[0])
      let s:buf_highlights[a:namespace][a:000[0]] = []
    endif
  else
    if has_key(s:buf_highlights, a:namespace)
      let s:buf_highlights[a:namespace] = {}
    endif
  endif
  call s:update()
endfunction

"
" lamp#view#highlight#color
"
function! lamp#view#highlight#color(namespace, bufnr, range, color) abort
  call s:add_highlight(a:namespace, a:bufnr, a:range, 'Lamp' . a:color)
endfunction

"
" lamp#view#highlight#error
"
function! lamp#view#highlight#error(namespace, bufnr, range) abort
  call s:add_highlight(a:namespace, a:bufnr, a:range, 'LampError')
endfunction

"
" lamp#view#highlight#warning
"
function! lamp#view#highlight#warning(namespace, bufnr, range) abort
  call s:add_highlight(a:namespace, a:bufnr, a:range, 'LampWarning')
endfunction

"
" lamp#view#highlight#information
"
function! lamp#view#highlight#information(namespace, bufnr, range) abort
  call s:add_highlight(a:namespace, a:bufnr, a:range, 'LampInformation')
endfunction

"
" lamp#view#highlight#hint
"
function! lamp#view#highlight#hint(namespace, bufnr, range) abort
  call s:add_highlight(a:namespace, a:bufnr, a:range, 'LampHint')
endfunction


"
" add_highlight
"
function! s:add_highlight(namespace, bufnr, range, highlight) abort
  call s:initialize()

  if !lamp#protocol#range#has_length(a:range)
    let l:text = get(getbufline(a:bufnr, a:range.end.line), 0, '')
    if a:range.end.character < strchars(l:text) - 1
      let a:range.end.character += 1
    else
      return
    endif
  endif

  if !has_key(s:buf_highlights, a:namespace)
    let s:buf_highlights[a:namespace] = {}
  endif
  if !has_key(s:buf_highlights[a:namespace], a:bufnr)
    let s:buf_highlights[a:namespace][a:bufnr] = []
  endif
  let s:buf_highlights[a:namespace][a:bufnr] += [{ 'highlight': a:highlight, 'range': a:range }]

  call s:update()
endfunction

"
" update
"
function! s:update() abort
  let l:ctx = {}
  function! l:ctx.callback() abort
    for l:winnr in range(1, tabpagewinnr(tabpagenr(), '$'))
      " clear current highlight
      let l:winid = win_getid(l:winnr)
      if has_key(s:win_highlights, l:winid)
        call lamp#view#window#do(l:winid, { -> map(copy(s:win_highlights[l:winid]), { k, v -> matchdelete(v) }) })
        let s:win_highlights[l:winid] = []
      else
        let s:win_highlights[l:winid] = []
      endif

      " add new highlights
      let l:bufnr = winbufnr(l:winnr)
      for [l:namespace, l:buf_highlight] in items(s:buf_highlights)
        if has_key(l:buf_highlight, l:bufnr)
          for l:highlight in l:buf_highlight[l:bufnr]
            let s:win_highlights[l:winid] += [matchaddpos(l:highlight.highlight, s:positions(l:bufnr, l:highlight.range), 100, -1, { 'window': l:winid })]
          endfor
        endif
      endfor
    endfor
  endfunction
  call lamp#debounce('lamp#view#highlight:update', l:ctx.callback, 0)
endfunction

"
" positions
"
" Return [[lnum, col-start, length]]
"
function! s:positions(bufnr, range) abort
  if a:range.end.character == 0
    let a:range.end.character = strlen(get(getbufline(a:bufnr, a:range.end.line), 0, ''))
    let a:range.end.line -= 1
  endif

  if a:range.start.line == a:range.end.line
    return [[a:range.start.line + 1, a:range.start.character + 1, a:range.end.character - a:range.start.character]]
  endif

  let l:positions = []
  for l:line in range(a:range.start.line, a:range.end.line)
    if a:range.start.line == l:line
      let l:bytes = strlen(get(getbufline(a:bufnr, a:range.start.line + 1), 0, ''))
      call add(l:positions, [l:line + 1, a:range.start.character + 1, l:bytes - a:range.start.character])
    elseif a:range.end.line == l:line
      call add(l:positions, [l:line + 1, 0, a:range.end.character])
    else
      call add(l:positions, l:line + 1)
    endif
  endfor
  return l:positions
endfunction

"
" initialize
"
function! s:initialize() abort
  if s:initialized
    return
  endif
  let s:initialized = v:true

  execute printf('highlight! LampError guibg=darkred')
  execute printf('highlight! LampWarning guibg=darkmagenta')
  execute printf('highlight! LampInformation gui=underline')
  execute printf('highlight! LampHint gui=underline')
  for l:color in s:colors
    execute printf('highlight! Lamp%s guibg=%s', l:color, l:color)
  endfor

  augroup lamp#view#highlight
    autocmd!
    autocmd BufWinEnter,WinNew * call s:update()
  augroup END
endfunction

