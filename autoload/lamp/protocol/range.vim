"
" lamp#protocol#range#in_line
"
function! lamp#protocol#range#in_line(range) abort
  let l:position = lamp#protocol#position#get()
  return a:range.start.line <= l:position.line && l:position.line <= a:range.end.line
endfunction

"
" lamp#protocol#range#merge_expand
"
function! lamp#protocol#range#merge_expand(range1, range2) abort
  let l:start_line = min([a:range1.start.line, a:range2.start.line])
  let l:start_character = min([a:range1.start.character, a:range2.start.character])
  let l:end_line = max([a:range1.end.line, a:range2.end.line])
  let l:end_character = max([a:range1.end.character, a:range2.end.character])
  return {
        \   'start': {
        \     'line': l:start_line,
        \     'character': l:start_character,
        \   },
        \   'end': {
        \     'line': l:end_line,
        \     'character': l:end_character,
        \   },
        \ }
endfunction

"
" lamp#protocol#range#compare_nearest
"
function! lamp#protocol#range#compare_nearest(range1, range2, position) abort
  let l:start_line_diff1 = abs(a:range1.start.line - a:position.line)
  let l:start_line_diff2 = abs(a:range2.start.line - a:position.line)
  if l:start_line_diff1 < l:start_line_diff2
    return -1
  elseif l:start_line_diff1 > l:start_line_diff2
    return 1
  endif

  let l:end_line_diff1 = abs(a:range1.end.line - a:position.line)
  let l:end_line_diff2 = abs(a:range2.end.line - a:position.line)
  if l:end_line_diff1 < l:end_line_diff2
    return -1
  elseif l:end_line_diff1 > l:end_line_diff2
    return 1
  endif

  let l:start_char_diff1 = abs(a:range1.start.character - a:position.character)
  let l:start_char_diff2 = abs(a:range2.start.character - a:position.character)
  if l:start_char_diff1 < l:start_char_diff2
    return -1
  elseif l:start_char_diff1 > l:start_char_diff2
    return 1
  endif

  let l:end_char_diff1 = abs(a:range1.end.character - a:position.character)
  let l:end_char_diff2 = abs(a:range2.end.character - a:position.character)
  if l:end_char_diff1 < l:end_char_diff2
    return -1
  elseif l:end_char_diff1 > l:end_char_diff2
    return 1
  endif

  return 0
endfunction

"
" lamp#protocol#range#compare_nearest
"
function! lamp#protocol#range#get_current_line() abort
  return {
        \   'start': {
        \     'line': line('.') - 1,
        \     'character': 0,
        \   },
        \   'end': {
        \     'line': line('.'),
        \     'character': 0,
        \   }
        \ }
endfunction

"
" lamp#protocol#range#current_word
"
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

"
" lamp#protocol#range#has_length
"
function! lamp#protocol#range#has_length(range) abort
  return a:range.start.line < a:range.end.line || (
        \   a:range.start.line == a:range.end.line &&
        \   a:range.start.character < a:range.end.character
        \ )
endfunction

"
" lamp#protocol#range#to_vim
"
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
