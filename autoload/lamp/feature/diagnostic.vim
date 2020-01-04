let s:highlight_ns = 'lamp#feature#diagnostic:highlight'
let s:virtual_text_ns = 'lamp#feature#diagnostic:virtual_text'

"
" init
"
function! lamp#feature#diagnostic#init() abort
  " noop
endfunction

"
" lamp#feature#diagnostic#update
"
function! lamp#feature#diagnostic#update() abort
  call lamp#debounce('lamp#feature#diagnostic#update', { -> s:update() }, 100)
endfunction

"
" update
"
function! s:update() abort
  if index(['i', 's'], mode()[0]) >= 0
    augroup lamp#feature#diagnostic
      autocmd!
      autocmd InsertLeave * call lamp#feature#diagnostic#update()
    augroup END
    return
  endif

  augroup lamp#feature#diagnostic
    autocmd!
  augroup END

  let l:context = {}

  for l:winnr in range(1, tabpagewinnr(tabpagenr(), '$'))
    let l:bufnr = winbufnr(l:winnr)
    if has_key(l:context, l:bufnr)
      continue
    endif
    let l:context[l:bufnr] = {}

    " clear.
    call lamp#view#sign#remove(l:bufnr)
    call lamp#view#highlight#remove(s:highlight_ns, l:bufnr)
    call lamp#view#virtual_text#remove(s:virtual_text_ns, l:bufnr)

    " update.
    for [l:server_name, l:document] in items(s:get_document_map(lamp#protocol#document#encode_uri(l:bufnr)))
      for l:diagnostic in l:document.diagnostics
        if has_key(l:context[l:bufnr], l:diagnostic.range.start.line)
          continue
        endif
        let l:context[l:bufnr][l:diagnostic.range.start.line] = v:true

        let l:severity = get(l:diagnostic, 'severity', 1)
        if l:severity == 1
          call lamp#view#sign#error(l:bufnr, l:diagnostic.range.start.line + 1)
          call lamp#view#highlight#error(s:highlight_ns, l:bufnr, l:diagnostic.range)
          call lamp#view#virtual_text#error(s:virtual_text_ns, l:bufnr, l:diagnostic.range.start.line, l:diagnostic.message)
        elseif l:severity == 2
          call lamp#view#sign#warning(l:bufnr, l:diagnostic.range.start.line + 1)
          call lamp#view#highlight#warning(s:highlight_ns, l:bufnr, l:diagnostic.range)
          call lamp#view#virtual_text#warning(s:virtual_text_ns, l:bufnr, l:diagnostic.range.start.line, l:diagnostic.message)
        elseif l:severity == 3
          call lamp#view#sign#information(l:bufnr, l:diagnostic.range.start.line + 1)
          call lamp#view#highlight#information(s:highlight_ns, l:bufnr, l:diagnostic.range)
          call lamp#view#virtual_text#information(s:virtual_text_ns, l:bufnr, l:diagnostic.range.start.line, l:diagnostic.message)
        elseif l:severity == 4
          call lamp#view#sign#hint(l:bufnr, l:diagnostic.range.start.line + 1)
          call lamp#view#highlight#hint(s:highlight_ns, l:bufnr, l:diagnostic.range)
          call lamp#view#virtual_text#hint(s:virtual_text_ns, l:bufnr, l:diagnostic.range.start.line, l:diagnostic.message)
        endif
      endfor
    endfor
  endfor
endfunction

"
" get_document_map
"
function! s:get_document_map(uri) abort
  let l:servers = lamp#server#registry#all()
  let l:servers = filter(l:servers, { k, v -> has_key(v.documents, a:uri) })
  if empty(l:servers)
    return {}
  endif
  let l:document_map = {}
  for l:server in l:servers
    let l:document_map[l:server.name] = l:server.documents[a:uri]
  endfor
  return l:document_map
endfunction

