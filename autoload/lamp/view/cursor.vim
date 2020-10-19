"
" lamp#view#cursor#get_before_char_skip_white
"
function! lamp#view#cursor#get_before_char_skip_white() abort
  let l:current_lnum = line('.')

  let l:lnum = l:current_lnum
  while l:lnum > 0
    if l:lnum == l:current_lnum
      let l:text = lamp#view#cursor#get_before_line()
    else
      let l:text = getline(l:lnum)
    endif
    let l:match = matchlist(l:text, '\([^[:blank:]]\)\s*$')
    if get(l:match, 1, v:null) isnot v:null
      return l:match[1]
    endif
    let l:lnum -= 1
  endwhile

  return ''
endfunction

"
" lamp#view#cursor#get_before_line
"
function! lamp#view#cursor#get_before_line() abort
  if mode()[0] ==# 'i'
    let l:col = col('.') - 2
  elseif mode()[0] ==# 's'
    let l:col = col('v') - 2
  endif
  let l:text = getline('.')
  return l:text[0 : min([strlen(l:text), l:col])]
endfunction

"
" lamp#view#cursor#get_before_char
"
function! lamp#view#cursor#get_before_char() abort
  let l:before_line = lamp#view#cursor#get_before_line()
  if strlen(l:before_line) > 0
    return l:before_line[-1:-1]
  endif
  return ''
endfunction

"
" lamp#view#cursor#search_before_char_pos
"
function! lamp#view#cursor#search_before_char(chars, ...) abort
  let l:search_lines = get(a:000, 0, 1)
  let l:current_lnum = line('.')

  let l:i = 0
  while l:i < l:search_lines
    let l:lnum = l:current_lnum - l:i
    " invalid lnum.
    if l:lnum < 1
      return ['', -1, -1]
    endif

    if l:lnum == l:current_lnum
      let l:text = lamp#view#cursor#get_before_line()
    else
      let l:text = getline(l:lnum)
    endif

    let l:j = strchars(l:text)
    while  l:j >= 0
      let l:charnr = strgetchar(l:text, l:j - 1)
      if l:charnr != -1
        let l:char = nr2char(l:charnr)
        if index(a:chars, l:char) >= 0
          return [l:char, l:lnum, l:j + 1]
        endif
      endif
      let l:j -= 1
    endwhile
    let l:i += 1
  endwhile

  return ['', -1, -1]
endfunction

