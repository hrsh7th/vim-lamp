let g:lamp#state = {
      \   'feature.completion.is_selected': v:false
      \ }

let s:Promise = vital#lamp#import('Async.Promise')
let s:Server = lamp#server#import()

let s:debounce_ids = {}

let s:on_locations = { locations -> [setqflist(locations, 'r'), execute('copen')] }
let s:config = {
      \   'root': expand('<sfile>:p:h:h'),
      \   'debug.log': v:null,
      \   'feature.definition.on_definitions': s:on_locations,
      \   'feature.type_definition.on_type_definitions': s:on_locations,
      \   'feature.declaration.on_declaration': s:on_locations,
      \   'feature.implementation.on_implementations': s:on_locations,
      \   'feature.references.on_references': s:on_locations,
      \   'feature.rename.on_renamed': s:on_locations,
      \   'feature.completion.snippet.expand': v:null,
      \   'view.sign.error.text': 'x',
      \   'view.sign.warning.text': '!',
      \   'view.sign.information.text': 'i',
      \   'view.sign.hint.text': '?',
      \   'view.floatwin.fenced_languages': {
      \     'help': ['help'],
      \     'vim': ['vim'],
      \     'typescript': ['ts', 'tsx', 'typescript', 'typescriptreact', 'typescript.tsx'],
      \     'javascript': ['js', 'jsx', 'javascript', 'javascriptreact', 'javascript.jsx'],
      \   }
      \ }

call s:Promise.on_unhandled_rejection({ err -> lamp#log('[ERROR]', err) })

"
" Register language server.
"
function! lamp#register(name, option) abort
  if !has_key(a:option, 'command')
    throw 'lamp#register: `option.command` is required.'
  endif

  if !has_key(a:option, 'filetypes')
    throw 'lamp#register: `option.filetypes` is required.'
  endif

  let l:server = s:Server.new(a:name, a:option)
  call lamp#server#registry#set(l:server)
  return l:server
endfunction

"
" Logging.
"
function! lamp#log(...) abort
  if exists('$LAMP_TEST')
    call lamp#config('debug.log', '/tmp/lamp.log')
  endif
  if !empty(lamp#config('debug.log'))
    call writefile([strcharpart(join([strftime('%H:%M:%S')] + a:000, "\t"), 0, 512)], lamp#config('debug.log'), 'a')
  endif
endfunction

"
" config.
"
function! lamp#config(key, ...) abort
  if len(a:000) > 0
    let s:config[a:key] = a:000[0]
  endif
  return s:config[a:key]
endfunction

"
" Debounce.
"
function! lamp#debounce(id, fn, timeout) abort
  if has_key(s:debounce_ids, a:id)
    call timer_stop(s:debounce_ids[a:id])
  endif
  let s:debounce_ids[a:id] = timer_start(a:timeout, { -> s:debounce(a:fn) }, { 'repeat': 1 })
endfunction
function! s:debounce(fn) abort
  try
    call a:fn()
  catch /.*/
    call lamp#log('[ERROR]', { 'exception': v:exception, 'throwpoint': v:throwpoint })
  endtry
endfunction

"
" rescue.
"
if !exists('$LAMP_TEST')
  function! lamp#rescue(...) abort
    function! s:catch(default, err) abort
      call lamp#log('[RESCUE]', a:err)
      return a:default
    endfunction
    return function('s:catch', [get(a:000, 0, v:null)], {})
  endfunction
else
  function! lamp#rescue(...) abort
    return { err -> execute('throw err') }
  endfunction
endif

"
" Sync.
"
function! lamp#sync(promise_or_fn, ...) abort
  let l:count = floor(get(a:000, 0, 10 * 1000) / 10)
  while l:count > 0
    if type(a:promise_or_fn) == v:t_func
      if a:promise_or_fn()
        return
      endif
    else
      if a:promise_or_fn._state == 1
        return a:promise_or_fn._result
      elseif a:promise_or_fn._state == 2
        throw json_encode(a:promise_or_fn._result)
      endif
    endif
    sleep 10m
    let l:count -= 1
  endwhile
  throw 'lamp#wait_for timeout.'
endfunction

"
" get.
"
function! lamp#get(dict, path, default) abort
  let l:keys = split(a:path, '\.')

  let l:target = a:dict
  for l:key in l:keys
    if index([v:t_dict, v:t_list], type(l:target)) == -1
      return a:default
    endif

    if !has_key(l:target, l:key)
      return a:default
    endif

    let l:value = l:target[l:key]
    unlet! l:target
    let l:target = l:value
  endfor

  return l:target
endfunction

"
" findup.
"
function! lamp#findup(...) abort
  let l:path = fnamemodify(bufname('%'), ':p')
  while l:path != '/'
    for l:marker in a:000
      let l:candidate = l:path . '/' . l:marker
      if isdirectory(l:candidate) || filereadable(l:candidate)
        return l:path
      endif
    endfor
    let l:path = substitute(l:path, '/[^/]*$', '', 'g')
  endwhile
  return getcwd()
endfunction

"
" merge.
"
function! lamp#merge(dict1, dict2) abort
  try
    let l:returns = deepcopy(a:dict1)

    " merge same key.
    for l:key in keys(a:dict1)
      if !has_key(a:dict2, l:key)
        continue
      endif

      " both dict.
      if type(a:dict1[l:key]) == type({}) && type(a:dict2[l:key]) == type({})
        let l:returns[l:key] = lamp#merge(a:dict1[l:key], a:dict2[l:key])
      endif

      " both list.
      if type(a:dict1[l:key]) == type([]) && type(a:dict2[l:key]) == type([])
        let l:returns[l:key] = extend(copy(a:dict1[l:key]), a:dict2[l:key])
      endif

      " remove key when v:null provided explicitly.
      if type(a:dict1[l:key]) != type(v:null) && type(a:dict2[l:key]) == type(v:null)
        unlet l:returns[l:key]
      endif
    endfor

    " add new key.
    for l:key in keys(a:dict2)
      " always have key.
      if has_key(a:dict1, l:key)
        continue
      endif
      let l:returns[l:key] = a:dict2[l:key]
    endfor
  catch /.*/
    echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
  endtry

  return l:returns
endfunction

"
" complete.
"
function! lamp#complete(find_start, base) abort
  if a:find_start == 1
    let l:before_line = lamp#view#cursor#get_before_line()
    return strlen(substitute(l:before_line, '\k*$', '', 'g'))
  endif

  let l:servers = lamp#server#registry#find_by_filetype(&filetype)
  let l:servers = filter(l:servers, { k, v -> v.supports('capabilities.completionProvider') })
  if empty(l:servers)
    return { 'words': [] }
  endif

  " init context.
  let s:context = {}
  let s:context.id = 0
  let s:context.requests = {}

  " send request.
  for l:server in l:servers
    let s:context.requests[l:server.name] = l:server.request('textDocument/completion', {
          \   'textDocument': lamp#protocol#document#identifier(bufnr('%')),
          \   'position': lamp#protocol#position#get(),
          \   'context': {
          \     'triggerKind': 2,
          \     'triggerCharacter': lamp#view#cursor#get_before_char_skip_white()
          \   }
          \ }).catch(lamp#rescue([]))
  endfor

  " consume response.
  let l:returns = { 'words': [], 'refresh': 'always' }

  for [l:server_name, l:request] in items(s:context.requests)
    let l:response = lamp#sync(l:request)

    let l:items = []
    let l:items = type(l:response) == type({}) ? get(l:response, 'items', []) : l:items
    let l:items = type(l:response) == type([]) ? l:response : l:items
    for l:item in l:items
      let l:filter_text = get(l:item, 'filterText', l:item.label)
      if l:filter_text !~ '^' . a:base && strlen(a:base) >= 1
        continue
      endif

      let l:word = get(l:item, 'insertText', l:item.label)
      let l:is_expandable = v:false
      if get(l:item, 'insertTextFormat', 1) == 2
        let l:word = l:item.label
        let l:is_expandable = v:true
      elseif has_key(l:item, 'textEdit')
        let l:word = l:item.label
      endif

      let s:context.id += 1
      let l:vim_item = {}
      let l:vim_item.word = l:word
      let l:vim_item.kind = lamp#protocol#completion#get_kind_name(l:item.kind) . ' ' . substitute(get(l:item, 'detail', ''), '\%(\r\n\|\r\|\n\)', ' ', 'g')
      let l:vim_item.abbr = l:is_expandable ? l:word . '~' : l:word
      let l:vim_item.menu = '[LAMP]'
      let l:vim_item.user_data = json_encode({
            \   'lamp': {
            \     'id': s:context.id,
            \     'server_name': l:server_name,
            \     'completion_item': l:item
            \   }
            \ })
      call add(l:returns.words, l:vim_item)
    endfor
  endfor

  return l:returns
endfunction

