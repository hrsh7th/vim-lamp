let s:Position = vital#lamp#import('VS.LSP.Position')

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
        \   'bufnr': a:bufnr,
        \   'all': v:true
        \ })
  let s:highlights = filter(s:highlights, { _, h ->
        \   h.namespace != a:namespace || h.bufnr != a:bufnr
        \ })
endfunction

"
" lamp#view#highlight#vim#add
"
if exists('*prop_add')
  function! lamp#view#highlight#vim#add(namespace, bufnr, range, highlight) abort
    call add(s:highlights, {
    \   'namespace': a:namespace,
    \   'bufnr': a:bufnr,
    \   'range': a:range,
    \   'highlight': a:highlight
    \ })

    let l:start = s:Position.lsp_to_vim(a:bufnr, a:range.start)
    let l:end = s:Position.lsp_to_vim(a:bufnr, a:range.end)
    call prop_add(l:start[0], l:start[1], {
    \   'id': a:namespace,
    \   'bufnr': a:bufnr,
    \   'end_lnum': l:end[0],
    \   'end_col': l:end[1],
    \   'type': a:highlight
    \ })
  endfunction
else
  function! lamp#view#highlight#vim#add(namespace, bufnr, range, highlight) abort
  endfunction
endif

"
" lamp#view#highlight#vim#get
"
if exists('*prop_add')
  function! lamp#view#highlight#vim#get(position) abort
    return filter(copy(s:highlights), { _, h -> lamp#protocol#position#in_range(a:position, h.range) })
  endfunction
else
  function! lamp#view#highlight#vim#get(position) abort
    return []
  endfunction
endif

