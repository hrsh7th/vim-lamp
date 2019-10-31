"
" job api compat layer.
"
function! lamp#server#channel#job#import() abort
  return s:Job
endfunction

let s:Job = {}

"
" new.
"
function! s:Job.new(command, option) abort
  let l:job = has('nvim') ? s:neovim(a:command, a:option) : s:vim(a:command, a:option)
  return extend(deepcopy(s:Job), {
        \   'job': l:job,
        \   'timer_id': 0,
        \   'buffer': '',
        \ })
endfunction

"
" send
"
function! s:Job.send(data) abort
  let self.buffer .= a:data
  call timer_stop(self.timer_id)
  let self.timer_id = timer_start(0, { timer_id -> self.consume() }, { 'repeat': -1 })
endfunction

"
" consume
"
function! s:Job.consume() abort
  if !self.is_running() || self.buffer ==# ''
    call timer_stop(self.timer_id)
    return
  endif

  let l:data = strpart(self.buffer, 0, 1024)
  call self.job.send(l:data)
  let self.buffer = strpart(self.buffer, 1024, strlen(self.buffer))
endfunction

"
" stop
"
function! s:Job.stop() abort
  call self.job.stop()
endfunction

"
" is_running
"
function! s:Job.is_running() abort
  return self.job.is_running()
endfunction

"---------

"
" neovim's jobstart api.
"
function! s:neovim(command, option) abort
  function! s:on_stdout(option, id, data, name) abort
    if has_key(a:option, 'on_stdout')
      call a:option.on_stdout(join(a:data, "\n"))
    endif
  endfunction

  function! s:on_stderr(option, id, data, name) abort
    if has_key(a:option, 'on_stderr')
      call a:option.on_stderr(join(a:data, "\n"))
    endif
  endfunction

  function! s:on_exit(option, id, code, event_type) abort
    if has_key(a:option, 'on_exit')
      call a:option.on_exit(a:code)
    endif
  endfunction

  function! s:send(job, data) abort
    call jobsend(a:job, a:data)
  endfunction

  function! s:stop(job) abort
    call jobstop(a:job)
  endfunction

  function! s:is_running(job) abort
    return jobwait([a:job], 0)[0] == -1
  endfunction

  let l:job = jobstart(a:command, {
        \   'on_stdout': function('s:on_stdout', [a:option], {}),
        \   'on_stderr': function('s:on_stderr', [a:option], {}),
        \   'on_exit':   function('s:on_exit', [a:option], {}),
        \   'detach': v:true
        \ })
  return {
        \ 'send': function('s:send', [l:job], {}),
        \ 'stop': function('s:stop', [l:job], {}),
        \ 'is_running': function('s:is_running', [l:job], {})
        \ }
endfunction

"
" vim's job_start api.
"
function! s:vim(command, option) abort
  function! s:on_stdout(option, job, data) abort
    if has_key(a:option, 'on_stdout')
      call a:option.on_stdout(a:data)
    endif
  endfunction

  function! s:on_stderr(option, job, data) abort
    if has_key(a:option, 'on_stderr')
      call a:option.on_stderr(a:data)
    endif
  endfunction

  function! s:on_exit(option, job, code) abort
    if has_key(a:option, 'on_exit')
      call a:option.on_exit(a:code)
    endif
  endfunction

  function! s:send(job, data) abort
    call ch_sendraw(a:job, a:data)
  endfunction

  function! s:stop(job) abort
    call ch_close(a:job)
  endfunction

  function! s:is_running(job) abort
    return ch_status(a:job) ==# 'open'
  endfunction

  let l:job = job_start(a:command, {
        \   'noblock': v:true,
        \   'in_io': 'pipe',
        \   'in_mode': 'raw',
        \   'out_io': 'pipe',
        \   'out_mode': 'raw',
        \   'err_io': 'pipe',
        \   'err_mode': 'raw',
        \   'out_cb': function('s:on_stdout', [a:option], {}),
        \   'err_cb': function('s:on_stderr', [a:option], {}),
        \   'exit_cb': function('s:on_exit', [a:option], {})
        \ })
  return {
        \ 'send': function('s:send', [l:job], {}),
        \ 'stop': function('s:stop', [l:job], {}),
        \ 'is_running': function('s:is_running', [l:job], {})
        \ }
endfunction

