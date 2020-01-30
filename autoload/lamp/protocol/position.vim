"
" lamp#protocol#position#get
"
function! lamp#protocol#position#get() abort
  return lamp#protocol#position#vim_to_lsp('%', getpos('.')[1 : 3])
endfunction

"
" lamp#protocol#position#in_range
"
function! lamp#protocol#position#in_range(position, range) abort
  return lamp#protocol#position#after(a:range.start, a:position) &&
        \ lamp#protocol#position#after(a:position, a:range.end)
endfunction

"
" lamp#protocol#position#to_vim
"
function! lamp#protocol#position#to_vim(position) abort
  return {
        \   'line': a:position.line + 1,
        \   'character': a:position.character + 1
        \ }
endfunction

"
" lamp#protocol#position#after
"
function! lamp#protocol#position#after(position1, position2) abort
  return a:position1.line <= a:position2.line && a:position1.character <= a:position2.character
endfunction

"
" lamp#protocol#position#vim_to_lsp
"
function! lamp#protocol#position#vim_to_lsp(expr, pos) abort
  let l:bufnr = bufnr(a:expr)
  if bufloaded(l:bufnr)
    let l:line = getbufline(l:bufnr, a:pos[0])[0]
  elseif filereadable(bufname(a:expr))
    let l:line = readfile(bufname(a:expr), '', a:pos[0])[-1]
  else
    return {
    \   'line': a:pos[0] - 1,
    \   'character': a:pos[1] + a:pos[2] - 1
    \ }
  endif

  let l:lnum = a:pos[0]
  let l:col = a:pos[1] + get(a:pos, 2, 0)
  return {
  \   'line': a:pos[0] - 1,
  \   'character': strchars(strpart(l:line, 0, l:col - 1))
  \ }
endfunction

"
" lamp#protocol#position#lsp_to_vim
"
function! lamp#protocol#position#lsp_to_vim(expr, position) abort
  if bufloaded(bufnr(a:expr))
    let l:line = getbufline(a:expr, a:position.line + 1)[0]
  elseif filereadable(bufname(a:expr))
    let l:line = readfile(bufname(a:expr), '', a:position.line + 1)[-1]
  else
    return [a:position.line + 1, a:position.character + 1]
  endif

  return [
  \   a:position.line + 1,
  \   strlen(strcharpart(l:line, 0, a:position.character)) + 1
  \ ]
endfunction

