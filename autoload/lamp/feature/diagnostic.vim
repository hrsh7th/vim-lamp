let s:sign_ns = 'lamp#feature#diagnostic:sign'
let s:highlight_ns = 'lamp#feature#diagnostic:highlight'
let s:virtual_text_ns = 'lamp#feature#diagnostic:virtual_text'

"
" {
"   changes: {
"     server: Server,
"     document: Document
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
      \   'changes': [],
      \   'state': {}
      \ }

"
" init
"
function! lamp#feature#diagnostic#init() abort
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
  for l:change in s:context.changes
    let l:server = l:change.server
    let l:document = l:change.document

    " remove per server.
    let l:highlight_ns = printf('%s:%s', s:highlight_ns, l:server.name)
    let l:virtual_text_ns = printf('%s:%s', s:virtual_text_ns, l:server.name)
    let l:sign_ns = printf('%s:%s', s:sign_ns, l:server.name)
    call lamp#view#sign#remove(l:sign_ns, l:document.bufnr)
    call lamp#view#highlight#remove(l:highlight_ns, l:document.bufnr)
    call lamp#view#virtual_text#remove(l:virtual_text_ns, l:document.bufnr)

    " initialize buffer state
    let s:context.state[l:document.bufnr] = get(s:context.state, l:document.bufnr, {})

    " update.
    for l:diagnostic in l:change.document.diagnostics
      let l:line = l:diagnostic.range.start.line

      " initialize line state
      let s:context.state[l:document.bufnr][l:line] = get(s:context.state[l:document.bufnr], l:line, {})

      " skip if already applied for l:line
      if has_key(s:context.state[l:document.bufnr][l:line], l:server.name)
        unlet s:context.state[l:document.bufnr][l:line][l:server.name]
      endif
      if len(keys(s:context.state[l:document.bufnr][l:line])) != 0
        continue
      endif

      " add diagnostic
      call lamp#profile('diagnostic update')
      let s:context.state[l:document.bufnr][l:line][l:server.name] = l:diagnostic
      let l:severity = get(l:diagnostic, 'severity', 1)
      if l:severity == 1
        call lamp#view#sign#error(l:sign_ns, l:document.bufnr, l:line + 1)
        call lamp#view#highlight#error(l:highlight_ns, l:document.bufnr, l:diagnostic.range)
        call lamp#view#virtual_text#error(l:virtual_text_ns, l:document.bufnr, l:line, l:diagnostic.message)
      elseif l:severity == 2
        call lamp#view#sign#warning(l:sign_ns, l:document.bufnr, l:line + 1)
        call lamp#view#highlight#warning(l:highlight_ns, l:document.bufnr, l:diagnostic.range)
        call lamp#view#virtual_text#warning(l:virtual_text_ns, l:document.bufnr, l:line, l:diagnostic.message)
      elseif l:severity == 3
        call lamp#view#sign#information(l:sign_ns, l:document.bufnr, l:line + 1)
        call lamp#view#highlight#information(l:highlight_ns, l:document.bufnr, l:diagnostic.range)
        call lamp#view#virtual_text#information(l:virtual_text_ns, l:document.bufnr, l:line, l:diagnostic.message)
      elseif l:severity == 4
        call lamp#view#sign#hint(l:sign_ns, l:document.bufnr, l:line + 1)
        call lamp#view#highlight#hint(l:highlight_ns, l:document.bufnr, l:diagnostic.range)
        call lamp#view#virtual_text#hint(l:virtual_text_ns, l:document.bufnr, l:line, l:diagnostic.message)
      endif
    endfor
  endfor
endfunction

