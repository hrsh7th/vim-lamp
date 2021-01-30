let s:Position = vital#lamp#import('VS.LSP.Position')
let s:TextMark = vital#lamp#import('VS.Vim.Buffer.TextMark')

"
" lamp#view#highlight#remove
"
function! lamp#view#highlight#remove(namespace, bufnr) abort
  call s:TextMark.clear(a:bufnr, a:namespace)
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

  call s:TextMark.set(a:bufnr, a:namespace, [{
  \   'start_pos': s:Position.lsp_to_vim(a:bufnr, a:range.start),
  \   'end_pos': s:Position.lsp_to_vim(a:bufnr, a:range.end),
  \   'highlight': a:highlight
  \ }])
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
endfunction
call s:initialize()

