let s:namespaces = {}
let s:highlights = []

"
" lamp#view#highlight#nvim#remove
"
function! lamp#view#highlight#nvim#remove(namespace, bufnr) abort
  if !exists('*nvim_buf_add_highlight')
    return
  endif

  if has_key(s:namespaces, a:namespace)
    call nvim_buf_clear_namespace(a:bufnr, s:namespaces[a:namespace], 0, -1)
  endif
  let s:highlights = filter(s:highlights, { _, h ->
        \   h.namespace != a:namespace || h.bufnr != a:bufnr
        \ })
endfunction

"
" lamp#view#highlight#nvim#add
"
function! lamp#view#highlight#nvim#add(namespace, bufnr, positions, highlight) abort
  if !exists('*nvim_buf_add_highlight')
    return
  endif

  if !has_key(s:namespaces, a:namespace)
    let s:namespaces[a:namespace] = nvim_create_namespace(a:namespace)
  endif

  for l:position in a:positions
    call add(s:highlights, {
          \   'namespace': a:namespace,
          \   'bufnr': a:bufnr,
          \   'position': l:position,
          \   'highlight': a:highlight
          \ })
    call nvim_buf_add_highlight(
          \   a:bufnr,
          \   s:namespaces[a:namespace],
          \   a:highlight,
          \   l:position[0],
          \   l:position[1],
          \   l:position[2]
          \ )
  endfor
endfunction

"
" lamp#view#highlight#nvim#get
"
function! lamp#view#highlight#nvim#get(position) abort
  if !exists('*nvim_buf_add_highlight')
    return []
  endif

  return filter(copy(s:highlights), { _, h ->
        \   h.position[0] == a:position.line
        \   && h.position[1] <= a:position.character && a:position.character <= h.position[2]
        \ })
endfunction

