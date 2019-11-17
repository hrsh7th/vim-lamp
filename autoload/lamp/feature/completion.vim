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
" Last inserted character.
" This use to check commitCharacters.
"
let s:recent_inserted_char = ''

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
    autocmd CompleteChanged * call s:on_complete_changed()
    autocmd InsertCharPre * call s:on_insert_char_pre()
    autocmd CompleteDone * call s:on_complete_done()
  augroup END
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

  let l:fn = {}
  function! l:fn.debounce(event, item_data) abort
    call s:resolve_completion_item(a:item_data).then({ completion_item -> s:show_documentation(a:event, completion_item) })
  endfunction

  let l:event = copy(v:event)
  call lamp#debounce('lamp#feature#completion:show_documentation', { -> l:fn.debounce(l:event, l:item_data) }, 100)
endfunction

"
" s:on_insert_char_pre
"
function! s:on_insert_char_pre() abort
  let s:recent_inserted_char = v:char
endfunction

"
" s:on_complete_done
"
function! s:on_complete_done() abort
  " clear.
  call lamp#debounce('lamp#feature#completion:show_documentation', { -> {} }, 100)
  call lamp#debounce('lamp#feature#completion:resolve', { -> {} }, 0)
  call s:floatwin.hide()

  let l:fn = {}
  function! l:fn.next_tick(is_selected, position_before_complete_done, line_before_complete_done, completed_item) abort
    let l:item_data = s:get_item_data(a:completed_item)
    if empty(l:item_data)
      return
    endif

    " <BS>, <C-w> etc.
    if strlen(getline('.')) < strlen(a:line_before_complete_done)
      return
    endif

    " completionItem/resolve
    let l:completion_item = lamp#sync(s:resolve_completion_item(l:item_data))
    if empty(l:completion_item)
      let l:completion_item = l:item_data.completion_item
    endif

    " check `lamp#complete_select` or `commitCharacters`
    if !a:is_selected && index(s:get_commit_characters(l:item_data, l:completion_item), s:recent_inserted_char) == -1
      return
    endif

    " snippet or textEdit.
    let l:expandable_state = s:get_expandable_state(l:completion_item)
    if !empty(l:expandable_state)
      call s:clear_completed_string(
            \   a:position_before_complete_done,
            \   a:line_before_complete_done,
            \   l:completion_item
            \ )
      call lamp#config('feature.completion.snippet.expand')({
            \   'body': split(l:expandable_state.text, "\n\|\r", v:true)
            \ })
    endif

    " additionalTextEdits.
    if has_key(l:completion_item, 'additionalTextEdits')
      call lamp#view#edit#apply(bufnr('%'), l:completion_item.additionalTextEdits)
    endif

    " executeCommand.
    if has_key(l:completion_item, 'command')
      let l:server = lamp#server#registry#get_by_name(l:item_data.server_name)
      if !empty(l:server)
        call l:server.request('workspace/executeCommand', {
              \   'command': l:completion_item.command.command,
              \   'arguments': get(l:completion_item.command, 'arguments')
              \ }).catch(lamp#rescue())
      endif
    endif
  endfunction

  let l:is_selected = g:lamp#state['feature.completion.is_selected']
  let l:position_before_complete_done = getpos('.')
  let l:line_before_complete_done = getline('.')

  call timer_start(0, { -> l:fn.next_tick(
        \   l:is_selected,
        \   l:position_before_complete_done,
        \   l:line_before_complete_done,
        \   v:completed_item
        \ ) }, { 'repeat': 1 })

  let g:lamp#state['feature.completion.is_selected'] = v:false
endfunction

"
" s:resolve_completion_item
"
function! s:resolve_completion_item(item_data) abort
  let s:item_state[a:item_data.id] = get(s:item_state, a:item_data.id, {})
  if has_key(s:item_state[a:item_data.id], 'resolve')
    return s:item_state[a:item_data.id].resolve
  endif

  let l:server = lamp#server#registry#get_by_name(a:item_data.server_name)
  if empty(l:server) || !l:server.supports('capabilities.completionProvider.resolveProvider')
    return s:Promise.resolve(a:item_data.completion_item)
  endif

  let s:item_state[a:item_data.id].resolve = l:server.request('completionItem/resolve', a:item_data.completion_item).catch(lamp#rescue({}))
  return s:item_state[a:item_data.id].resolve
endfunction

"
" s:get_expandable_state
"
function! s:get_expandable_state(completion_item) abort
  if has_key(a:completion_item, 'textEdit') && a:completion_item.label !=# a:completion_item.textEdit.newText
    return {
          \   'text': a:completion_item.textEdit.newText
          \ }
  endif

  if get(a:completion_item, 'insertTextFormat', 1) == 2 && a:completion_item.label !=# get(a:completion_item, 'insertText', '')
    return {
          \   'text': a:completion_item.insertText
          \ }
  endif
  return {}
endfunction

"
" s:clear_completed_string
"
function! s:clear_completed_string(position_before_complete_done, line_before_complete_done, completion_item) abort
  " Remove last typed characters.
  call setline('.', a:line_before_complete_done)

  " Remove completed string.
  let l:start_position = [a:position_before_complete_done[1], (a:position_before_complete_done[2] + a:position_before_complete_done[3]) - strlen(a:completion_item.label)]
  call lamp#view#edit#apply(bufnr('%'), [{
        \   'range': {
        \     'start': {
        \       'line': l:start_position[0] - 1,
        \       'character': l:start_position[1] - 1
        \     },
        \     'end': {
        \       'line': a:position_before_complete_done[1] - 1,
        \       'character': (a:position_before_complete_done[2] + a:position_before_complete_done[3]) - 1,
        \     }
        \   },
        \   'newText': ''
        \ }])
  call cursor(l:start_position)
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

  if !has_key(l:user_data, s:user_data_key)
    return {}
  endif

  let l:item_data = l:user_data[s:user_data_key]
  if !has_key(l:item_data, 'id') || !has_key(l:item_data, 'server_name') || !has_key(l:item_data, 'completion_item')
    return {}
  endif

  return l:item_data
endfunction

"
" s:get_commit_characters
"
function! s:get_commit_characters(item_data, completion_item) abort
  let l:commit_chars = []
  let l:commit_chars += get(a:completion_item, 'commitCharacters', [])
  let l:server = lamp#server#registry#get_by_name(a:item_data.server_name)
  if !empty(l:server)
    let l:commit_chars += l:server.capability.get_completion_all_commit_characters()
  endif
  return l:commit_chars
endfunction

"
" s:show_documentation.
"
function! s:show_documentation(event, completion_item) abort
  if mode()[0] !=# 'i'
    return
  endif

  let l:contents = []
  if has_key(a:completion_item, 'detail')
    let l:contents += lamp#protocol#markup_content#normalize({
          \   'language': &filetype,
          \   'value': a:completion_item.detail
          \ })
  endif

  if has_key(a:completion_item, 'documentation')
    let l:contents += lamp#protocol#markup_content#normalize(a:completion_item.documentation)
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

