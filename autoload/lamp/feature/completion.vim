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
    call s:resolve(a:item_data).then({ completion_item -> s:show_documentation(a:event, completion_item) })
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
  function! l:fn.next_tick(recent_position, recent_line, completed_item) abort
    let l:item_data = s:get_item_data(a:completed_item)
    if empty(l:item_data)
      let s:item_state = {}
      return
    endif
    let l:item_state = get(s:item_state, l:item_data.id, {})
    let s:item_state = {}

    " <BS>, <C-w> etc.
    if strlen(getline('.')) < strlen(a:recent_line)
      return
    endif

    " resolve completion item.
    let l:completion_item = lamp#sync(s:resolve(l:item_data))
    if empty(l:completion_item)
      let l:completion_item = l:item_data.completion_item
    endif

    " check `lamp#complete_select` or `commitCharacters`
    if !g:lamp#private_context['feature.completion.selected'] &&
          \ index(s:get_commit_characters(l:item_data, l:completion_item), s:recent_inserted_char) == -1
      return
    endif
    let g:lamp#private_context['feature.completion.selected'] = v:false

    let l:is_snippet = get(l:completion_item, 'insertTextFormat', 1) == 2 && has_key(l:completion_item, 'insertText')
    let l:has_text_edit = !empty(get(l:completion_item, 'textEdit', {}))

    " remove completed string if need.
    if l:has_text_edit || l:is_snippet
      " Remove last inserted character.
      call setline('.', a:recent_line)

      " remove completed string.
      let l:start_position = [a:recent_position[1], (a:recent_position[2] + a:recent_position[3]) - strlen(l:completion_item.label)]
      call lamp#view#edit#apply(bufnr('%'), [{
            \   'range': {
            \     'start': {
            \       'line': l:start_position[0] - 1,
            \       'character': l:start_position[1] - 1
            \     },
            \     'end': {
            \       'line': a:recent_position[1] - 1,
            \       'character': (a:recent_position[2] + a:recent_position[3]) - 1,
            \     }
            \   },
            \   'newText': ''
            \ }])
    endif

    " Snippet or textEdit.
    if l:is_snippet
      call cursor(l:start_position)
      call lamp#config('feature.completion.snippet.expand')({
            \   'body': split(l:completion_item.insertText, "\n\|\r", v:true)
            \ })
    elseif l:has_text_edit
      call lamp#view#edit#apply(bufnr('%'), [{
            \   'range': l:completion_item.textEdit.range,
            \   'newText': ''
            \ }])
      call cursor(l:start_position)
      call lamp#config('feature.completion.snippet.expand')({
            \   'body': split(l:completion_item.textEdit.newText, "\n\|\r", v:true)
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

  let l:recent_position = getpos('.')
  let l:recent_line = getline('.')
  call timer_start(0, { -> l:fn.next_tick(l:recent_position, l:recent_line, v:completed_item) }, { 'repeat': 1 })
endfunction

"
" s:resolve
"
function! s:resolve(item_data) abort
  let s:item_state[a:item_data.id] = get(s:item_state, a:item_data.id, {})
  if has_key(s:item_state[a:item_data.id], 'resolve')
    return s:item_state[a:item_data.id].resolve
  endif

  let l:server = lamp#server#registry#get_by_name(a:item_data.server_name)
  if empty(l:server) || !l:server.supports('capabilities.completionItem.resolveProvider')
    return s:Promise.resolve({})
  endif

  let s:item_state[a:item_data.id].resolve = l:server.request('completionItem/resolve', a:item_data.completion_item).catch(lamp#rescue({}))
  return s:item_state[a:item_data.id].resolve
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

