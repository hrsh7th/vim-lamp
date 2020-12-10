let s:kind_map = {
      \   '1': '',
      \   '2': '',
      \   '3': '',
      \   '4': '',
      \   '5': '',
      \   '6': '',
      \   '7': '',
      \   '8': '',
      \   '9': '',
      \   '10': '',
      \   '11': '',
      \   '12': '',
      \   '13': '',
      \   '14': '',
      \   '15': '',
      \   '16': '',
      \   '17': '',
      \   '18': '',
      \   '19': '',
      \   '20': '',
      \   '21': '',
      \   '22': '',
      \   '23': '',
      \   '24': '',
      \   '25': '',
      \ }

"
" lamp#protocol#completion#get_kind_map
"
function! lamp#protocol#completion#get_kind_map() abort
  return copy(s:kind_map)
endfunction

"
" lamp#protocol#completion#get_kind_name
"
function! lamp#protocol#completion#get_kind_name(kind) abort
  return get(s:kind_map, string(a:kind), '')
endfunction

