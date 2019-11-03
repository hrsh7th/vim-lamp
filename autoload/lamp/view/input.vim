function! lamp#view#input#select(message, candidates) abort
  redraw
  let l:candidates = [a:message]
  let l:candidates += map(copy(a:candidates), { k, v -> printf('  %s. %s', k + 1, v) })
  let l:index = inputlist(l:candidates)
  if l:index < 1
    return -1
  endif
  return l:index - 1
endfunction

