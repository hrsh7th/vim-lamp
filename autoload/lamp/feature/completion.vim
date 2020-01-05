let s:Promise = vital#lamp#import('Async.Promise')
let s:Floatwin = lamp#view#floatwin#import()
let s:floatwin = s:Floatwin.new({})

let s:context = {
      \   'curpos': [],
      \   'line': '',
      \   'completed_item': v:null,
      \ }

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
  augroup lamp#feature#completion
    autocmd!
    autocmd InsertLeave * call s:on_insert_leave()
    autocmd CompleteChanged * call s:on_complete_changed()
    autocmd CompleteDone * call s:on_complete_done()
  augroup END
endfunction

"
" lamp#feature#completion#convert
"
function! lamp#feature#completion#convert(server_name, response) abort
  let l:completed_items = []

  let l:completion_items = []
  let l:completion_items = type(a:response) == type({}) ? get(a:response, 'items', []) : l:completion_items
  let l:completion_items = type(a:response) == type([]) ? a:response : l:completion_items
  for l:completion_item in l:completion_items
    let l:word = get(l:completion_item, 'insertText', l:completion_item.label)
    let l:is_expandable = v:false
    if get(l:completion_item, 'insertTextFormat', 1) == 2
      if has_key(l:completion_item, 'textEdit')
        let l:word = l:completion_item.label
        let l:is_expandable = l:word != l:completion_item.textEdit.newText
      elseif has_key(l:completion_item, 'insertText')
        let l:word = l:completion_item.label
        let l:is_expandable = l:word != l:completion_item.insertText
      endif
    endif

    let l:user_data_key = '{"lamp/key":"' . s:managed_user_data_key . '"}'
    call add(l:completed_items, {
          \   'word': l:word,
          \   'abbr': l:word . (l:is_expandable ? '~' : ''),
          \   'menu': substitute(get(l:completion_item, 'detail', ''), "\\%(\r\n\\|\r\\|\n\\)", '', 'g'),
          \   'kind': lamp#protocol#completion#get_kind_name(get(l:completion_item, 'kind', 0)),
          \   'user_data': l:user_data_key,
          \   '_filter_text': get(l:completion_item, 'filterText', l:word),
          \ })
    let s:managed_user_data_map[l:user_data_key] = {
          \   'server_name': a:server_name,
          \   'completion_item': l:completion_item
          \ }
    let s:managed_user_data_key += 1
  endfor

  return l:completed_items
endfunction

"
" get_managed_user_data
"
function! s:get_managed_user_data(completed_item) abort
  if has_key(s:managed_user_data_map, get(a:completed_item, 'user_data'))
    return s:managed_user_data_map[a:completed_item.user_data]
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
  call lamp#debounce('lamp#feature#completion:show_documentation', { -> {} }, 100)
  call timer_start(0, { -> s:floatwin.hide() })
  call s:clear_managed_user_data()
endfunction

"
" on_complete_changed
"
function! s:on_complete_changed() abort
  call s:floatwin.hide()

  let l:user_data = s:get_managed_user_data(v:completed_item)
  if empty(l:user_data)
    return
  endif

  let l:ctx = {}
  let l:ctx.event = copy(v:event)
  let l:ctx.user_data = l:user_data
  function! l:ctx.callback() abort
    call s:resolve_completion_item(self.user_data).then({ completion_item ->
          \   s:show_documentation(self.event, completion_item)
          \ })
  endfunction

  let l:event = copy(v:event)
  call lamp#debounce(
        \   'lamp#feature#completion:show_documentation',
        \   { -> l:ctx.callback() },
        \   100
        \ )
endfunction

"
" on_complete_done
"
function! s:on_complete_done() abort
  " clear.
  call lamp#debounce('lamp#feature#completion:resolve', { -> {} }, 0)
  call lamp#debounce('lamp#feature#completion:show_documentation', { -> {} }, 100)
  call s:floatwin.hide()

  let s:context.curpos = getpos('.')
  let s:context.line = getline('.')
  let s:context.completed_item = v:completed_item
  let s:context.user_data = s:get_managed_user_data(v:completed_item)

  if !empty(v:completed_item)
    call s:clear_managed_user_data()
    call feedkeys(printf("\<C-r>=<SNR>%d_on_complete_done_after()\<CR>", s:SID()), 'n')
  endif
endfunction

"
" on_complete_done_after
"
function! s:on_complete_done_after() abort
  let l:curpos = s:context.curpos
  let l:line = s:context.line
  let l:completed_item = s:context.completed_item
  let l:user_data = s:context.user_data

  if mode()[0] ==# 'n'
    return ''
  endif

  if empty(l:user_data)
    return ''
  endif

  " <BS>, <C-w> etc.
  if strlen(getline('.')) < strlen(l:line)
    return ''
  endif

  " completionItem/resolve
  let l:completion_item = lamp#sync(s:resolve_completion_item(l:user_data))
  if empty(l:completion_item)
    let l:completion_item = l:user_data.completion_item
  endif

  " snippet or textEdit.
  let l:expandable_state = s:get_expandable_state(l:completed_item, l:completion_item)
  if !empty(l:expandable_state)
    undojoin | call s:clear_completed_string(
          \   l:curpos,
          \   l:line,
          \   l:completed_item,
          \   l:completion_item
          \ )
    undojoin | call lamp#config('feature.completion.snippet.expand')({
          \   'body': l:expandable_state.text
          \ })
  endif

  " additionalTextEdits.
  if has_key(l:completion_item, 'additionalTextEdits')
    undojoin | call lamp#view#edit#apply(bufnr('%'), l:completion_item.additionalTextEdits)
  endif

  " executeCommand.
  if has_key(l:completion_item, 'command')
    let l:server = lamp#server#registry#get_by_name(l:user_data.server_name)
    if !empty(l:server)
      call l:server.request('workspace/executeCommand', {
            \   'command': l:completion_item.command.command,
            \   'arguments': get(l:completion_item.command, 'arguments', [])
            \ }).catch(lamp#rescue())
    endif
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
    return s:Promise.resolve(a:user_data.completion_item)
  endif

  let a:user_data.resolve = l:server.request('completionItem/resolve', a:user_data.completion_item).catch(lamp#rescue({}))
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
function! s:clear_completed_string(curpos, line, completed_item, completion_item) abort
  " Remove last typed characters.
  call setline('.', a:line)

  let l:position = {
        \   'line': a:curpos[1] - 1,
        \   'character': (a:curpos[2] + a:curpos[3]) - 1,
        \ }

  " Remove completed string.
  let l:range = {
        \   'start': {
        \     'line': l:position.line,
        \     'character': l:position.character - strlen(a:completed_item.word)
        \   },
        \   'end': l:position
        \ }
  if has_key(a:completion_item, 'textEdit')
    let l:range = lamp#protocol#range#merge_expand(l:range, a:completion_item.textEdit.range)
  endif
  call lamp#view#edit#apply(bufnr('%'), [{
        \   'range': l:range,
        \   'newText': '',
        \ }])
  call cursor([l:range.start.line + 1, l:range.start.character + 1])
endfunction

"
" show_documentation
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
" get_floatwin_screenpos
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

"
" SID.
"
function! s:SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun

