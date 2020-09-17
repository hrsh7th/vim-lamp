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
function! lamp#view#highlight#get(position) abort
  return lamp#view#highlight#{s:ns}#get(a:position)
endfunction

"
" lamp#view#highlight#remove
"
function! lamp#view#highlight#remove(namespace, bufnr) abort
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
  call lamp#view#highlight#{s:ns}#add(a:namespace, a:bufnr, a:range, a:highlight)
endfunction

"
" initialize
"
function! s:initialize() abort
  for l:definition in [{
  \   'kind': 'Error',
  \   'guifg': 'Red',
  \ }, {
  \   'kind': 'Warning',
  \   'guifg': 'Orange',
  \ }, {
  \   'kind': 'Information',
  \   'guifg': 'LightYellow',
  \ }, {
  \   'kind': 'Hint',
  \   'guifg': 'LightGray',
  \ }]
    execute printf('highlight! default Lamp%s gui=undercurl cterm=undercurl guisp=%s', l:definition.kind, l:definition.guifg)
  endfor

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
call s:initialize()

