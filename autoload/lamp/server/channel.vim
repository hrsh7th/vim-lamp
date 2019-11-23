let s:Promise = vital#lamp#import('Async.Promise')
let s:Job = lamp#server#channel#job#import()

let s:Channel = {}

function! lamp#server#channel#import() abort
  return s:Channel
endfunction

"
" new.
"
function! s:Channel.new(option) abort
  return extend(deepcopy(s:Channel), {
        \   'command': a:option.command,
        \   'on_notification': { -> {} },
        \   'job': v:null,
        \   'buffer': '',
        \   'request_id': 0,
        \   'requests': {},
        \ })
endfunction

"
" Start process.
"
function! s:Channel.start(on_notification) abort
  let self.job = s:Job.new(self.command, {
        \   'on_stdout': function(s:Channel.on_stdout, [], self),
        \   'on_stderr': function(s:Channel.on_stderr, [], self),
        \   'on_exit': function(s:Channel.on_exit, [], self),
        \ })
  let self.on_notification = a:on_notification
endfunction

"
" Stop process.
"
function! s:Channel.stop() abort
  if !empty(self.job)
    call self.job.stop()
  endif
endfunction

"
" Get process status.
"
function! s:Channel.is_running() abort
  if !empty(self.job)
    return self.job.is_running()
  endif
  return v:false
endfunction

"
" Send request.
"
function! s:Channel.request(method, ...) abort
  let l:message = { 'method': a:method }
  if len(a:000) > 0
    let l:message = extend(l:message, { 'params': a:000[0] })
  endif

  let self.request_id = self.request_id + 1

  let l:fn = {}
  function! l:fn.executor(message, resolve, reject) abort dict
    call lamp#log(' -> [REQUEST]', self.request_id, a:message)
    let self.requests[self.request_id] = {
          \   'resolve': a:resolve,
          \   'reject': a:reject
          \ }
    call self.job.send(self.to_message(extend({ 'id': self.request_id }, a:message)))
  endfunction

  return s:Promise.new(function(l:fn.executor, [l:message], self))
endfunction

"
" Send response.
"
function! s:Channel.response(id, ...) abort
  let l:message = { 'id': a:id }
  if len(a:000) > 0
    let l:message = extend(l:message, a:000[0])
  endif

  call lamp#log(' -> [RESPONSE]', l:message)
  call self.job.send(self.to_message(l:message))
endfunction

"
" Send notify.
"
function! s:Channel.notify(method, ...) abort
  let l:message = { 'method': a:method }
  if len(a:000) > 0
    let l:message = extend(l:message, { 'params': a:000[0] })
  endif

  call lamp#log(' -> [NOTIFY]', l:message)
  call self.job.send(self.to_message(l:message))
endfunction

"
" Convert to message.
"
function! s:Channel.to_message(content) abort
  let l:content = json_encode(extend({ 'jsonrpc': '2.0' }, a:content))
  return 'Content-Length: ' . strlen(l:content) . "\r\n\r\n" . l:content
endfunction

"
" on message.
"
function! s:Channel.on_message(message) abort
  if has_key(a:message, 'id')
    " Response.
    if has_key(self.requests, a:message.id)
      call lamp#log(' <- [RESPONSE]', a:message.id, a:message)
      if has_key(a:message, 'error')
        call self.requests[a:message.id].reject(a:message.error)
      else
        call self.requests[a:message.id].resolve(get(a:message, 'result', v:null))
      endif
      call remove(self.requests, a:message.id)

    " Request.
    else
      call lamp#log(' <- [REQUEST]', a:message)
      call self.on_notification(a:message)
    endif
    return
  endif

  " Notification.
  if has_key(a:message, 'method')
    call lamp#log(' <- [NOTIFY]', a:message)
    call self.on_notification(a:message)
  endif
endfunction

"
" on_stdout.
"
function! s:Channel.on_stdout(data) abort
  let self.buffer .= a:data

  " header check.
  let l:header_length = stridx(self.buffer, "\r\n\r\n") + 4
  if l:header_length < 4
    return
  endif

  " content length check.
  let l:content_length = get(matchlist(self.buffer[0 : l:header_length - 1], 'Content-Length: \(\d\+\)'), 1, v:null)
  if l:content_length is v:null
    return
  endif
  let l:end_of_content = l:header_length + l:content_length

  " content check.
  if strlen(self.buffer) < l:end_of_content
    return
  endif

  " try content.
  try
    let l:content = self.buffer[l:header_length : l:end_of_content - 1]
    let l:message = json_decode(l:content)
    let self.buffer = self.buffer[l:end_of_content : ]

    call self.on_message(l:message)

    if strlen(self.buffer) > 0
      call self.on_stdout('')
    endif
  catch /.*/
    echoerr string([v:exception, v:throwpoint])
  endtry
endfunction

"
" on_stderr
"
function! s:Channel.on_stderr(data) abort
  if strlen(a:data)
    echomsg string(['on_stderr', a:data])
  endif
endfunction

"
" on_exit
"
function! s:Channel.on_exit(code) abort
  " TODO: impl
endfunction

