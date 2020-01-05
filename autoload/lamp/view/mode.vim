let s:insert_leave_timer_id = -1
let s:insert_leave_queue = []

"
" lamp#view#mode#insert_leave
"
function! lamp#view#mode#insert_leave(fn) abort
  call timer_stop(s:insert_leave_timer_id)
  call add(s:insert_leave_queue, a:fn)

  let l:ctx = {}
  function! l:ctx.callback(timer_id) abort
    if index(['i', 's'], mode()[0]) >= 0
      return
    endif

    let l:i = 0
    while l:i < len(s:insert_leave_queue)
      call s:insert_leave_queue[l:i]()
      let l:i += 1
    endwhile
    let s:insert_leave_queue = []
    call timer_start(0, { -> timer_stop(a:timer_id) })
  endfunction
  let s:insert_leave_timer_id = timer_start(200, { timer_id -> l:ctx.callback(timer_id) }, { 'repeat': -1 })
endfunction

