let s:Position = vital#lamp#import('VS.LSP.Position')
let s:Promise = vital#lamp#import('Async.Promise')

"
" lamp#feature#references#init
"
function! lamp#feature#references#init() abort
  " noop.
endfunction

"
" lamp#feature#references#do
"
function! lamp#feature#references#do(include_declaration) abort
  if has_key(s:, 'cancellation_token')
    call s:cancellation_token.cancel()
  endif
  let s:cancellation_token = lamp#cancellation_token()

  let l:bufnr = bufnr('%')
  let l:servers = lamp#server#registry#find_by_filetype(getbufvar(l:bufnr, '&filetype', ''))
  let l:servers = filter(l:servers, { k, v -> v.supports('capabilities.referencesProvider') })
  if empty(l:servers)
    call lamp#view#notice#add({ 'lines': ['`References`: Has no `References` capability.'] })
    return
  endif

  let l:promises = map(l:servers, { k, v ->
        \   v.request('textDocument/references', {
        \     'textDocument': lamp#protocol#document#identifier(bufnr('%')),
        \     'position': s:Position.cursor(),
        \     'context': {
        \       'includeDeclaration': a:include_declaration
        \     }
        \   }, {
        \     'cancellation_token': s:cancellation_token,
        \   }).catch(lamp#rescue([]))
        \ })
  let l:p = s:Promise.all(l:promises)
  let l:p = l:p.then({ responses -> s:on_response(l:bufnr, responses) })
  let l:p = l:p.catch(lamp#rescue())
endfunction

"
" s:on_response
"
function! s:on_response(bufnr, responses) abort
  let l:locations = []
  for l:response in a:responses
    let l:locations += lamp#protocol#location#normalize(l:response)
  endfor

  call lamp#view#location#handle('', {}, l:locations, {
        \   'always_listing': v:true,
        \   'no_fallback': v:true
        \ })
endfunction

