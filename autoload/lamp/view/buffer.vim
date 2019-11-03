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

  call lamp#view#buffer#do(l:bufnr, { -> [
        \   execute('undojoin | normal! i_'),
        \   execute('undojoin | normal! "_x"')
        \ ] })
endfunction

"
" safe bufdo.
"
function! lamp#view#buffer#do(bufnr, fn) abort
  let l:current_bufnr = bufnr('%')
  if l:current_bufnr == a:bufnr
    call a:fn()
    return
  endif

  try
    execute printf('noautocmd keepalt keepjumps %sbufdo! call a:fn()', a:bufnr)
  catch /.*/
    echomsg string({ 'e': v:exception, 't': v:throwpoint })
  endtry
  execute printf('noautocmd keepalt keepjumps %sbuffer', l:current_bufnr)
endfunction

"
" get_indent_option
"
function! lamp#view#buffer#get_indent_size() abort
  if &shiftwidth
    return &shiftwidth
  endif
  return &tabstop
endfunction

