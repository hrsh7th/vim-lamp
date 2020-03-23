let s:Promise = vital#lamp#import('Async.Promise')
let s:Position = vital#lamp#import('VS.LSP.Position')

let s:context = {
\   'index': 0,
\   'selection_range': v:null,
\ }

"
" lamp#feature#selection_range#init
"
function! lamp#feature#selection_range#init() abort
  " noop
endfunction

"
" lamp#feature#selection_range#do
"
function! lamp#feature#selection_range#do(...) abort
  if has_key(s:, 'cancellation_token')
    call s:cancellation_token.cancel()
  endif
  let s:cancellation_token = lamp#cancellation_token()

  let l:direction = get(a:000, 0, 1)
  if !empty(s:context.selection_range)
    return s:select(l:direction)
  endif

  let l:servers = lamp#server#registry#find_by_filetype(&filetype)
  let l:servers = filter(l:servers, { _, server -> server.supports('capabilities.selectionRangeProvider') })
  if empty(l:servers)
    return lamp#view#notice#add({ 'lines': ['`SelectionRange`: Has no `SelectionRange` capability.'] })
  endif

  let l:position = s:Position.cursor()
  let l:promises = map(l:servers, { _, server ->
  \   server.request('textDocument/selectionRange', {
  \     'textDocument': lamp#protocol#document#identifier(bufnr('%')),
  \     'positions': [l:position],
  \   }, {
  \     'cancellation_token': s:cancellation_token,
  \   }).catch(lamp#rescue())
  \ })
  let l:p = s:Promise.all(l:promises)
  let l:p = l:p.then({ responses -> s:on_responses(responses) })
  let l:p = l:p.catch(lamp#rescue())

  try
    call lamp#sync(l:p)
  catch /.*/
    echomsg 'SelectionRange: timeout.'
  endtry
endfunction

"
" on_responses
"
function! s:on_responses(responses) abort
  let l:selection_range = v:null
  for l:response in a:responses
    if len(l:response) != 0
      let l:selection_range = l:response[0]
      break
    endif
  endfor
  if empty(l:selection_range)
    return lamp#view#notice#add({ 'lines': ['`SelectionRange`: no `SelectionRange` found.'] })
  endif

  let s:context.index = 0
  let s:context.selection_range = l:selection_range
  call s:select(1)
endfunction

"
" select
"
function! s:select(direction) abort
  let s:context.index = max([0, s:context.index + a:direction])

  let l:current = s:context.selection_range
  let l:range = v:null
  for l:i in range(0, s:context.index)
    let l:range = l:current.range
    if !has_key(l:current, 'parent')
      break
    endif
    let l:current = l:current.parent
  endfor

  let l:start = s:Position.lsp_to_vim('%', l:range.start)
  let l:end = s:Position.lsp_to_vim('%', l:range.end)
  call cursor(l:end)
  normal! hv
  call cursor(l:start)

  call timer_start(100, function('s:deactivate'), { 'repeat': -1 })
endfunction

"
" deactivate
"
function! s:deactivate(timer_id) abort
  if mode()[0] ==# 'n' || empty(s:context.selection_range)
    let s:context.index = 0
    let s:context.selection_range = v:null
    call timer_start(0, { -> timer_stop(a:timer_id) })
  endif
endfunction

