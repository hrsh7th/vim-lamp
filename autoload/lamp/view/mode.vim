let s:insert_leave_timer_id = -1

"
" lamp#view#mode#insert_leave
"
function! lamp#view#mode#insert_leave(fn) abort
  call timer_stop(s:insert_leave_timer_id)

  let l:ctx = {}
  let l:ctx.fn = a:fn
  function! l:ctx.callback(timer_id) abort
    if index(['i', 's'], mode()[0]) >= 0
      return
    endif
    call self.fn()
    call timer_start(0, { -> timer_stop(a:timer_id) })
  endfunction
  let s:insert_leave_timer_id = timer_start(200, { timer_id -> l:ctx.callback(timer_id) }, { 'repeat': -1 })
endfunction
