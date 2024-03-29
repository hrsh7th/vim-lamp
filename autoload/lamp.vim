let s:Promise = vital#lamp#import('Async.Promise')
let s:TextEdit = vital#lamp#import('VS.LSP.TextEdit')
let s:Position = vital#lamp#import('VS.LSP.Position')
let s:Server = lamp#server#import()
let s:CancellationToken = lamp#server#cancellation_token#import()

let s:debounce_ids = {}

let s:profiles = {}

let s:state = {
\   'exiting': v:false,
\ }

let s:config = {
\   'global.root': expand('<sfile>:p:h:h'),
\   'global.debug': v:null,
\   'global.debug.clear_on_start': v:false,
\   'global.timeout': 3000,
\   'feature.completion.snippet.expand': v:null,
\   'feature.completion.floating_docs': v:true,
\   'feature.diagnostic.increase_delay.normal': 200,
\   'feature.diagnostic.increase_delay.insert': 1200,
\   'view.location.on_location': { locations -> [
\     setqflist(locations, 'r'),
\     execute('copen')
\   ] },
\   'view.location.on_fallback': { command, position -> [
\     lamp#view#notice({ 'lines': ['`Location`: no locations found.'] })
\   ] },
\   'view.sign.error.text': '>>',
\   'view.sign.warning.text': '>>',
\   'view.sign.information.text': '>>',
\   'view.sign.hint.text': '>>',
\   'view.floatwin.fenced_languages': {
\     'help': ['help'],
\     'vim': ['vim'],
\     'typescript': ['ts', 'tsx', 'typescript', 'typescriptreact', 'typescript.tsx'],
\     'javascript': ['js', 'jsx', 'javascript', 'javascriptreact', 'javascript.jsx'],
\   }
\ }

function! s:on_unhandled_rejection(err) abort
  if strlen(lamp#config('global.debug')) > 0
    echoerr string(a:err)
    call lamp#log('[ERROR]', a:err)
  endif
endfunction
call s:Promise.on_unhandled_rejection(function('s:on_unhandled_rejection'))

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
" lamp#log_clear
"
function! lamp#log_clear() abort
  if filereadable(lamp#config('global.debug')) && lamp#config('global.debug.clear_on_start')
    call delete(lamp#config('global.debug'))
  endif
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
" lamp#cancellation_token
"
function! lamp#cancellation_token() abort
  return s:CancellationToken.new()
endfunction

"
" lamp#get
"
function! lamp#get(dict, path, default) abort
  let l:keys = split(a:path, '\.')

  let l:V = a:dict
  for l:key in l:keys
    let l:type = type(l:V)
    if !(l:type == v:t_dict && has_key(l:V, l:key))
      return a:default
    endif
    let l:V = l:V[l:key]
  endfor
  return l:V
endfunction

"
" lamp#findup
"
function! lamp#findup(markers, ...) abort
  for l:marker in a:markers
    let l:path = lamp#fnamemodify(get(a:000, 0, bufname('%')), ':p')
    if !filereadable(l:path)
      return ''
    endif
    while v:true
      let l:candidate = l:path . '/' . l:marker
      if isdirectory(l:candidate) || filereadable(l:candidate)
        return substitute(l:path, '[\\/]$', '', 'g')
      endif
      let l:up = lamp#fnamemodify(l:path, ':h')
      if l:up ==# l:path
        break
      endif
      let l:path = l:up
    endwhile
  endfor
  return ''
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
" lamp#fnamemodify
"
function! lamp#fnamemodify(path, modifier) abort
  let l:path = fnamemodify(a:path, a:modifier)
  let l:path = l:path[-1 : -1] ==# '/' ? l:path[0 : -2] : l:path
  return l:path
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
  let s:context.position = s:Position.cursor()

  " send request.
  for l:server in l:servers
    let s:context.requests[l:server.name] = l:server.request('textDocument/completion', {
    \   'textDocument': lamp#protocol#document#identifier(bufnr('%')),
    \   'position': s:context.position,
    \   'context': {
    \     'triggerKind': 1
    \   }
    \ }).catch(lamp#rescue([]))
  endfor

  " consume response.
  let l:returns = { 'words': [], 'refresh': 'always' }
  for [l:server_name, l:request] in items(s:context.requests)
    try
      for l:completed_item in lamp#feature#completion#convert(l:server_name, s:context.position, lamp#sync(l:request))
        if l:completed_item.word !~ '^\V' . join(split(a:base, '\zs'), '\m.\{-}\V') . '\m.*$' && strlen(a:base) >= 1
          continue
        endif
        call add(l:returns.words, l:completed_item)
      endfor
    catch /.*/
      call lamp#log('[ERROR]', v:exception, v:throwpoint)
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

