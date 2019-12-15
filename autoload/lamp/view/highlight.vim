let s:initialized = v:false
let s:ns = has('nvim') ? 'nvim' : 'vim'

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
  return lamp#view#highlight#{s:ns}#get(a:position)
endfunction

"
" lamp#view#highlight#remove
"
function! lamp#view#highlight#remove(namespace, bufnr) abort
  call lamp#log('[CALL] lamp#view#highlight#remove')
  call lamp#view#highlight#{s:ns}#remove(a:namespace, a:bufnr)
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

  call lamp#log('[CALL] lamp#view#highlight s:add_highlight')

  " correct empty range.
  if !lamp#protocol#range#has_length(a:range)
    let l:text = get(getbufline(a:bufnr, a:range.end.line), 0, '')
    if a:range.end.character < strchars(l:text) - 1
      let a:range.end.character += 1
    else
      return
    endif
  endif

  " add highlight.
  call lamp#view#highlight#{s:ns}#add(a:namespace, a:bufnr, s:positions(a:bufnr, a:range), a:highlight)
endfunction

"
" positions
"
function! s:positions(bufnr, range) abort
  " to inclusive.
  if a:range.end.character == 0
    let a:range.end.character = strlen(get(getbufline(a:bufnr, a:range.end.line), 0, ''))
    let a:range.end.line -= 1
  endif

  " same line.
  if a:range.start.line == a:range.end.line
    return [[a:range.start.line, a:range.start.character, a:range.end.character]]
  endif

  " multiline.
  let l:positions = []
  for l:line in range(a:range.start.line, a:range.end.line)
    if a:range.start.line == l:line
      call add(l:positions, [l:line, a:range.start.character, a:range.end.character])
    elseif a:range.end.line == l:line
      call add(l:positions, [l:line, 0, a:range.end.character])
    else
      let l:text = get(getbufline(a:bufnr, l:line + 1), 0, '')
      call add(l:positions, [l:line, 0, strlen(l:text)])
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

  execute printf('highlight! LampError gui=underline guibg=darkred')
  execute printf('highlight! LampWarning gui=underline guibg=darkmagenta')
  execute printf('highlight! LampInformation gui=underline')
  execute printf('highlight! LampHint gui=underline')
  for l:color in s:colors
    execute printf('highlight! Lamp%s guibg=%s', l:color, l:color)
  endfor

  if exists('*prop_add')
    call prop_type_add('LampError', { 'highlight': 'LampError' })
    call prop_type_add('LampWarning', { 'highlight': 'LampWarning' })
    call prop_type_add('LampInformation', { 'highlight': 'LampInformation' })
    call prop_type_add('LampHint', { 'highlight': 'LampHint' })
    for l:color in s:colors
      let l:highlight = printf('Lamp%s', l:color)
      call prop_type_add(l:highlight, {
            \   'highlight': l:highlight
            \ })
    endfor
  endif
endfunction

