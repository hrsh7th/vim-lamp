let s:Position = vital#lamp#import('VS.LSP.Position')
let s:Text = vital#lamp#import('VS.LSP.Text')
let s:TextEdit = vital#lamp#import('VS.LSP.TextEdit')
let s:Promise = vital#lamp#import('Async.Promise')
let s:Floatwin = lamp#view#floatwin#import()
let s:CancellationToken = lamp#server#cancellation_token#import()

let s:context = {}

"
" {
"   [id]: ...
" }
"
let s:managed_user_data_map = {}
let s:managed_user_data_key = 0
let s:resolve_cancellation_token = v:null

"
" lamp#feature#completion#init
"
function! lamp#feature#completion#init() abort
  call lamp#view#floatwin#configure('completion', {
  \   'max_height': &lines / 3,
  \ })
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

  let l:completion_items = []
  let l:completion_items = type(a:response) == type({}) ? get(a:response, 'items', []) : l:completion_items
  let l:completion_items = type(a:response) == type([]) ? a:response : l:completion_items

  if has('nvim')
    return luaeval('lamp_feature_completion_convert(_A[1], _A[2], _A[3], _A[4], _A[5], _A[6])', [
    \   l:params,
    \   a:server_name,
    \   a:complete_position,
    \   l:completion_items
    \ ])
  else
    return s:convert(
    \   l:params,
    \   a:server_name,
    \   a:complete_position,
    \   l:completion_items
    \ )
  endif
endfunction

"
" convert
"
function! s:convert(params, server_name, complete_position, completion_items) abort
  let l:kind_map = lamp#protocol#completion#get_kind_map()

  let l:completed_items = []
  for l:completion_item in a:completion_items
    let l:label = trim(l:completion_item.label)
    let l:insert_text = trim(get(l:completion_item, 'insertText', l:label))

    if get(l:completion_item, 'insertTextFormat', 1) == 2
      let l:word = l:label
      let l:abbr = l:label

      let l:expandable = v:false
      if has_key(l:completion_item, 'textEdit')
        let l:expandable = l:word !=# get(l:completion_item.textEdit, 'newText', '')
      elseif has_key(l:completion_item, 'insertText')
        let l:expandable = l:word !=# l:completion_item.insertText
      endif

      if l:expandable
        let l:abbr = l:abbr . '~'
      endif
    else
      let l:word = l:insert_text
      let l:abbr = l:label
    endif

    " create user_data
    let l:user_data_key = '{"lamp/key":"' . s:managed_user_data_key . '"}'
    let s:managed_user_data_map[l:user_data_key] = {
    \   'server_name': a:server_name,
    \   'completion_item': l:completion_item,
    \   'complete_position': a:complete_position,
    \ }
    let s:managed_user_data_key += 1

    " create item
    let l:kind = get(l:kind_map, get(l:completion_item, 'kind', -1), '')
    call add(l:completed_items, {
    \   'word': l:word,
    \   'abbr': l:abbr,
    \   'menu': a:params.menu,
    \   'dup': a:params.dup,
    \   'kind': l:kind,
    \   'preselect': get(l:completion_item, 'preselect', v:false),
    \   'user_data': l:user_data_key,
    \   'filter_text': get(l:completion_item, 'filterText', v:null),
    \   'sort_text': get(l:completion_item, 'sortText', v:null)
    \ })
  endfor

  return l:completed_items
endfunction

"
" lamp_feature_completion_convert
"
" @see https://github.com/neoclide/coc.nvim/blob/master/src/util/complete.ts#L16
" @see https://github.com/neoclide/coc.nvim/blob/master/src/languages.ts#L726
"
if has('nvim')
lua << EOF
function lamp_feature_completion_convert(params, server_name, complete_position, completion_items)
  local kind_map = vim.call('lamp#protocol#completion#get_kind_map')

  local complete_items = {}
  for _, completion_item in pairs(completion_items) do
    local label = string.gsub(completion_item.label, "^%s*(.-)%s*$", "%1")
    local insert_text = completion_item.insertText and string.gsub(completion_item.insertText, "^%s*(.-)%s*$", "%1") or label

    local word = ''
    local abbr = ''
    if completion_item.insertTextFormat == 2 then
      word = label
      abbr = label

      local expandable = false
      if completion_item.textEdit ~= nil then
        expandable = word ~= completion_item.textEdit.newText
      elseif completion_item.insertText ~= nil then
        expandable = word ~= completion_item.insertText
      end

      if expandable then
        abbr = abbr .. '~'
      end
    else
      word = insert_text
      abbr = label
    end

    local kind = kind_map['' .. (completion_item.kind or '')] or ''
    table.insert(complete_items, {
      word = word;
      abbr = abbr;
      menu = params.menu;
      dup = params.dup;
      preselect = completion_item.preselect or false,
      kind = kind;
      user_data = {
        lamp = {
          server_name = server_name;
          completion_item = completion_item;
          complete_position = complete_position;
        };
      };
      filter_text = completion_item.filterText or nil;
      sort_text = completion_item.sortText or nil;
    })
  end
  return complete_items
end
EOF
endif

"
" get_managed_user_data
"
function! s:get_managed_user_data(completed_item) abort
  let l:user_data = get(a:completed_item, 'user_data', v:null)
  if l:user_data is# v:null
    return {}
  endif

  " dict.
  if type(l:user_data) == type({})
    return get(l:user_data, 'lamp', {})
  endif

  " just key.
  if has_key(s:managed_user_data_map, l:user_data)
    return s:managed_user_data_map[l:user_data]
  endif

  " modified json string.
  if stridx(l:user_data, '"lamp/key"') != -1
    try
      let l:user_data = json_decode(l:user_data)
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
  call lamp#view#floatwin#hide('completion')
  call lamp#debounce('lamp#feature#completion:on_complete_changed', { -> {} }, 0)
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
    call lamp#view#floatwin#hide('completion')
    return
  endif
  if mode()[0] ==# 'n'
    return
  endif

  let l:event = copy(v:event)
  if l:event.width >= float2nr(&columns / 2)
    return
  endif

  let l:ctx = {}
  let l:ctx.user_data = l:user_data
  let l:ctx.event = l:event
  let l:ctx.completed_item = v:completed_item
  function! l:ctx.callback() abort
    call s:resolve_completion_item(self.user_data).then({ completion_item ->
    \   s:show_documentation(self.event, self.completed_item, completion_item)
    \ })
  endfunction
  call lamp#debounce('lamp#feature#completion:on_complete_changed', { -> l:ctx.callback() }, 80)
endfunction

"
" on_complete_done
"
function! s:on_complete_done() abort
  let s:context.done_position = s:Position.cursor()
  let s:context.done_line = getline('.')
  let s:context.completed_item = v:completed_item
  let s:context.user_data = s:get_managed_user_data(v:completed_item)

  if !empty(v:completed_item) && strlen(get(v:completed_item, 'word', '')) > 0 && !empty(s:context.user_data)
    call lamp#view#floatwin#hide('completion')
    noautocmd call feedkeys("\<Plug>(lamp-completion:on_complete_done_after)", '')
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
  let l:complete_position = l:user_data.complete_position
  let l:complete_start_character = l:done_position.character - strchars(l:completed_item.word)

  if mode()[0] ==# 'n'
    return ''
  endif

  " <BS>, <C-w> etc.
  if strlen(getline('.')) < strlen(l:done_line)
    return ''
  endif

  call s:clear_managed_user_data()

  call lamp#log('[COMPLETE_DONE]', s:context)

  " completionItem/resolve
  try
    let l:completion_item = lamp#sync(s:resolve_completion_item(l:user_data))
  catch /.*/
    let l:completion_item = l:user_data.completion_item
  endtry

  " Clear completed string if needed.
  let l:is_expandable = s:is_expandable(l:done_line, l:done_position, l:complete_position, l:completion_item, l:completed_item)
  if l:is_expandable
    call s:clear_completed_string(
    \   l:done_line,
    \   l:done_position,
    \   l:complete_position
    \ )
  endif

  " additionalTextEdits.
  if type(get(l:completion_item, 'additionalTextEdits', v:null)) == type([])
    call lamp#view#edit#apply(bufnr('%'), l:completion_item.additionalTextEdits)
  endif

  " snippet or textEdit.
  if l:is_expandable
    " create text_edit
    if type(get(l:completion_item, 'textEdit', v:null)) == type({})
      let l:overflow_before = l:complete_start_character - l:completion_item.textEdit.range.start.character
      let l:overflow_after = l:completion_item.textEdit.range.end.character - l:complete_position.character
      let l:text = get(l:completion_item.textEdit, 'newText', l:completed_item.word)
    else
      let l:overflow_before = 0
      let l:overflow_after = 0
      let l:text = get(l:completion_item, 'insertText', l:completed_item.word)
    endif

    " apply snipept or text_edit
    let l:position = s:Position.cursor()
    let l:range = {
    \   'start': {
    \     'line': l:position.line,
    \     'character': l:position.character - (l:complete_position.character - l:complete_start_character) - l:overflow_before,
    \   },
    \   'end': {
    \     'line': l:position.line,
    \     'character': l:position.character + l:overflow_after,
    \   }
    \ }
    if get(l:completion_item, 'insertTextFormat', 1) == 2
      call s:TextEdit.apply('%', [{ 'range': l:range, 'newText': '' }])
      call cursor(s:Position.lsp_to_vim('%', l:range.start))
      call lamp#config('feature.completion.snippet.expand')({
      \   'body': l:text,
      \ })
    else
      call s:TextEdit.apply('%', [{ 'range': l:range, 'newText': l:text }])
      let l:lines = s:Text.split_by_eol(l:text)
      let l:start = l:range.start
      let l:start.line += len(l:lines) - 1
      let l:start.character += strchars(l:lines[-1])
      call cursor(s:Position.lsp_to_vim('%', l:start))
    endif
  endif

  " executeCommand.
  if type(get(l:completion_item, 'command', v:null)) == type({})
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

  return ''
endfunction

"
" clear_completed_string
"
function! s:clear_completed_string(done_line, done_position, complete_position) abort
  let l:before = strcharpart(a:done_line, 0, a:complete_position.character)
  let l:after = strcharpart(a:done_line, a:done_position.character, strchars(a:done_line) - a:done_position.character)
  call setline('.', l:before . l:after)
  call cursor([a:done_position.line + 1, strlen(l:before) + 1])
endfunction

"
" is_expandable
"
function! s:is_expandable(done_line, done_position, complete_position, completion_item, completed_item) abort
  if get(a:completion_item, 'textEdit', v:null) isnot# v:null
    if a:completion_item.textEdit.range.start.line != a:completion_item.textEdit.range.end.line
      return v:true
    endif

    " compute if textEdit will change text.
    let l:new_text = get(a:completion_item.textEdit, 'newText', '')
    let l:completed_before = strcharpart(a:done_line, 0, a:complete_position.character)
    let l:completed_after = strcharpart(a:done_line, a:done_position.character, strchars(a:done_line) - a:done_position.character)
    let l:completed_line = l:completed_before . l:completed_after
    let l:text_edit_before = strcharpart(l:completed_line, 0, a:completion_item.textEdit.range.start.character)
    let l:text_edit_after = strcharpart(l:completed_line, a:completion_item.textEdit.range.end.character)

    return a:done_line !=# l:text_edit_before . s:trim_unmeaning_tabstop(l:new_text) . l:text_edit_after
  endif
  return get(a:completion_item, 'insertText', a:completed_item.word) !=# s:trim_unmeaning_tabstop(a:completed_item.word)
endfunction

"
" trim_unmeaning_tabstop
"
function! s:trim_unmeaning_tabstop(text) abort
  return substitute(a:text, '\%(\$0\|\${0}\)$', '', 'g')
endfunction

"
" resolve_completion_item
"
function! s:resolve_completion_item(user_data) abort
  if has_key(a:user_data, 'resolve')
    return a:user_data.resolve
  endif

  if !empty(s:resolve_cancellation_token)
    call s:resolve_cancellation_token.cancel()
  endif
  let s:resolve_cancellation_token = s:CancellationToken.new()

  let l:server = lamp#server#registry#get_by_name(a:user_data.server_name)
  if empty(l:server) || !l:server.supports('capabilities.completionProvider.resolveProvider')
    let a:user_data.resolve = s:Promise.resolve(a:user_data.completion_item)
    return a:user_data.resolve
  endif

  let a:user_data.resolve = l:server.request('completionItem/resolve',a:user_data.completion_item, { 'cancellation_token': s:resolve_cancellation_token })
  let a:user_data.resolve = a:user_data.resolve.then({ item -> empty(item) ? a:user_data.completion_item : item })
  let a:user_data.resolve = a:user_data.resolve.catch(lamp#rescue(a:user_data.completion_item))
  return a:user_data.resolve
endfunction

"
" show_documentation
"
function! s:show_documentation(event, completed_item, completion_item) abort
  if mode()[0] !=# 'i'
    return
  endif

  if !pumvisible() || empty(v:completed_item) || get(v:completed_item, 'user_data', v:null) isnot# get(a:completed_item, 'user_data', v:null)
    return
  endif

  let l:contents = []

  " detail
  if type(get(a:completion_item, 'detail', v:null)) == type('')
    let l:contents += lamp#protocol#markup_content#normalize({
    \   'language': &filetype,
    \   'value': a:completion_item.detail
    \ })
  endif

  " documentation
  if get(a:completion_item, 'documentation', v:null) isnot# v:null
    let l:contents += lamp#protocol#markup_content#normalize(a:completion_item.documentation)
  endif

  if !empty(l:contents)
    let l:screenpos = s:get_floatwin_screenpos(a:event, l:contents)
    if !empty(l:screenpos)
      call lamp#view#floatwin#show('completion', l:screenpos, l:contents)
    endif
  else
    call lamp#view#floatwin#hide('completion')
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
  let l:row = a:event.row + min([l:current_item_index, float2nr(a:event.height) - l:pum_scrolloff])

  " create x.
  let l:doc_width = lamp#view#floatwin#get('completion').get_width(a:contents)
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
