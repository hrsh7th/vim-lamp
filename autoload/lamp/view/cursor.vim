function! lamp#view#cursor#get_before_char_skip_white() abort
  let l:current_lnum = line('.')

  let l:lnum = l:current_lnum
  while l:lnum > 0
    let l:text = getline(l:lnum)
    if l:lnum == l:current_lnum
      let l:text = lamp#view#cursor#get_before_line()
    endif
    let l:match = matchlist(l:text, '\([^[:blank:]]\)\s*$')
    if get(l:match, 1, v:null) isnot v:null
      return l:match[1]
    endif
    let l:lnum -= 1
  endwhile

  return ''
endfunction

function! lamp#view#cursor#get_before_line() abort
  let l:text = getline('.')
  return l:text[0 : min([strlen(l:text), col('.') - 2])]
endfunction

