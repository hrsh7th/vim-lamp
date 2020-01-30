let s:Promise = vital#lamp#import('Async.Promise')
let s:Server = lamp#server#import()

let s:debounce_ids = {}

let s:profiles = {}

let s:state = {
      \   'exiting': v:false,
      \ }

let s:config = {
      \   'global.root': expand('<sfile>:p:h:h'),
      \   'global.debug': v:null,
      \   'global.timeout': 3000,
      \   'feature.completion.snippet.expand': v:null,
      \   'feature.completion.floating_docs': v:true,
      \   'feature.diagnostic.delay.insert': 800,
      \   'feature.diagnostic.delay.normal': 200,
      \   'view.location.on_location': { locations -> [
      \     setqflist(locations, 'r'),
      \     execute('copen')
      \   ] },
      \   'view.location.on_fallback': { command, position -> [
      \     lamp#view#notice({ 'lines': ['`Location`: no locations found.'] })
      \   ] },
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
" lamp#profile
"
function! lamp#profile(name, ...) abort
  if !has_key(s:profiles, a:name)
    let s:profiles[a:name] = {
          \   'count': 0,
          \   'start': reltime(),
          \   'end': -1,
          \ }
  endif

  if get(a:000, 0, v:false)
    let s:profiles[a:name].end = reltimefloat(reltime(s:profiles[a:name].start)) * 1000
  else
    let s:profiles[a:name].count += 1
    let s:profiles[a:name].start = reltime()
  endif
endfunction

"
" lamp#profile_finish
"
function! lamp#profile_finish() abort
  for [l:name, l:profile] in items(s:profiles)
    echomsg string({
          \   'name': l:name,
          \   'count': l:profile.count,
          \   'time': l:profile.end
          \ })
  endfor
  let s:profiles = {}
endfunction

"
" lamp#register
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
" lamp#log
"
function! lamp#log(...) abort
  if exists('$LAMP_TEST')
    call lamp#config('global.debug', '/tmp/lamp.log')
  endif
  if !empty(lamp#config('global.debug'))
    call writefile([join([strftime('%H:%M:%S')] + a:000, "\t")], lamp#config('global.debug'), 'a')
  endif
endfunction

"
" lamp#state
"
function! lamp#state(key, ...) abort
  if len(a:000) > 0
    let s:state[a:key] = a:000[0]
  endif
  return s:state[a:key]
endfunction

"
" lamp#config
"
function! lamp#config(key, ...) abort
  if len(a:000) > 0
    let s:config[a:key] = a:000[0]
  endif
  return s:config[a:key]
endfunction

"
" lamp#debounce
"
function! lamp#debounce(id, fn, timeout) abort
  if has_key(s:debounce_ids, a:id)
    call timer_stop(s:debounce_ids[a:id])
  endif

  let l:ctx = {}
  let l:ctx.fn = a:fn
  function! l:ctx.callback() abort
    try
      call self.fn()
    catch /.*/
      call lamp#log('[ERROR]', { 'exception': v:exception, 'throwpoint': v:throwpoint })
    endtry
  endfunction
  let s:debounce_ids[a:id] = timer_start(a:timeout, { -> l:ctx.callback() })
endfunction

"
" rescue.
"
function! lamp#rescue(...) abort
  if !exists('$LAMP_TEST')
    let l:ctx = {}
    let l:ctx.default = get(a:000, 0, v:null)
    function! l:ctx.catch(err) abort
      call lamp#log('[RESCUE]', a:err)
      return self.default
    endfunction
    return { err -> l:ctx.catch(err) }
  else
    return { err -> execute('throw err') }
  endif
endfunction

"
" lamp#sync
"
function! lamp#sync(promise_or_fn, ...) abort
  let l:timeout = get(a:000, 0, lamp#config('global.timeout'))
  let l:reltime = reltime()

  if type(a:promise_or_fn) == type({ -> {} })
    while v:true
      if  a:promise_or_fn()
        return
      endif

      if l:timeout != -1 && reltimefloat(reltime(l:reltime)) * 1000 > l:timeout
        throw 'lamp#sync: timeout'
      endif
      sleep 1m
    endwhile
  elseif type(a:promise_or_fn) == type({}) && has_key(a:promise_or_fn, '_vital_promise')
    while v:true
      if a:promise_or_fn._state == 1
        return a:promise_or_fn._result
      elseif a:promise_or_fn._state == 2
        throw json_encode(a:promise_or_fn._result)
      endif

      if l:timeout != -1 && reltimefloat(reltime(l:reltime)) * 1000 > l:timeout
        throw 'lamp#sync: timeout'
      endif

      sleep 1m
    endwhile
  endif
endfunction

"
" lamp#get
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
" lamp#findup
"
function! lamp#findup(...) abort
  for l:marker in a:000
    let l:path = fnamemodify(bufname('%'), ':p')
    while index(['', '/'], l:path) == -1
      let l:candidate = l:path . '/' . l:marker
      if isdirectory(l:candidate) || filereadable(l:candidate)
        return l:path
      endif
      let l:path = substitute(l:path, '/[^/]*$', '', 'g')
    endwhile
  endfor
  return fnamemodify(bufname('%'), ':p:h')
endfunction

"
" lamp#merge
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
" lamp#complete
"
function! lamp#complete(find_start, base) abort
  if a:find_start == 1
    let l:before_line = lamp#view#cursor#get_before_line()
    return strlen(substitute(l:before_line, s:get_keyword_pattern() . '$', '', 'g'))
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
    try
      for l:completed_item in lamp#feature#completion#convert(l:server_name, lamp#sync(l:request))
        if l:completed_item._filter_text !~ '^' . a:base && strlen(a:base) >= 1
          continue
        endif
        call add(l:returns.words, l:completed_item)
      endfor
    catch /.*/
      echomsg 'lamp#complete: request timeout.'
    endtry
  endfor
  return l:returns
endfunction

"
" get_keyword_pattern
"
function! s:get_keyword_pattern() abort
  let l:keywords = split(&iskeyword, ',')
  let l:keywords = filter(l:keywords, { _, k -> match(k, '\d\+-\d\+') == -1 })
  let l:keywords = filter(l:keywords, { _, k -> k !=# '@' })
  let l:pattern = '\%(' . join(map(l:keywords, { _, v -> '\V' . escape(v, '\') . '\m' }), '\|') . '\|\w\)*'
  return l:pattern
endfunction

