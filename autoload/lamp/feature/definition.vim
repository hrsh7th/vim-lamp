let s:Promise = vital#lamp#import('Async.Promise')

"
" lamp#feature#definition#init
"
function! lamp#feature#definition#init() abort
  " noop.
endfunction

"
" lamp#feature#definition#do
"
function! lamp#feature#definition#do(command) abort
  let l:bufnr = bufnr('%')
  let l:servers = lamp#server#registry#find_by_filetype(getbufvar(l:bufnr, '&filetype', ''))
  let l:servers = filter(l:servers, { k, v -> v.supports('capabilities.definitionProvider') })
  if empty(l:servers)
    call lamp#view#notice#add({ 'lines': ['`Definition`: Has no `Definition` capability.'] })
    return
  endif

  let l:promises = map(l:servers, { k, v ->
        \   v.request('textDocument/definition', {
        \     'textDocument': lamp#protocol#document#identifier(bufnr('%')),
        \     'position': lamp#protocol#position#get(),
        \   }).catch(lamp#rescue([]))
        \ })
  let l:p = s:Promise.all(l:promises)
  let l:p = l:p.then({ responses -> s:on_response(a:command, l:bufnr, responses) })
  let l:p = l:p.catch(lamp#rescue())
endfunction

"
" s:on_response
"
function! s:on_response(command, bufnr, responses) abort
  let l:locations = []
  for l:response in a:responses
    let l:locations += lamp#protocol#location#normalize(l:response)
  endfor

  if len(l:locations) == 1
    call lamp#view#buffer#open(a:command, l:locations[0])
  elseif len(l:locations) > 1
    call lamp#config('feature.definition.on_definitions')(l:locations)
  else
    call lamp#view#notice#add({ 'lines': ['`Definition`: No definitions found.'] })
  endif
endfunction

