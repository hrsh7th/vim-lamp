let s:Promise = vital#lamp#import('Async.Promise')

"
" lamp#feature#type_definition#init
"
function! lamp#feature#type_definition#init() abort
  " noop.
endfunction

"
" lamp#feature#type_definition#do
"
function! lamp#feature#type_definition#do(command) abort
  let l:command = strlen(a:command) > 0 ? a:command : 'edit'

  let l:bufnr = bufnr('%')
  let l:servers = lamp#server#registry#find_by_filetype(getbufvar(l:bufnr, '&filetype', ''))
  let l:servers = filter(l:servers, { k, v -> v.supports('capabilities.typeDefinitionProvider') })
  if empty(l:servers)
    call lamp#view#notice#add({ 'lines': ['`TypeDefinition`: Has no `TypeDefinition` capability.'] })
    return
  endif

  let l:position = lamp#protocol#position#get()
  let l:promises = map(l:servers, { k, v ->
        \   v.request('textDocument/typeDefinition', {
        \     'textDocument': lamp#protocol#document#identifier(bufnr('%')),
        \     'position': l:position,
        \   }).catch(lamp#rescue([]))
        \ })
  let l:p = s:Promise.all(l:promises)
  let l:p = l:p.then({ responses -> s:on_response(l:command, l:bufnr, l:position, responses) })
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


