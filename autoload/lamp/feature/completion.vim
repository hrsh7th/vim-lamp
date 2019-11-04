let s:Promise = vital#lamp#import('Async.Promise')
let s:Floatwin = lamp#view#floatwin#import()
let s:floatwin = s:Floatwin.new({})

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
let s:item_state = {}

function! lamp#feature#completion#init() abort
  augroup lamp#feature#completion
    autocmd!
    autocmd MenuPopup * call s:on_menu_popup()
    autocmd CompleteChanged * call s:on_complete_changed()
    autocmd CompleteDone * call s:on_complete_done()
  augroup END
endfunction

"
" s:on_menu_popup
"
function! s:on_menu_popup() abort
  let s:item_state = {}
endfunction

"
" s:on_complete_changed
"
function! s:on_complete_changed() abort
  call s:floatwin.hide()

  let l:item_data = s:get_item_data(v:completed_item)
  if empty(l:item_data)
    return
  endif

  let l:event = copy(v:event)

  " already resolve requested.
  let s:item_state[l:item_data.id] = get(s:item_state, l:item_data.id, {})
  if has_key(s:item_state[l:item_data.id], 'resolve')
    call lamp#debounce('lamp#feature#completion:show_documentation', { -> s:show_documentation(l:event, s:item_state[l:item_data.id]) }, 200)
    return
  endif

  " request resolve.
  let l:fn = {}
  function! l:fn.debounce(event, item_data) abort
    let s:item_state[a:item_data.id].resolve = s:resolve(a:item_data)
    call s:show_documentation(a:event, s:item_state[a:item_data.id])
  endfunction
  call lamp#debounce('lamp#feature#completion:show_documentation', { -> l:fn.debounce(l:event, l:item_data) }, 200)
endfunction

"
" s:on_complete_done
"
function! s:on_complete_done() abort
  call s:floatwin.hide()

  " clear debounce timer.
  call lamp#debounce('lamp#feature#completion:resolve', { -> {} }, 0)

  " check managed item.
  let l:item_data = s:get_item_data(v:completed_item)
  if empty(l:item_data)
    return
  endif

  " get item state.
  let l:item_state = get(s:item_state, l:item_data.id, {})

  " resolve if needed.
  let l:promise = get(l:item_state, 'resolve', {})
  if empty(l:promise)
    let l:promise = s:resolve(l:item_data)
  endif

  " resolve data.
  let l:completion_item = lamp#sync(l:promise)
  if empty(l:completion_item)
    return
  endif

  " textEdit.
  let l:text_edit = get(l:completion_item, 'textEdit', {})
  if !empty(l:text_edit)
    " TODO: The server that returns textEdit.
    call lamp#view#edit#apply(bufnr('%'), [l:text_edit])
  endif

  " additionalTextEdits.
  let l:additional_text_edits = get(l:completion_item, 'additionalTextEdits', {})
  if !empty(l:additional_text_edits)
    call timer_start(0, { -> lamp#view#edit#apply(bufnr('%'), l:additional_text_edits) }, { 'repeat': 1 })
  endif

  " executeCommand.
  if has_key(l:completion_item, 'command')
    let l:server = lamp#server#registry#get_by_name(l:item_data.server_name)
    if empty(l:server)
      return
    endif
    call l:server.request('workspace/executeCommand', {
          \   'command': l:completion_item.command.command,
          \   'arguments': get(l:completion_item.command, 'arguments')
          \ }).catch(lamp#rescue())
  endif

  " TODO: adjust cursor position
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
      if type(l:user_data) != type({}) " vim's json_decode is not throw exception.
        let l:user_data = {}
      endif
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

"
" s:show_documentation.
"
function! s:show_documentation(event, item_state) abort
  let l:resolve = get(a:item_state, 'resolve', {})
  if empty(l:resolve)
    return
  endif

  let l:completion_item = lamp#sync(l:resolve)
  if empty(l:completion_item)
    return
  endif

  let l:contents = []
  if has_key(l:completion_item, 'detail')
    let l:contents += lamp#protocol#markup_content#normalize({
          \   'language': &filetype,
          \   'value': l:completion_item.detail
          \ })
  endif

  if has_key(l:completion_item, 'documentation')
    let l:contents += lamp#protocol#markup_content#normalize(l:completion_item.documentation)
  endif

  if !empty(l:contents)
    let l:screenpos = s:get_floatwin_screenpos(a:event, l:contents)
    if !empty(l:screenpos)
      call s:floatwin.show(l:screenpos, l:contents)
    endif
  endif
endfunction

"
" s:get_floatwin_position.
"
function! s:get_floatwin_screenpos(event, contents) abort
  if empty(a:event)
    return {}
  endif

  let l:total_item_count = a:event.size
  let l:current_item_index = max([complete_info(['selected']).selected, 0]) " NOTE: sometimes vim returns -2.

  " create y.
  let l:pum_scrolloff = min([4, float2nr(a:event.height / 2)]) " TODO: calculate `4` from Vim script.
  let l:pum_scrolloff -= max([0, l:current_item_index - (a:event.size - l:pum_scrolloff)])
  let l:row = a:event.row + min([l:current_item_index, a:event.height - l:pum_scrolloff])

  " create x.
  let l:doc_width = s:floatwin.get_width(a:contents)
  let l:col_if_right = a:event.col + a:event.width + 1 + (a:event.scrollbar ? 1 : 0)
  let l:col_if_left = a:event.col - l:doc_width - 2

  " use more big space.
  if a:event.col > (&columns - l:col_if_right)
    let l:col = l:col_if_left
  else
    let l:col = l:col_if_right
  endif

  return [l:row, l:col]
endfunction

