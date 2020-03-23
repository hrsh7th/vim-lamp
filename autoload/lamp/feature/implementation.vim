let s:Position = vital#lamp#import('VS.LSP.Position')
let s:Promise = vital#lamp#import('Async.Promise')

"
" lamp#feature#implementation#init
"
function! lamp#feature#implementation#init() abort
  " noop.
endfunction

"
" lamp#feature#implementation#do
"
function! lamp#feature#implementation#do(command) abort
  if has_key(s:, 'cancellation_token')
    call s:cancellation_token.cancel()
  endif
  let s:cancellation_token = lamp#cancellation_token()

  let l:command = strlen(a:command) > 0 ? a:command : 'edit'

  let l:bufnr = bufnr('%')
  let l:servers = lamp#server#registry#find_by_filetype(getbufvar(l:bufnr, '&filetype', ''))
  let l:servers = filter(l:servers, { k, v -> v.supports('capabilities.implementationProvider') })
  if empty(l:servers)
    call lamp#view#notice#add({ 'lines': ['`Implementation`: Has no `implementation` capability.'] })
    return
  endif

  let l:position = s:Position.cursor()
  let l:promises = map(l:servers, { k, v ->
        \   v.request('textDocument/implementation', {
        \     'textDocument': lamp#protocol#document#identifier(bufnr('%')),
        \     'position': l:position,
        \   }, {
        \     'cancellation_token': s:cancellation_token,
        \   }).catch(lamp#rescue([]))
        \ })
  let l:p = s:Promise.all(l:promises)
  let l:p = l:p.then({ responses -> s:on_response(l:command, l:bufnr, position, responses) })
  let l:p = l:p.catch(lamp#rescue())
endfunction

"
" s:on_response
"
function! s:on_response(command, bufnr, position, responses) abort
  let l:locations = []
  for l:response in a:responses
    let l:locations += lamp#protocol#location#normalize(l:response)
  endfor

  call lamp#view#location#handle(a:command, a:position, l:locations)
endfunction

