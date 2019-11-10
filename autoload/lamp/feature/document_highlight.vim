let s:highlight_namespace = 'lamp#feature#document_highlight'

function! lamp#feature#document_highlight#init() abort
  " noop
endfunction

function! lamp#feature#document_highlight#clear() abort
  call lamp#view#highlight#remove(s:highlight_namespace)
endfunction

function! lamp#feature#document_highlight#do() abort
  let l:bufnr = bufnr('%')
  let l:servers = lamp#server#registry#find_by_filetype(&filetype)
  let l:servers = filter(l:servers, { k, v -> v.supports('capabilities.documentHighlightProvider') })
  if empty(l:servers)
    call lamp#view#notice#add({ 'lines': ['`DocumentHighlight`: Has no `DocumentHighlight` capability.'] })
    return
  endif
  let l:p = l:servers[0].request('textDocument/documentHighlight', {
        \   'textDocument': lamp#protocol#document#identifier(l:bufnr),
        \   'position': lamp#protocol#position#get()
        \ })
  let l:p = l:p.then({ response -> s:on_response(l:bufnr, response) })
  let l:p = l:p.catch(lamp#rescue())
endfunction

function! s:on_response(bufnr, response) abort
  if empty(a:response)
    return
  endif
  for l:highlight in a:response
    call lamp#view#highlight#attention(s:highlight_namespace, a:bufnr, l:highlight.range)
  endfor
endfunction

