"
" lamp#protocol#location#normalize
"
function! lamp#protocol#location#normalize(locations) abort
  if empty(a:locations)
    return []
  endif

  let l:normalized = []
  for l:location in type(a:locations) == type([]) ? a:locations : [a:locations]
    if empty(l:location)
      continue
    endif

    " Location
    if has_key(l:location, 'uri')
      let l:normalized += [{
            \   'filename': lamp#protocol#document#decode_uri(l:location.uri),
            \   'lnum': l:location.range.start.line + 1,
            \   'col': l:location.range.start.character + 1,
            \ }]

    " LocationLink
    elseif has_key(l:location, 'targetUri')
      let l:normalized += [{
            \   'filename': lamp#protocol#document#decode_uri(l:location.targetUri),
            \   'lnum': l:location.targetSelectionRange.start.line + 1,
            \   'col': l:location.targetSelectionRange.start.character + 1,
            \ }]
    endif
  endfor
  return l:normalized
endfunction

