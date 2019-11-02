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

  try
    execute printf('noautocmd keepalt keepjumps %swindo call a:fn()', win_id2win(a:winid))
  catch /.*/
    echomsg string({ 'e': v:exception, 't': v:throwpoint })
  endtry
  execute printf('noautocmd keepalt keepjumps %swincmd w', win_id2win(l:current_winid))
endfunction

