let s:highlights = []

"
" lamp#view#highlight#vim#remove
"
function! lamp#view#highlight#vim#remove(namespace, bufnr) abort
  if !exists('*prop_add')
    return
  endif

  call prop_remove({
        \   'id': a:namespace,
        \   'bufnr': a:bufnr
        \ })
  let s:highlights = filter(s:highlights, { _, h ->
        \   h.namespace != a:namespace || h.bufnr != a:bufnr
        \ })
endfunction

"
" lamp#view#highlight#vim#add
"
if exists('*prop_add')
  function! lamp#view#highlight#vim#add(namespace, bufnr, positions, highlight) abort
    for l:position in a:positions
      call add(s:highlights, {
            \   'namespace': a:namespace,
            \   'bufnr': a:bufnr,
            \   'position': l:position,
            \   'highlight': a:highlight
            \ })
      call prop_add(l:position[0] + 1, l:position[1] + 1, {
            \   'id': a:namespace,
            \   'bufnr': a:bufnr,
            \   'end_col': l:position[2] + 1,
            \   'type': a:highlight
            \ })
    endfor
  endfunction
else
  function! lamp#view#highlight#vim#add(namespace, bufnr, positions, highlight) abort
  endfunction
endif

"
" lamp#view#highlight#vim#get
"
if exists('*prop_add')
  function! lamp#view#highlight#vim#get(position) abort
    return filter(copy(s:highlights), { _, h ->
          \   h.position[0] == a:position.line
          \   && h.position[1] <= a:position.character && a:position.character <= h.position[2]
          \ })
  endfunction
else
  function! lamp#view#highlight#vim#get(position) abort
    return []
  endfunction
endif

