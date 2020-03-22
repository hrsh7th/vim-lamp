let s:sign_ns = 'lamp#feature#diagnostic:sign'
let s:highlight_ns = 'lamp#feature#diagnostic:highlight'
let s:virtual_text_ns = 'lamp#feature#diagnostic:virtual_text'

"
" {
"   changes: {
"     [server_name]: {
"       document: Document,
"       changedtick: number
"     }
"   }[]
"   state: {
"     [bufnr]: {
"       [lnum]: {
"         [server_name]: Diagnostic
"       }
"     }
"   }
" }
"
let s:context = {
\   'changes': {},
\   'state': {}
\ }

"
" init
"
function! lamp#feature#diagnostic#init() abort
  augroup lamp#feature#diagnostic#init
    autocmd!
    autocmd InsertLeave * call s:check()
  augroup END
endfunction

"
" lamp#feature#diagnostic#update
"
function! lamp#feature#diagnostic#update(server, document) abort
  if a:document.applied_diagnostics_count > len(a:document.diagnostics)
    return s:update(a:server.name, a:document)
  endif

  let s:context.changes[a:server.name] = get(s:context.changes, a:server.name, {})
  let s:context.changes[a:server.name][a:document.bufnr] = {
  \   'document': a:document,
  \   'changedtick': a:document.get_changedtick(),
  \ }
  call s:check()
endfunction

"
" check
"
function! s:check() abort
  let l:ctx = {}
  function! l:ctx.callback() abort
    for [l:server_name, l:changes] in items(s:context.changes)
      for [l:bufnr, l:state] in items(l:changes)
        if l:state.changedtick != l:state.document.get_changedtick() || s:update(l:server_name, l:state.document)
          call remove(s:context.changes[l:server_name], l:state.document.bufnr)
        endif
      endfor
    endfor
  endfunction

  let l:timeout = mode()[0] ==# 'i'
  \   ? lamp#config('feature.diagnostic.increase_delay.insert')
  \   : lamp#config('feature.diagnostic.increase_delay.normal')
  call lamp#debounce('lamp#feature#diagnostic:check', { -> l:ctx.callback() }, l:timeout)
endfunction

"
" update
"
function! s:update(server_name, document) abort
  let a:document.applied_diagnostics_count = len(a:document.diagnostics)

  " remove per server.
  let l:highlight_ns = printf('%s:%s', s:highlight_ns, a:server_name)
  let l:virtual_text_ns = printf('%s:%s', s:virtual_text_ns, a:server_name)
  let l:sign_ns = printf('%s:%s', s:sign_ns, a:server_name)
  call lamp#view#sign#remove(l:sign_ns, a:document.bufnr)
  call lamp#view#highlight#remove(l:highlight_ns, a:document.bufnr)
  call lamp#view#virtual_text#remove(l:virtual_text_ns, a:document.bufnr)

  " initialize buffer state
  let s:context.state[a:document.bufnr] = get(s:context.state, a:document.bufnr, {})

  " update.
  for l:diagnostic in a:document.diagnostics
    let l:line = l:diagnostic.range.start.line

    " initialize line state
    let s:context.state[a:document.bufnr][l:line] = get(s:context.state[a:document.bufnr], l:line, {})

    " skip if already applied for l:line
    if has_key(s:context.state[a:document.bufnr][l:line], a:server_name)
      unlet s:context.state[a:document.bufnr][l:line][a:server_name]
    endif
    if len(keys(s:context.state[a:document.bufnr][l:line])) != 0
      continue
    endif

    " add diagnostic
    let s:context.state[a:document.bufnr][l:line][a:server_name] = l:diagnostic
    let l:severity = get(l:diagnostic, 'severity', 1)
    if l:severity == 1
      call lamp#view#sign#error(l:sign_ns, a:document.bufnr, l:line + 1)
      call lamp#view#highlight#error(l:highlight_ns, a:document.bufnr, l:diagnostic.range)
      call lamp#view#virtual_text#error(l:virtual_text_ns, a:document.bufnr, l:line, l:diagnostic.message)
    elseif l:severity == 2
      call lamp#view#sign#warning(l:sign_ns, a:document.bufnr, l:line + 1)
      call lamp#view#highlight#warning(l:highlight_ns, a:document.bufnr, l:diagnostic.range)
      call lamp#view#virtual_text#warning(l:virtual_text_ns, a:document.bufnr, l:line, l:diagnostic.message)
    elseif l:severity == 3
      call lamp#view#sign#information(l:sign_ns, a:document.bufnr, l:line + 1)
      call lamp#view#highlight#information(l:highlight_ns, a:document.bufnr, l:diagnostic.range)
      call lamp#view#virtual_text#information(l:virtual_text_ns, a:document.bufnr, l:line, l:diagnostic.message)
    elseif l:severity == 4
      call lamp#view#sign#hint(l:sign_ns, a:document.bufnr, l:line + 1)
      call lamp#view#highlight#hint(l:highlight_ns, a:document.bufnr, l:diagnostic.range)
      call lamp#view#virtual_text#hint(l:virtual_text_ns, a:document.bufnr, l:line, l:diagnostic.message)
    endif
  endfor

  return v:true
endfunction

