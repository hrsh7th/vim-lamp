let s:Buffer = vital#lamp#import('VS.Vim.Buffer')

"
" lamp#view#buffer#append_line
"
function! lamp#view#buffer#append_line(bufnr, start, line) abort
  if has('nvim')
    call nvim_buf_set_lines(a:bufnr, a:start, a:start, v:false, [a:line])
  else
    call appendbufline(a:bufnr, a:start, a:line)
  endif
endfunction

"
" lamp#view#buffer#get_lines
"
function! lamp#view#buffer#get_lines(bufnr) abort
  let l:lines = getbufline(a:bufnr, '^', '$')
  if &fixendofline && !&binary
    call add(l:lines, '')
  endif
  return l:lines
endfunction

"
" lamp#view#buffer#open
"
function! lamp#view#buffer#open(command, location) abort
  normal! m'
  let l:bufnr = s:Buffer.ensure(a:location.filename)
  if l:bufnr != bufnr('%') || a:command !=# 'edit'
    execute printf('keepalt keepjumps %s %s', a:command, a:location.filename)
  endif

  let l:lnum = get(a:location, 'lnum', 1)
  let l:col = get(a:location, 'col', 1)
  execute printf('keepalt keepjumps normal! %sG%s|zz', l:lnum, l:col)
endfunction

"
" lamp#view#buffer#do
"
function! lamp#view#buffer#do(bufnr, fn) abort
  let l:current_bufnr = bufnr('%')
  if l:current_bufnr == a:bufnr
    call a:fn()
    return
  endif

  try
    execute printf('keepalt keepjumps %sbufdo! call a:fn()', a:bufnr)
  catch /.*/
    echomsg string({ 'e': v:exception, 't': v:throwpoint })
  endtry
  execute printf('noautocmd keepalt keepjumps %sbuffer', l:current_bufnr)
endfunction

"
" lamp#view#buffer#get_indent_size
"
function! lamp#view#buffer#get_indent_size() abort
  if &shiftwidth
    return &shiftwidth
  endif
  return &tabstop
endfunction

"
" lamp#view#buffer#reset
"
function! lamp#view#buffer#reset() abort
  set hidden
  enew!

  let l:bufnr = bufnr('$')
  while l:bufnr >= 0
    if bufloaded(l:bufnr) && l:bufnr != bufnr('%')
      call lamp#view#buffer#do(l:bufnr, { -> execute('bdelete!') })
    endif
    let l:bufnr -= 1
  endwhile
endfunction

