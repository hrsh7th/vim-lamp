let s:highlight_ns = 'lamp#feature#diagnostic:highlight'
let s:virtual_text_ns = 'lamp#feature#diagnostic:virtual_text'

let s:context = {
      \   'has_changed_contents': v:false,
      \   'increase_diagnostics': v:false
      \ }

"
" init
"
function! lamp#feature#diagnostic#init() abort
  execute printf('augroup lamp#feature#diagnostic_%d', bufnr('%'))
    autocmd!
    autocmd TextChanged,TextChangedI,TextChangedP <buffer> call s:check()
  augroup END
endfunction

"
" lamp#feature#diagnostic#update
"
function! lamp#feature#diagnostic#update(increase_diagnostics) abort
  let s:context.has_changed_contents = v:true
  let s:context.increase_diagnostics = a:increase_diagnostics
  call s:check()
endfunction

"
" check
"
function! s:check() abort
  let l:ctx = {}
  function! l:ctx.callback() abort
    if s:context.has_changed_contents
      call s:update()
      let s:context.has_changed_contents = v:false
    endif
  endfunction
  call lamp#debounce(
        \   'lamp#feature#diagnostic:check',
        \   { -> l:ctx.callback() },
        \   s:context.increase_diagnostics
        \     ? lamp#config('feature.diagnostic.increase.delay')
        \     : lamp#config('feature.diagnostic.decrease.delay')
        \ )
endfunction

"
" update
"
function! s:update() abort
  let l:context = {}

  for l:winnr in range(1, tabpagewinnr(tabpagenr(), '$'))
    let l:bufnr = winbufnr(l:winnr)
    if has_key(l:context, l:bufnr)
      continue
    endif
    let l:context[l:bufnr] = {}

    call lamp#view#sign#remove(l:bufnr)

    " update.
    for [l:server_name, l:document] in items(s:get_document_map(lamp#protocol#document#encode_uri(l:bufnr)))
      let l:highlight_ns = printf('%s:%s', s:highlight_ns, l:server_name)
      let l:virtual_text_ns = printf('%s:%s', s:virtual_text_ns, l:server_name)
      call lamp#view#highlight#remove(l:highlight_ns, l:bufnr)
      call lamp#view#virtual_text#remove(l:virtual_text_ns, l:bufnr)

      for l:diagnostic in l:document.diagnostics
        if has_key(l:context[l:bufnr], l:diagnostic.range.start.line)
          continue
        endif
        let l:context[l:bufnr][l:diagnostic.range.start.line] = v:true

        let l:severity = get(l:diagnostic, 'severity', 1)
        if l:severity == 1
          call lamp#view#sign#error(l:bufnr, l:diagnostic.range.start.line + 1)
          call lamp#view#highlight#error(l:highlight_ns, l:bufnr, l:diagnostic.range)
          call lamp#view#virtual_text#error(l:virtual_text_ns, l:bufnr, l:diagnostic.range.start.line, l:diagnostic.message)
        elseif l:severity == 2
          call lamp#view#sign#warning(l:bufnr, l:diagnostic.range.start.line + 1)
          call lamp#view#highlight#warning(l:highlight_ns, l:bufnr, l:diagnostic.range)
          call lamp#view#virtual_text#warning(l:virtual_text_ns, l:bufnr, l:diagnostic.range.start.line, l:diagnostic.message)
        elseif l:severity == 3
          call lamp#view#sign#information(l:bufnr, l:diagnostic.range.start.line + 1)
          call lamp#view#highlight#information(l:highlight_ns, l:bufnr, l:diagnostic.range)
          call lamp#view#virtual_text#information(l:virtual_text_ns, l:bufnr, l:diagnostic.range.start.line, l:diagnostic.message)
        elseif l:severity == 4
          call lamp#view#sign#hint(l:bufnr, l:diagnostic.range.start.line + 1)
          call lamp#view#highlight#hint(l:highlight_ns, l:bufnr, l:diagnostic.range)
          call lamp#view#virtual_text#hint(l:virtual_text_ns, l:bufnr, l:diagnostic.range.start.line, l:diagnostic.message)
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
    let l:doc = l:server.documents[a:uri]
    if !l:doc.dirty
      let l:document_map[l:server.name] = l:server.documents[a:uri]
    endif
  endfor
  return l:document_map
endfunction

