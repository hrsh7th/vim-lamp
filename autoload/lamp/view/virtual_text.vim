let s:namespaces = {}
let s:initialized = v:false

"
" lamp#view#virtual_text#remove
"
function! lamp#view#virtual_text#remove(namespace, bufnr) abort
  if !exists('*nvim_buf_clear_namespace')
    return
  endif
  if has_key(s:namespaces, a:namespace)
    call nvim_buf_clear_namespace(a:bufnr, s:namespaces[a:namespace], 0, -1)
  endif
endfunction

"
" lamp#view#virtual_text#error
"
function! lamp#view#virtual_text#error(namespace, bufnr, line, text) abort
  call s:add_virtual_text(a:namespace, a:bufnr, a:line, a:text, 'LampVirtualError')
endfunction

"
" lamp#view#virtual_text#warning
"
function! lamp#view#virtual_text#warning(namespace, bufnr, line, text) abort
  call s:add_virtual_text(a:namespace, a:bufnr, a:line, a:text, 'LampVirtualWarning')
endfunction

"
" lamp#view#virtual_text#information
"
function! lamp#view#virtual_text#information(namespace, bufnr, line, text) abort
  call s:add_virtual_text(a:namespace, a:bufnr, a:line, a:text, 'LampVirtualInformation')
endfunction

"
" lamp#view#virtual_text#hint
"
function! lamp#view#virtual_text#hint(namespace, bufnr, line, text) abort
  call s:add_virtual_text(a:namespace, a:bufnr, a:line, a:text, 'LampVirtualHint')
endfunction

"
" add_virtual_text
"
function! s:add_virtual_text(namespace, bufnr, line, text, highlight) abort
  if !exists('*nvim_buf_set_virtual_text')
    return
  endif

  call s:initialize()
  if !has_key(s:namespaces, a:namespace)
    let s:namespaces[a:namespace] = nvim_create_namespace(a:namespace)
  endif
  call nvim_buf_set_virtual_text(a:bufnr, s:namespaces[a:namespace], a:line, [
        \   [a:text, a:highlight]
        \ ], {})
endfunction

"
" initialize
"
function! s:initialize() abort
  if s:initialized
    return
  endif
  let s:initialized = v:true

  execute printf('highlight! link LampVirtualError Error')
  execute printf('highlight! link LampVirtualWarning WarningMsg')
  execute printf('highlight! link LampVirtualInformation MoreMsg')
  execute printf('highlight! link LampVirtualHint NonText')
endfunction
