let s:highlight_ns = 'lamp#feature#diagnostic:highlight'
let s:virtual_text_ns = 'lamp#feature#diagnostic:virtual_text'

let s:context = {
      \   'changes': [],
      \   'state': {}
      \ }

"
" init
"
function! lamp#feature#diagnostic#init() abort
  execute printf('augroup lamp#feature#diagnostic_%d', bufnr('%'))
  autocmd!
  autocmd InsertLeave,TextChanged,TextChangedI,TextChangedP <buffer> call s:check()
  autocmd BufWritePost <buffer> call s:update()
augroup END
endfunction

"
" lamp#feature#diagnostic#update
"
function! lamp#feature#diagnostic#update(server, doc) abort
  call add(s:context.changes, {
        \   'server': a:server,
        \   'document': a:doc
        \ })
  call s:check()
endfunction

"
" check
"
function! s:check() abort
  if len(s:context.changes) == 0
    return
  endif

  let l:ctx = {}
  function! l:ctx.callback() abort
    call s:update()
    let s:context.changes = []
  endfunction

  let l:timeout = mode()[0] ==# 'n'
        \ ? lamp#config('feature.diagnostic.delay.normal')
        \ : lamp#config('feature.diagnostic.delay.insert')
  call lamp#debounce('lamp#feature#diagnostic:check', { -> l:ctx.callback() }, l:timeout)
endfunction

"
" update
"
function! s:update() abort
  call lamp#profile('diagnostics update')
  for l:change in s:context.changes
    let l:server = l:change.server
    let l:document = l:change.document

    if l:document.dirty
      continue
    endif

    " initialize buffer state
    let s:context.state[l:document.bufnr] = get(s:context.state, l:document.bufnr, {})

    " remove all signs.
    call lamp#view#sign#remove(l:document.bufnr)

    " remove per server.
    let l:highlight_ns = printf('%s:%s', s:highlight_ns, l:server.name)
    let l:virtual_text_ns = printf('%s:%s', s:virtual_text_ns, l:server.name)
    call lamp#view#highlight#remove(l:highlight_ns, l:document.bufnr)
    call lamp#view#virtual_text#remove(l:virtual_text_ns, l:document.bufnr)

    " remove buffer state.
    for [l:line, l:server_name_map] in items(s:context.state[l:document.bufnr])
      if has_key(l:server_name_map, l:server.name)
        unlet l:server_name_map[l:server.name]
      endif
    endfor

    " update.
    for l:diagnostic in l:change.document.diagnostics
      let l:line = l:diagnostic.range.start.line
      let s:context.state[l:document.bufnr][l:line] = get(s:context.state[l:document.bufnr], l:line, {})
      if len(keys(s:context.state[l:document.bufnr][l:line])) != 0
        continue
      endif
      let s:context.state[l:document.bufnr][l:line][l:server.name] = v:true

      let l:severity = get(l:diagnostic, 'severity', 1)
      if l:severity == 1
        call lamp#view#sign#error(l:document.bufnr, l:line + 1)
        call lamp#view#highlight#error(l:highlight_ns, l:document.bufnr, l:diagnostic.range)
        call lamp#view#virtual_text#error(l:virtual_text_ns, l:document.bufnr, l:line, l:diagnostic.message)
      elseif l:severity == 2
        call lamp#view#sign#warning(l:document.bufnr, l:line + 1)
        call lamp#view#highlight#warning(l:highlight_ns, l:document.bufnr, l:diagnostic.range)
        call lamp#view#virtual_text#warning(l:virtual_text_ns, l:document.bufnr, l:line, l:diagnostic.message)
      elseif l:severity == 3
        call lamp#view#sign#information(l:document.bufnr, l:line + 1)
        call lamp#view#highlight#information(l:highlight_ns, l:document.bufnr, l:diagnostic.range)
        call lamp#view#virtual_text#information(l:virtual_text_ns, l:document.bufnr, l:line, l:diagnostic.message)
      elseif l:severity == 4
        call lamp#view#sign#hint(l:document.bufnr, l:line + 1)
        call lamp#view#highlight#hint(l:highlight_ns, l:document.bufnr, l:diagnostic.range)
        call lamp#view#virtual_text#hint(l:virtual_text_ns, l:document.bufnr, l:line, l:diagnostic.message)
      endif
    endfor
  endfor
  call lamp#profile('diagnostics update', v:true)
endfunction

