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
  let l:bufnr = bufnr('%')
  let l:servers = lamp#server#registry#find_by_filetype(getbufvar(l:bufnr, '&filetype', ''))
  let l:servers = filter(l:servers, { k, v -> v.supports('capabilities.referencesProvider') })
  if empty(l:servers)
    return
  endif

  let l:promises = map(l:servers, { k, v ->
        \   v.request('textDocument/references', {
        \     'textDocument': lamp#protocol#document#identifier(bufnr('%')),
        \     'position': lamp#protocol#position#get(),
        \     'context': {
        \       'includeDeclaration': a:include_declaration
        \     }
        \   }).catch(lamp#rescue([]))
        \ })
  call s:Promise.all(l:promises).then({ responses -> s:on_response(l:bufnr, responses) })
endfunction

"
" s:on_response
"
function! s:on_response(bufnr, responses) abort
  let l:locations = []
  for l:response in a:responses
    for l:location in l:response
      call add(l:locations, {
            \   'filename': lamp#protocol#document#decode_uri(l:location.uri),
            \   'lnum': (l:location.range.start.line) + 1,
            \   'col': (l:location.range.start.character) + 1,
            \ })
    endfor
  endfor

  call lamp#config('feature.references.on_references')(l:locations)
endfunction
