let s:kind_map = {
      \   '1': 'Text',
      \   '2': 'Method',
      \   '3': 'Function',
      \   '4': 'Constructor',
      \   '5': 'Field',
      \   '6': 'Variable',
      \   '7': 'Class',
      \   '8': 'Interface',
      \   '9': 'Module',
      \   '10': 'Property',
      \   '11': 'Unit',
      \   '12': 'Value',
      \   '13': 'Enum',
      \   '14': 'Keyword',
      \   '15': 'Snippet',
      \   '16': 'Color',
      \   '17': 'File',
      \   '18': 'Reference',
      \   '19': 'Folder',
      \   '20': 'EnumMenber',
      \   '21': 'Constant',
      \   '22': 'Struct',
      \   '23': 'Event',
      \   '24': 'Operator',
      \   '25': 'TypeParameter',
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
  return get(s:kind_map, '' . a:kind, '')
endfunction

