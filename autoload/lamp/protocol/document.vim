let s:language_id_map = {
      \   'typescript.tsx': 'typescriptreact',
      \   'javascript.jsx': 'javascriptreact'
      \ }

function! lamp#protocol#document#encode_uri(bufnr_or_path) abort
  let l:path = type(a:bufnr_or_path) == type('') ? a:bufnr_or_path : bufname(a:bufnr_or_path)
  let l:path = fnamemodify(l:path, ':p')
  let l:path = 'file://' . substitute(l:path, '\([^a-zA-Z0-9-_.~/]\)', '\=printf("%%%02x", char2nr(submatch(1)))', 'g')
  return l:path
endfunction

function! lamp#protocol#document#decode_uri(uri) abort
  let l:path = a:uri
  let l:path = substitute(l:path, '^\Vfile://', '', 'g')
  let l:path = substitute(l:path, '%\([a-fA-F0-9]\{2}\)', '\=nr2char(str2nr(submatch(1), 16))', 'g')
  return l:path
endfunction

function! lamp#protocol#document#identifier(bufnr) abort
  return { 'uri': lamp#protocol#document#encode_uri(bufname(a:bufnr)) }
endfunction

function! lamp#protocol#document#versioned_identifier(bufnr) abort
  return extend(lamp#protocol#document#identifier(a:bufnr), {
        \   'version': getbufvar(a:bufnr, 'changedtick', 0)
        \ })
endfunction

function! lamp#protocol#document#item(bufnr) abort
  return extend(lamp#protocol#document#versioned_identifier(a:bufnr), {
        \   'languageId': lamp#protocol#document#language_id(a:bufnr),
        \   'text': join(getbufline(a:bufnr, '^', '$'), "\n")
        \ })
endfunction

function! lamp#protocol#document#language_id(bufnr) abort
  let l:filetype = getbufvar(a:bufnr, '&filetype', '')
  return get(s:language_id_map, l:filetype, l:filetype)
endfunction

