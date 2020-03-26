let s:sign_ns = 'lamp#feature#diagnostic:sign'
let s:highlight_ns = 'lamp#feature#diagnostic:highlight'
let s:virtual_text_ns = 'lamp#feature#diagnostic:virtual_text'

"
" {
"   state: {
"     [bufname]: {
"       [lnum]: {
"         [server_name]: Diagnostic
"       }
"     }
"   }
" }
"
let s:context = {
\   'state': {}
\ }

"
" init
"
function! lamp#feature#diagnostic#init() abort
  call s:update()
endfunction

"
" lamp#feature#diagnostic#update
"
function! lamp#feature#diagnostic#update(server, diagnostics) abort
  if a:diagnostics.is_decreased() && a:diagnostics.is_shown()
    call lamp#log('[LOG]', 'diagnostics update immediately', a:server.name)
    call s:apply(a:server.name, a:diagnostics)
  else
    call lamp#log('[LOG]', 'diagnostics update debounced', a:server.name)
    call s:check()
  endif
endfunction

"
" check
"
function! s:check() abort
  let l:timeout = mode()[0] ==# 'i'
  \   ? lamp#config('feature.diagnostic.increase_delay.insert')
  \   : lamp#config('feature.diagnostic.increase_delay.normal')
  call lamp#debounce('lamp#feature#diagnostic#update', { -> s:update() }, l:timeout)
endfunction

"
" update
"
function! s:update() abort
  let l:bufnames = {}
  for l:winnr in range(1, tabpagewinnr(tabpagenr(), '$'))
    let l:bufnames[fnamemodify(bufname(winbufnr(l:winnr)), ':p')] = 1
  endfor

  for l:bufname in keys(l:bufnames)
    let l:uri = lamp#protocol#document#encode_uri(l:bufname)
    for l:server in lamp#server#registry#find_by_filetype(getbufvar(l:bufname, '&filetype'))
      if has_key(l:server.diagnostics, l:uri) && l:server.diagnostics[l:uri].updated()
        call s:apply(l:server.name, l:server.diagnostics[l:uri])
      else
        call lamp#log('[LOG]', 'diagnostics skipped', l:server.name)
      endif
    endfor
  endfor
endfunction

"
" apply
"
function! s:apply(server_name, diagnostics) abort
  if len(a:diagnostics.applied_diagnostics) == 0 && len(a:diagnostics.diagnostics) == 0
    call lamp#log('[LOG]', 'diagnostics skipped 0 to 0', a:server_name)
    return
  endif
  call lamp#log('[LOG]', 'diagnostics apply', a:server_name, len(a:diagnostics.applied_diagnostics), 'to', len(a:diagnostics.diagnostics))
  call a:diagnostics.applied()

  let l:bufnr = bufnr(a:diagnostics.bufname)

  " remove per server.
  let l:highlight_ns = printf('%s:%s', s:highlight_ns, a:server_name)
  let l:virtual_text_ns = printf('%s:%s', s:virtual_text_ns, a:server_name)
  let l:sign_ns = printf('%s:%s', s:sign_ns, a:server_name)
  call lamp#view#sign#remove(l:sign_ns, l:bufnr)
  call lamp#view#highlight#remove(l:highlight_ns, l:bufnr)
  call lamp#view#virtual_text#remove(l:virtual_text_ns, l:bufnr)

  " initialize buffer state
  let s:context.state[l:bufnr] = get(s:context.state, l:bufnr, {})

  " update.
  for l:diagnostic in a:diagnostics.diagnostics
    let l:line = l:diagnostic.range.start.line

    " initialize line state
    let s:context.state[l:bufnr][l:line] = get(s:context.state[l:bufnr], l:line, {})

    " skip if already applied for l:line
    if has_key(s:context.state[l:bufnr][l:line], a:server_name)
      unlet s:context.state[l:bufnr][l:line][a:server_name]
    endif
    if len(keys(s:context.state[l:bufnr][l:line])) != 0
      continue
    endif

    " add diagnostic
    let s:context.state[l:bufnr][l:line][a:server_name] = l:diagnostic
    let l:severity = get(l:diagnostic, 'severity', 1)
    if l:severity == 1
      call lamp#view#sign#error(l:sign_ns, l:bufnr, l:line + 1)
      call lamp#view#highlight#error(l:highlight_ns, l:bufnr, l:diagnostic.range)
      call lamp#view#virtual_text#error(l:virtual_text_ns, l:bufnr, l:line, l:diagnostic.message)
    elseif l:severity == 2
      call lamp#view#sign#warning(l:sign_ns, l:bufnr, l:line + 1)
      call lamp#view#highlight#warning(l:highlight_ns, l:bufnr, l:diagnostic.range)
      call lamp#view#virtual_text#warning(l:virtual_text_ns, l:bufnr, l:line, l:diagnostic.message)
    elseif l:severity == 3
      call lamp#view#sign#information(l:sign_ns, l:bufnr, l:line + 1)
      call lamp#view#highlight#information(l:highlight_ns, l:bufnr, l:diagnostic.range)
      call lamp#view#virtual_text#information(l:virtual_text_ns, l:bufnr, l:line, l:diagnostic.message)
    elseif l:severity == 4
      call lamp#view#sign#hint(l:sign_ns, l:bufnr, l:line + 1)
      call lamp#view#highlight#hint(l:highlight_ns, l:bufnr, l:diagnostic.range)
      call lamp#view#virtual_text#hint(l:virtual_text_ns, l:bufnr, l:line, l:diagnostic.message)
    endif
  endfor
endfunction

