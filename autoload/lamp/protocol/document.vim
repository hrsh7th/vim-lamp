let s:URI = vital#lamp#import('VS.LSP.URI')

let s:language_id_map = {
      \   'typescript.tsx': 'typescriptreact',
      \   'javascript.jsx': 'javascriptreact'
      \ }

"
" lamp#protocol#document#encode_uri
"
function! lamp#protocol#document#encode_uri(bufnr_or_path) abort
  let l:path = type(a:bufnr_or_path) == type(0) ? bufname(a:bufnr_or_path) : a:bufnr_or_path
  return s:URI.encode(fnamemodify(l:path, ':p'))
endfunction

"
" lamp#protocol#document#decode_uri
"
function! lamp#protocol#document#decode_uri(uri) abort
  return s:URI.decode(a:uri)
endfunction

"
" lamp#protocol#document#identifier
"
function! lamp#protocol#document#identifier(bufnr) abort
  return { 'uri': lamp#protocol#document#encode_uri(a:bufnr) }
endfunction

"
" lamp#protocol#document#versioned_identifier
"
function! lamp#protocol#document#versioned_identifier(bufnr) abort
  return extend(lamp#protocol#document#identifier(a:bufnr), {
        \   'version': getbufvar(a:bufnr, 'changedtick', 0)
        \ })
endfunction

"
" lamp#protocol#document#item
"
function! lamp#protocol#document#item(bufnr) abort
  return extend(lamp#protocol#document#versioned_identifier(a:bufnr), {
        \   'languageId': lamp#protocol#document#language_id(a:bufnr),
        \   'text': join(lamp#view#buffer#get_lines(a:bufnr), "\n")
        \ })
endfunction

"
" lamp#protocol#document#language_id
"
function! lamp#protocol#document#language_id(bufnr) abort
  let l:filetype = getbufvar(a:bufnr, '&filetype', '')
  return get(s:language_id_map, l:filetype, l:filetype)
endfunction

