let s:highlight_id = 0
let s:highlight_namespace = 'lamp#feature#document_highlight'

let s:highlight_active_namespaces = []

"
" lamp#feature#document_highlight#init
"
function! lamp#feature#document_highlight#init() abort
  " noop
endfunction

"
" lamp#feature#document_highlight#clear
"
function! lamp#feature#document_highlight#clear() abort
  for l:namespace in s:highlight_active_namespaces
    call lamp#view#highlight#remove(l:namespace)
  endfor
  let s:highlight_active_namespaces = []
  let s:highlight_id = 0
endfunction

"
" lamp#feature#document_highlight#do
"
function! lamp#feature#document_highlight#do() abort
  let l:highlights_under_cursor = lamp#view#highlight#get_by_position(lamp#protocol#position#get())
  if len(keys(l:highlights_under_cursor)) != 0
    for l:namespace in keys(l:highlights_under_cursor)
      call lamp#view#highlight#remove(l:namespace)
    endfor
    return
  endif

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

"
" s:on_response
"
function! s:on_response(bufnr, response) abort
  if empty(a:response)
    return
  endif

  let l:namespace = s:highlight_namespace + s:highlight_id
  for l:highlight in a:response
    call lamp#view#highlight#color(l:namespace, a:bufnr, l:highlight.range, lamp#view#highlight#nr2color(s:highlight_id))
  endfor
  call add(s:highlight_active_namespaces, l:namespace)
  let s:highlight_id += 1
endfunction

