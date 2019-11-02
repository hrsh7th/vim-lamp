function! lamp#protocol#range#in_line(range, position) abort
  return a:range.start.line <= a:position.line && a:position.line <= a:range.end.line
endfunction

function! lamp#protocol#range#current_word() abort
  let l:line = line('.')
  let l:col = col('.')
  let l:text = getline(l:line)
  let l:match = matchstrpos(strpart(l:text, 0, l:col), '\k*$')
  if l:match[1] == -1
    return {}
  endif

  let l:match = matchstrpos(l:text, '\k*', l:match[1])
  if l:match[1] == -1
    return {}
  endif

  return {
        \   'start': {
        \     'line': l:line - 1,
        \     'character': l:match[1]
        \   },
        \   'end': {
        \     'line': l:line - 1,
        \     'character': l:match[2]
        \   }
        \ }
endfunction

function! lamp#protocol#range#has_length(range) abort
  return a:range.start.line < a:range.end.line || (
        \   a:range.start.line == a:range.end.line &&
        \   a:range.start.character < a:range.end.character
        \ )
endfunction

function! lamp#protocol#range#to_vim(range) abort
  return {
        \   'start': {
        \     'line': a:range.start.line + 1,
        \     'character': a:range.start.character + 1
        \   },
        \   'end': {
        \     'line': a:range.end.line + 1,
        \     'character': a:range.end.character + 1
        \   }
        \ }
endfunction
