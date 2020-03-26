let s:Promise = vital#lamp#import('Async.Promise')
let s:Job = lamp#server#channel#job#import()

let s:log_name_len = 12

"
" lamp#server#channel#import
"
function! lamp#server#channel#import() abort
  return s:Channel
endfunction

let s:Channel = {}

"
" new
"
function! s:Channel.new(option) abort
  return extend(deepcopy(s:Channel), {
  \   'name': a:option.name,
  \   'command': a:option.command,
  \   'on_notification': { -> {} },
  \   'job': v:null,
  \   'buffer': '',
  \   'request_id': 0,
  \   'requests': {},
  \ })
endfunction

"
" start
"
function! s:Channel.start(on_notification, opts) abort
  let self.job = s:Job.new(self.command, extend(a:opts, {
  \   'on_stdout': function(s:Channel.on_stdout, [], self),
  \   'on_stderr': function(s:Channel.on_stderr, [], self),
  \   'on_exit': function(s:Channel.on_exit, [], self),
  \ }))
  let self.on_notification = a:on_notification
endfunction

"
" stop
"
function! s:Channel.stop() abort
  if !empty(self.job)
    call self.job.stop()
  endif
endfunction

"
" is_running
"
function! s:Channel.is_running() abort
  if !empty(self.job)
    return self.job.is_running()
  endif
  return v:false
endfunction

"
" request
"
function! s:Channel.request(method, params, ...) abort
  let l:option = get(a:000, 0, {})

  let l:message = { 'method': a:method }
  if a:params isnot# v:null
    let l:message = extend(l:message, { 'params': a:params })
  endif

  let l:request_id = self.request_id + 1
  let self.request_id = l:request_id

  " attach cancellation token.
  if has_key(l:option, 'cancellation_token')
    call l:option.cancellation_token.attach({ -> self.cancel(l:request_id) })
  endif

  " initialize request.
  let l:ctx = {}
  function! l:ctx.executor(message, resolve, reject) abort dict
    let self.requests[self.request_id] = {
          \   'resolve': a:resolve,
          \   'reject': a:reject,
          \ }
    call self.job.send(self.to_message(extend({ 'id': self.request_id }, a:message)))
    call self.log('-> [REQUEST]', self.request_id, a:message)
  endfunction
  return s:Promise.new(function(l:ctx.executor, [l:message], self))
endfunction

"
" response
"
function! s:Channel.response(id, ...) abort
  let l:message = { 'id': a:id }
  if len(a:000) > 0
    let l:message = extend(l:message, a:000[0])
  endif

  call self.log('-> [RESPONSE]', l:message)
  call self.job.send(self.to_message(l:message))
endfunction

"
" notify
"
function! s:Channel.notify(method, ...) abort
  let l:message = { 'method': a:method }
  if len(a:000) > 0
    let l:message = extend(l:message, { 'params': a:000[0] })
  endif

  call self.log('-> [NOTIFY]', l:message)
  call self.job.send(self.to_message(l:message))
endfunction

"
" cancel
"
function! s:Channel.cancel(id) abort
  if has_key(self.requests, a:id)
    call self.notify('$/cancelRequest', {
    \   'id': a:id
    \ })
    call remove(self.requests, a:id)
  endif
endfunction

"
" to_message
"
function! s:Channel.to_message(content) abort
  let l:content = json_encode(extend({ 'jsonrpc': '2.0' }, a:content))
  return 'Content-Length: ' . strlen(l:content) . "\r\n\r\n" . l:content
endfunction

"
" on_message
"
function! s:Channel.on_message(message) abort
  " Request or Response.
  if has_key(a:message, 'id')
    " Request.
    if has_key(a:message, 'method')
      call self.log('<- [REQUEST]', a:message)
      call self.on_notification(a:message)

    " Response.
    elseif has_key(a:message, 'id')
      if has_key(self.requests, a:message.id)
        call self.log('<- [RESPONSE]', a:message.id, a:message)
        let l:request = remove(self.requests, a:message.id)
        if has_key(a:message, 'error')
          call l:request.reject(a:message.error)
        else
          call l:request.resolve(get(a:message, 'result', v:null))
        endif
      else
        call self.log('<- [RESPONSE IGNORE]', a:message.id, 'canceled or unknown response.')
      endif
    endif

  " Notification.
  elseif has_key(a:message, 'method')
    call self.log('<- [NOTIFY]', a:message)
    call self.on_notification(a:message)
  endif
endfunction

"
" on_stdout
"
function! s:Channel.on_stdout(data) abort
  let self.buffer .= a:data

  while 1
    " header check.
    let l:header_length = stridx(self.buffer, "\r\n\r\n") + 4
    if l:header_length < 4
      return
    endif

    " content length check.
    let l:content_length = get(matchlist(self.buffer, 'Content-Length:\s*\(\d\+\)', 0, 1), 1, v:null)
    if l:content_length is v:null
      return
    endif
    let l:message_length = l:header_length + l:content_length

    " content check.
    let l:buffer_len = strlen(self.buffer)
    if l:buffer_len < l:message_length
      return
    endif

    " try content.
    try
      let l:content = strpart(self.buffer, l:header_length, l:message_length - l:header_length)
      let l:message = json_decode(l:content)
      let self.buffer = strpart(self.buffer, l:message_length, strlen(self.buffer) - l:message_length)
      call self.on_message(l:message)
    catch /.*/
      call self.log('[JSON-PARSE-ERROR]', a:data)
    endtry
  endwhile
endfunction

"
"
" on_stderr
"
function! s:Channel.on_stderr(data) abort
  if strlen(a:data)
    call self.log('[STDERR]', a:data)
  endif
endfunction

"
" on_exit
"
function! s:Channel.on_exit(code) abort
  " TODO: impl
endfunction

"
" log
"
function! s:Channel.log(...) abort
  if strlen(lamp#config('global.debug')) > 0
    let l:name = strcharpart(self.name, 0, s:log_name_len)
    let l:name = l:name . repeat(' ', s:log_name_len - strlen(l:name))
    call call('lamp#log', [l:name] + a:000)
  endif
endfunction

