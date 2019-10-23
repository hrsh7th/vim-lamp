let s:Promise = vital#lamp#import('Async.Promise')
let s:Server = lamp#server#import()

let s:timer_ids = {}

let s:config = {
      \   'root': expand('<sfile>:p:h:h'),
      \   'logfile': '',
      \   'option.on_definitions': { locations -> [
      \     setqflist(locations, 'r'),
      \     execute('copen')
      \   ] },
      \   'option.on_renamed': { locations -> [
      \     setqflist(locations, 'r'),
      \     execute('copen')
      \   ] }
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
  if strlen(lamp#config('logfile')) > 0
    call writefile([strcharpart(join(a:000, "\t"), 0, 512)], lamp#config('logfile'), 'a')
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
  if has_key(s:timer_ids, a:id)
    call timer_stop(s:timer_ids[a:id])
  endif
  let s:timer_ids[a:id] = timer_start(a:timeout, { -> s:debounce(a:fn) }, { 'repeat': 1 })
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
function! lamp#rescue(default) abort
  function! s:catch(err, default) abort
    call lamp#log('[RESQUE]', a:default, '<-', a:err)
    return a:default
  endfunction
  return function('s:catch', [a:default], {})
endfunction

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

