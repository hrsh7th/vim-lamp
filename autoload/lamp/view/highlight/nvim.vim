let s:Position = vital#lamp#import('VS.LSP.Position')

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
if exists('*nvim_buf_set_extmark')
  function! lamp#view#highlight#nvim#add(namespace, bufnr, range, highlight) abort
    try
      if !has_key(s:namespaces, a:namespace)
        let s:namespaces[a:namespace] = nvim_create_namespace(a:namespace)
      endif

      call add(s:highlights, {
      \   'namespace': a:namespace,
      \   'bufnr': a:bufnr,
      \   'range': a:range,
      \   'highlight': a:highlight
      \ })

      let l:start = s:Position.lsp_to_vim(a:bufnr, a:range.start)
      let l:end = s:Position.lsp_to_vim(a:bufnr, a:range.end)
      call nvim_buf_set_extmark(
      \   a:bufnr,
      \   s:namespaces[a:namespace],
      \   l:start[0] - 1,
      \   l:start[1] - 1,
      \   {
      \     'end_line': l:end[0] - 1,
      \     'end_col': l:end[1] - 1,
      \     'hl_group': a:highlight,
      \   }
      \ )
    catch /.*/
    endtry
  endfunction
else
  function! lamp#view#highlight#nvim#add(namespace, bufnr, range, highlight) abort
  endfunction
endif

"
" lamp#view#highlight#nvim#get
"
if exists('*nvim_buf_get_extmarks')
  function! lamp#view#highlight#nvim#get(position) abort
    return filter(copy(s:highlights), { _, h ->
    \   h.range.start.line == a:position.line
    \   && h.range.start.line <= a:position.character && a:position.character <= h.range.start.character
    \ })
  endfunction
else
  function! lamp#view#highlight#nvim#get(position) abort
    return []
  endfunction
endif

