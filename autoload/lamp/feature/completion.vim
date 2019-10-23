let s:Promise = vital#lamp#import('Async.Promise')

"
" TextEdit enabled if other completion engine plugin provides below user-data.
"
" v:completed_item.user_data['lamp'] = {
"   'id': string | number;
"   'server_name': string;
"   'completion_item': CompletionItem;
" }
"
let s:user_data_key = 'lamp'

"
" {
"   [id]: {
"     'resolve': Promise;
"   }
" }
"
let s:state = {}

function! lamp#feature#completion#init() abort
  augroup lamp#feature#completion
    autocmd!
    autocmd CompleteChanged * call s:on_complete_changed()
    autocmd CompleteDone * call s:on_complete_done()
  augroup END
endfunction

"
" s:on_complete_changed
"
function! s:on_complete_changed() abort
  let l:item_data = s:get_item_data(v:completed_item)
  if empty(l:item_data)
    return
  endif

  let s:state[l:item_data.id] = get(s:state, l:item_data.id, {})
  if has_key(s:state[l:item_data.id], 'resolve')
    return
  endif

  let l:fn = {}
  function! l:fn.debounce(item_data) abort
    let s:state[a:item_data.id].resolve = s:resolve(a:item_data)
  endfunction
  call lamp#debounce('lamp#feature#completion:resolve', { -> l:fn.debounce(l:item_data) }, 100)
endfunction

"
" s:on_complete_done
"
function! s:on_complete_done() abort
  " clear debounce timer.
  call lamp#debounce('lamp#feature#completion:resolve', { -> {} }, 0)

  " check managed item.
  let l:item_data = s:get_item_data(v:completed_item)
  if empty(l:item_data)
    return
  endif

  " get item state.
  let l:state = get(s:state, l:item_data.id, {})

  " resolve if needed.
  let l:promise = get(l:state, 'resolve', {})
  if empty(l:promise)
    let l:promise = s:resolve(l:item_data)
  endif

  " resolve data.
  let l:completion_item = lamp#sync(l:promise)
  if empty(l:completion_item)
    return
  endif

  let l:text_edit = get(l:completion_item, 'textEdit', {})
  if !empty(l:text_edit)
    call lamp#view#edit#apply(bufnr('%'), [l:text_edit])
  endif

  let l:additional_text_edits = get(l:completion_item, 'additionalTextEdits', {})
  if !empty(l:additional_text_edits)
    call lamp#view#edit#apply(bufnr('%'), l:additional_text_edits)
  endif

  " TODO: save cursor position.
endfunction

"
" s:resolve
"
function! s:resolve(item_user_data) abort
  let l:server_name = a:item_user_data.server_name
  let l:completion_item = a:item_user_data.completion_item

  let l:server = lamp#server#registry#get_by_name(l:server_name)
  if empty(l:server)
    return s:Promise.resolve({})
  endif
  return l:server.request('completionItem/resolve', l:completion_item).catch(lamp#rescue({}))
endfunction

"
" s:get_item_data
"
function! s:get_item_data(completed_item) abort
  if empty(a:completed_item)
    return {}
  endif

  if !has_key(a:completed_item, 'user_data')
    return {}
  endif

  if type(a:completed_item.user_data) == type({})
    let l:user_data = a:completed_item.user_data
  else
    try
      let l:user_data = json_decode(a:completed_item.user_data)
    catch /.*/
      let l:user_data = {}
    endtry
  endif

  " if user_data has not `lamp` key.
  if !has_key(l:user_data, s:user_data_key)
    return {}
  endif

  " check values in user_data.
  let l:item_data = l:user_data[s:user_data_key]
  if !has_key(l:item_data, 'id') || !has_key(l:item_data, 'server_name') || !has_key(l:item_data, 'completion_item')
    return {}
  endif

  return l:item_data
endfunction

