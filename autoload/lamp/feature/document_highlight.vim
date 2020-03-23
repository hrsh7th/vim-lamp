let s:Position = vital#lamp#import('VS.LSP.Position')

let s:highlight_id = 0
let s:highlight_namespace = 'lamp#feature#document_highlight'

"
" [{
"   'namespace': ...,
"   'bufnr': ...
" }]
"
let s:active_highlights = []

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
  for l:highlight in s:active_highlights
    call lamp#view#highlight#remove(l:highlight.namespace, l:highlight.bufnr)
  endfor
  let s:active_highlights = []
  let s:highlight_id = 0
endfunction

"
" lamp#feature#document_highlight#do
"
function! lamp#feature#document_highlight#do() abort
  if has_key(s:, 'cancellation_token')
    call s:cancellation_token.cancel()
  endif
  let s:cancellation_token = lamp#cancellation_token()

  " remove highlight under cursor if already highlighted.
  let l:highlights_under_cursor = lamp#view#highlight#get(s:Position.cursor())
  if len(l:highlights_under_cursor) != 0
    for l:highlight in l:highlights_under_cursor
      call lamp#view#highlight#remove(l:highlight.namespace, bufnr('%'))
    endfor
    return
  endif

  " highlight word under cursor.
  let l:bufnr = bufnr('%')
  let l:servers = lamp#server#registry#find_by_filetype(&filetype)
  let l:servers = filter(l:servers, { k, v -> v.supports('capabilities.documentHighlightProvider') })
  if empty(l:servers)
    call lamp#view#notice#add({ 'lines': ['`DocumentHighlight`: Has no `DocumentHighlight` capability.'] })
    return
  endif
  let l:p = l:servers[0].request('textDocument/documentHighlight', {
        \   'textDocument': lamp#protocol#document#identifier(l:bufnr),
        \   'position': s:Position.cursor()
        \ }, {
        \   'cancellation_token': s:cancellation_token,
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

  let l:namespace = s:highlight_namespace . s:highlight_id
  for l:highlight in a:response
    call lamp#view#highlight#color(l:namespace, a:bufnr, l:highlight.range, lamp#view#highlight#nr2color(s:highlight_id))
  endfor
  call add(s:active_highlights, {
        \   'bufnr': a:bufnr,
        \   'namespace': l:namespace
        \ })
  let s:highlight_id += 1
endfunction

