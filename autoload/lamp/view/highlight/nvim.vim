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
if exists('*nvim_buf_add_highlight')
  function! lamp#view#highlight#nvim#add(namespace, bufnr, range, highlight) abort
    try
      if !has_key(s:namespaces, a:namespace)
        let s:namespaces[a:namespace] = nvim_create_namespace(a:namespace)
      endif

      for l:range in s:ranges(a:bufnr, a:range)
        call add(s:highlights, {
              \   'namespace': a:namespace,
              \   'bufnr': a:bufnr,
              \   'range': l:range,
              \   'highlight': a:highlight
              \ })

        let l:start = s:Position.lsp_to_vim(a:bufnr, l:range.start)
        let l:end = s:Position.lsp_to_vim(a:bufnr, l:range.end)
        call nvim_buf_add_highlight(
              \   a:bufnr,
              \   s:namespaces[a:namespace],
              \   a:highlight,
              \   l:start[0] - 1,
              \   l:start[1] - 1,
              \   l:end[1] - 1
              \ )
      endfor
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
if exists('*nvim_buf_add_highlight')
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

"
" ranges
"
function! s:ranges(bufnr, range) abort
  if a:range.start.line == a:range.end.line
    return [a:range]
  endif

  let l:ranges = []
  for l:line in range(a:range.start.line, a:range.end.line)
    if a:range.start.line == l:line
      let l:ranges += [{
      \   'start': {
      \     'line': l:line,
      \     'character': a:range.start.character
      \   },
      \   'end': {
      \     'line': l:line,
      \     'character': strchars(get(getbufline(a:bufnr, l:line + 1), 0 , ''))
      \   }
      \ }]
    elseif a:range.end.line == l:line
      let l:ranges += [{
      \   'start': {
      \     'line': l:line,
      \     'character': 0
      \   },
      \   'end': {
      \     'line': l:line,
      \     'character': a:range.end.character
      \   }
      \ }]
    else
      let l:ranges += [{
      \   'start': {
      \     'line': l:line,
      \     'character': 0
      \   },
      \   'end': {
      \     'line': l:line,
      \     'character': strchars(get(getbufline(a:bufnr, l:line + 1), 0 , ''))
      \   }
      \ }]
    endif
  endfor
  return l:ranges
endfunction
