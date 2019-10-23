let s:notices = []

function! lamp#view#notice#add(notice) abort
  call add(s:notices, a:notice)
endfunction

