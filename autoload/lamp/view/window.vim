"
" lamp#view#window#do
"
function! lamp#view#window#do(winid, fn) abort
  if !empty(getcmdwintype())
    return
  endif

  let l:current_winid = win_getid()
  if l:current_winid == a:winid
    call a:fn()
    return
  endif

  if exists('*win_execute')
    let s:Do = a:fn
    try
      noautocmd keepalt keepjumps call win_execute(a:winid, 'noautocmd keepalt keepjumps call s:Do()')
    catch /.*/
      echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
    endtry
    unlet s:Do
    return
  endif

  noautocmd keepalt keepjumps call win_gotoid(a:winid)
  try
    call a:fn()
  catch /.*/
    echomsg string({ 'e': v:exception, 't': v:throwpoint })
  endtry
  noautocmd keepalt keepjumps call win_gotoid(l:current_winid)
endfunction

"
" lamp#view#window#find_floating_winids
"
function! lamp#view#window#find_floating_winids() abort
  
endfunction

