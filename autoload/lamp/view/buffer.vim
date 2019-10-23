"
" lamp#view#buffer#open
"
function! lamp#view#buffer#open(command, location) abort
  let l:bufnr = bufnr(a:location.filename, v:true)
  call bufload(l:bufnr)
  call setbufvar(l:bufnr, '&buflisted', v:true)

  execute printf('%s %s', a:command, a:location.filename)

  if has_key(a:location, 'lnum')
    call cursor([a:location.lnum, get(a:location, 'col', 1)])
  endif
endfunction

"
" force fire `TextChanged`
"
function! lamp#view#buffer#touch(expr) abort
  let l:bufnr = bufnr(a:expr, v:true)
  if !bufexists(l:bufnr)
    return
  endif

  let l:current_bufnr = bufnr('%')
  execute printf('keepalt keepjumps %sbufdo! undojoin | normal! i_', l:bufnr)
  execute printf('keepalt keepjumps %sbufdo! undojoin | normal! "_x', l:bufnr)
  execute printf('keepalt keepjumps %sbuffer', l:current_bufnr)
endfunction

