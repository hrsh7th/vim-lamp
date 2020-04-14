let s:Position = vital#lamp#import('VS.LSP.Position')
let s:TextEdit = vital#lamp#import('VS.LSP.TextEdit')
let s:Promise = vital#lamp#import('Async.Promise')
let s:Floatwin = lamp#view#floatwin#import()
let s:floatwin = s:Floatwin.new({
\   'max_height': &lines / 3
\ })

let s:context = {}

"
" {
"   [id]: ...
" }
"
let s:managed_user_data_map = {}
let s:managed_user_data_key = 0

"
" lamp#feature#completion#init
"
function! lamp#feature#completion#init() abort
  execute printf('augroup lamp#feature#completion_%d', bufnr('%'))
    autocmd!
    autocmd InsertLeave <buffer> call s:on_insert_leave()
    autocmd CompleteChanged <buffer> call s:on_complete_changed()
    autocmd CompleteDone <buffer> call s:on_complete_done()
  augroup END
endfunction

"
" lamp#feature#completion#convert
"
function! lamp#feature#completion#convert(server_name, complete_position, response, ...) abort
  let l:params = get(a:000, 0, {
  \   'menu': '',
  \   'dup': 1,
  \ })

  let l:current_position = s:Position.cursor()

  let l:completed_items = []

  let l:completion_items = []
  let l:completion_items = type(a:response) == type({}) ? get(a:response, 'items', []) : l:completion_items
  let l:completion_items = type(a:response) == type([]) ? a:response : l:completion_items
  for l:completion_item in l:completion_items
    " textEdit
    if has_key(l:completion_item, 'textEdit') && type(l:completion_item.textEdit) == type({})
      let l:word = l:completion_item.label
      let l:offset = l:completion_item.textEdit.range.end.character > l:current_position.character
      if l:offset > 0
        let l:word = strpart(l:word, 0, strlen(l:word) - l:offset)
      endif
      let l:abbr = l:word . (l:word !=# l:completion_item.textEdit.newText ? '~' : '')

    " snippet
    elseif has_key(l:completion_item, 'insertText') && get(l:completion_item, 'insertTextFormat', 1) == 2
      let l:word = l:completion_item.label
      let l:abbr = l:completion_item.label . (l:word !=# l:completion_item.insertText ? '~' : '')

    " normal
    else
      let l:word = get(l:completion_item, 'insertText', l:completion_item.label)
      let l:abbr = l:completion_item.label
    endif

    " create user_data
    let l:user_data_key = '{"lamp/key":"' . s:managed_user_data_key . '"}'
    let s:managed_user_data_map[l:user_data_key] = {
          \   'server_name': a:server_name,
          \   'completion_item': l:completion_item,
          \   'complete_position': a:complete_position,
          \ }
    let s:managed_user_data_key += 1

    let l:word = trim(l:word)
    let l:abbr = trim(l:abbr)

    " create item
    call add(l:completed_items, {
          \   'word': l:word,
          \   'abbr': l:abbr,
          \   'menu': l:params.menu,
          \   'dup': l:params.dup,
          \   'kind': join([
          \     lamp#protocol#completion#get_kind_name(get(l:completion_item, 'kind', 0)),
          \     get(split(trim(get(l:completion_item, 'detail', '')), "\n"), 0, '')
          \   ], ' '),
          \   'user_data': l:user_data_key,
          \   '_filter_text': get(l:completion_item, 'filterText', l:word),
          \   '_sort_text': get(l:completion_item, 'sortText', l:word)
          \ })
  endfor

  return l:completed_items
endfunction

"
" get_managed_user_data
"
function! s:get_managed_user_data(completed_item) abort
  let l:user_data_string = get(a:completed_item, 'user_data')

  " just key.
  if has_key(s:managed_user_data_map, l:user_data_string)
    return s:managed_user_data_map[l:user_data_string]
  endif

  " modified json string.
  if stridx(l:user_data_string, '"lamp/key"') != -1
    try
      let l:user_data = json_decode(l:user_data_string)
      if has_key(l:user_data, 'lamp/key')
        let l:key = '{"lamp/key":"' . l:user_data['lamp/key'] . '"}'
        if has_key(s:managed_user_data_map, l:key)
          return s:managed_user_data_map[l:key]
        endif
      endif
    catch /.*/
    endtry
  endif

  return {}
endfunction

"
" clear_managed_user_data
"
function! s:clear_managed_user_data() abort
  let s:managed_user_data_map = {}
  let s:managed_user_data_key = 0
endfunction

"
" on_insert_leave
"
function! s:on_insert_leave() abort
  call lamp#debounce('lamp#feature#completion:resolve', { -> {} }, 0)
  call lamp#debounce('lamp#feature#completion:show_documentation', { -> {} }, 0)
  call s:floatwin.hide()
  call s:clear_managed_user_data()
endfunction

"
" on_complete_changed
"
function! s:on_complete_changed() abort
  if !lamp#config('feature.completion.floating_docs')
    return
  endif

  let l:user_data = s:get_managed_user_data(v:completed_item)
  if empty(l:user_data)
    call s:floatwin.hide()
    return
  endif

  let l:ctx = {}
  let l:ctx.event = copy(v:event)
  let l:ctx.completed_item = copy(v:completed_item)
  let l:ctx.user_data = l:user_data
  function! l:ctx.callback() abort
    if empty(v:completed_item) || get(v:completed_item, 'user_data', '') !=# get(self.completed_item, 'user_data', '')
      return
    endif

    if self.event.width >= float2nr(&columns / 2)
      return
    endif

    call s:resolve_completion_item(self.user_data).then({ completion_item ->
          \   s:show_documentation(self.event, self.completed_item, completion_item)
          \ })
  endfunction

  call lamp#debounce(
        \   'lamp#feature#completion:show_documentation',
        \   { -> l:ctx.callback() },
        \   10
        \ )
endfunction

"
" on_complete_done
"
function! s:on_complete_done() abort
  " clear.
  call lamp#debounce('lamp#feature#completion:resolve', { -> {} }, 0)
  call lamp#debounce('lamp#feature#completion:show_documentation', { -> {} }, 0)
  call s:floatwin.hide()

  let s:context.done_position = s:Position.cursor()
  let s:context.done_line = getline('.')
  let s:context.completed_item = v:completed_item
  let s:context.user_data = s:get_managed_user_data(v:completed_item)

  if !empty(v:completed_item) && strlen(get(v:completed_item, 'word', '')) > 0
    undojoin | noautocmd call feedkeys("\<Plug>(lamp-completion:on_complete_done_after)", '')
  endif
endfunction

"
" on_complete_done_after
"
inoremap <silent><nowait> <Plug>(lamp-completion:on_complete_done_after) <C-r>=<SID>on_complete_done_after()<CR>
function! s:on_complete_done_after() abort
  let l:done_position = s:context.done_position
  let l:done_line = s:context.done_line
  let l:completed_item = s:context.completed_item
  let l:user_data = s:context.user_data

  if mode()[0] ==# 'n'
    return ''
  endif

  if empty(l:user_data)
    return ''
  endif

  " <BS>, <C-w> etc.
  if strlen(getline('.')) < strlen(l:done_line)
    return ''
  endif

  call s:clear_managed_user_data()

  " completionItem/resolve
  try
    let l:completion_item = lamp#sync(s:resolve_completion_item(l:user_data))
  catch /.*/
    let l:completion_item = l:user_data.completion_item
  endtry

  " Clear completed string if needed.
  let l:expandable_state = s:get_expandable_state(l:completed_item, l:completion_item)
  if !empty(l:expandable_state)
    undojoin | call s:clear_completed_string(
          \   l:completed_item,
          \   l:completion_item,
          \   l:done_line,
          \   l:done_position,
          \   l:user_data.complete_position
          \ )
  endif

  " additionalTextEdits.
  if has_key(l:completion_item, 'additionalTextEdits')
    undojoin | call lamp#view#edit#apply(bufnr('%'), l:completion_item.additionalTextEdits)
  endif

  " executeCommand.
  if has_key(l:completion_item, 'command')
    let l:server = lamp#server#registry#get_by_name(l:user_data.server_name)
    if !empty(l:server)
      let l:p = l:server.request('workspace/executeCommand', {
            \   'command': l:completion_item.command.command,
            \   'arguments': get(l:completion_item.command, 'arguments', [])
            \ }).catch(lamp#rescue())
      try
        call lamp#sync(l:p)
      catch /.*/
      endtry
    endif
  endif

  " snippet or textEdit.
  if !empty(l:expandable_state)
    undojoin | call lamp#config('feature.completion.snippet.expand')({
          \   'body': l:expandable_state.text
          \ })
  endif

  return ''
endfunction

"
" resolve_completion_item
"
function! s:resolve_completion_item(user_data) abort
  if has_key(a:user_data, 'resolve')
    return a:user_data.resolve
  endif

  let l:server = lamp#server#registry#get_by_name(a:user_data.server_name)
  if empty(l:server) || !l:server.supports('capabilities.completionProvider.resolveProvider')
    let a:user_data.resolve = s:Promise.resolve(a:user_data.completion_item)
    return a:user_data.resolve
  endif

  let a:user_data.resolve = l:server.request('completionItem/resolve',a:user_data.completion_item)
  let a:user_data.resolve = a:user_data.resolve.then({ item -> empty(item) ? a:user_data.completion_item : item })
  let a:user_data.resolve = a:user_data.resolve.catch(lamp#rescue(a:user_data.completion_item))
  return a:user_data.resolve
endfunction

"
" get_expandable_state
"
function! s:get_expandable_state(completed_item, completion_item) abort
  if has_key(a:completion_item, 'textEdit') &&
        \ a:completed_item.word !=# a:completion_item.textEdit.newText
    return {
          \   'text': a:completion_item.textEdit.newText
          \ }
  endif

  if get(a:completion_item, 'insertTextFormat', 1) == 2 &&
        \ has_key(a:completion_item, 'insertText') &&
        \ a:completed_item.word !=# a:completion_item.insertText
    return {
          \   'text': a:completion_item.insertText
          \ }
  endif
  return {}
endfunction

"
" clear_completed_string
"
function! s:clear_completed_string(completed_item, completion_item, done_line, done_position, complete_position) abort
  " Remove commit characters.
  call setline('.', a:done_line)

  " Create remove range.
  let l:range = {
  \   'start': {
  \     'line': a:done_position.line,
  \     'character': a:done_position.character - strchars(a:completed_item.word)
  \   },
  \   'end': a:done_position
  \ }

  " Expand remove range to textEdit.
  if has_key(a:completion_item, 'textEdit')
    let l:range = {
    \   'start': {
    \     'line': a:completion_item.textEdit.range.start.line,
    \     'character': a:completion_item.textEdit.range.start.character,
    \   },
    \   'end': {
    \     'line': a:completion_item.textEdit.range.end.line,
    \     'character': a:completion_item.textEdit.range.end.character + strchars(a:completed_item.word) - (a:complete_position.character - l:range.start.character)
    \   }
    \ }
  endif

  undojoin | call s:TextEdit.apply('%', [{ 'range': l:range, 'newText': '' }])
  call cursor(s:Position.lsp_to_vim('%', l:range.start))
endfunction

"
" show_documentation
"
function! s:show_documentation(event, completed_item, completion_item) abort
  if mode()[0] !=# 'i'
    return
  endif

  if !pumvisible() || empty(v:completed_item) || get(v:completed_item, 'user_data') !=# get(a:completed_item, 'user_data')
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
" get_floatwin_screenpos
"
function! s:get_floatwin_screenpos(event, contents) abort
  if empty(a:event)
    return []
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

  if l:col <= 0
    return []
  endif
  if &columns <= l:col + l:doc_width
    return []
  endif

  return [l:row, l:col]
endfunction

