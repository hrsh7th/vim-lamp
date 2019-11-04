let s:Promise = vital#lamp#import('Async.Promise')
let s:Server = lamp#server#import()

let s:debounce_ids = {}

let s:on_locations = { locations -> [setqflist(locations, 'r'), execute('copen')] }
let s:config = {
      \   'root': expand('<sfile>:p:h:h'),
      \   'debug.log': v:null,
      \   'feature.definition.on_definitions': s:on_locations,
      \   'feature.references.on_references': s:on_locations,
      \   'feature.rename.on_renamed': s:on_locations,
      \   'view.sign.error.text': 'x',
      \   'view.sign.warning.text': '!',
      \   'view.sign.information.text': 'i',
      \   'view.sign.hint.text': '?',
      \   'view.floatwin.fenced_language': {
      \     'help': ['help'],
      \     'vim': ['vim'],
      \     'typescript': ['ts', 'tsx', 'typescript', 'typescriptreact', 'typescript.tsx'],
      \     'javascript': ['js', 'jsx', 'javascript', 'javascriptreact', 'javascript.jsx']
      \   }
      \ }

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
  if strlen(lamp#config('debug.log')) > 0
    call writefile([strcharpart(join(a:000, "\t"), 0, 512)], lamp#config('debug.log'), 'a')
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
    function! s:catch(err, default) abort
      call lamp#log('[RESCUE]', a:default, '<-', a:err)
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
" complete.
"
function! lamp#complete(find_start, base) abort
  if a:find_start == 1
    let l:before_text = getline('.')[0 : col('.') - 1]
    return strlen(substitute(l:before_text, '\k*$', '', 'g'))
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
          \   'position': lamp#protocol#position#get()
          \ }).catch(lamp#rescue([]))
  endfor

  " consume response.
  let l:returns = { 'words': [], 'refresh': 'always' }

  for [l:server_name, l:request] in items(s:context.requests)
    let l:response = lamp#sync(l:request)

    let l:items = type(l:response) == type({}) ? l:response.items : l:response
    for l:item in l:items
      let l:filter_text = get(l:item, 'filterText', get(l:item, 'insertText', l:item.label))
      if l:filter_text !~ '^' . a:base
        continue
      endif

      let s:context.id += 1
      let l:vim_item = {}
      let l:vim_item.word = get(l:item, 'insertText', l:item.label)
      let l:vim_item.kind = lamp#protocol#completion#get_kind_name(l:item.kind)
      let l:vim_item.abbr = l:item.label
      let l:vim_item.menu = '[LAMP]'
      let l:vim_item.info = get(l:item, 'detail', '') . get(l:item, 'documentation', '')
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

