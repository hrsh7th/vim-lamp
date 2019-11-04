let s:Promise = vital#lamp#import('Async.Promise')

"
" lamp#feature#document_symbol#init
"
function! lamp#feature#document_symbol#init() abort
  " noop.
endfunction

"
" lamp#feature#document_symbol#update
"
function! lamp#feature#document_symbol#update() abort
  let l:bufnr = bufnr('%')
  let l:servers = lamp#server#registry#find_by_filetype(getbufvar(l:bufnr, '&filetype', ''))
  let l:servers = filter(l:servers, { k, v -> v.supports('capabilities.documentSymbolProvider') })
  if empty(l:servers)
    echomsg 'empty'
    return
  endif

  let l:promises = map(l:servers, { k, v ->
        \   v.request('textDocument/documentSymbol', {
        \     'textDocument': lamp#protocol#document#identifier(bufnr('%')),
        \   }).then({ data -> { 'server': v, 'data': data } }).catch(lamp#rescue({ 'server': v, 'data': [] }))
        \ })
  let l:p = s:Promise.all(l:promises)
  let l:p = l:p.then({ responses -> s:on_responses(l:bufnr, responses) })
  let l:p = l:p.catch(lamp#rescue())
  return l:p
endfunction

"
" s:on_responses
"
function! s:on_responses(bufnr, responses) abort
  let l:responses = a:responses
  let l:responses = filter(a:responses, { k, v -> !empty(v.data) })

  for l:response in l:responses
    call s:on_response(a:bufnr, l:response.server, l:response.data)
  endfor
endfunction

"
" s:on_response
"
function! s:on_response(bufnr, server, response) abort
  " Store the server.
  " To use text-objects.
  " echomsg string({ 'bufnr': a:bufnr, 'server_name': a:server.name, 'response': a:response })
endfunction

