let s:sign_ns = 'lamp#feature#diagnostic:sign'
let s:highlight_ns = 'lamp#feature#diagnostic:highlight'
let s:virtual_text_ns = 'lamp#feature#diagnostic:virtual_text'

"
" init
"
function! lamp#feature#diagnostic#init() abort
  execute printf('augroup lamp#feature#diagnostic_%d', bufnr('%'))
    autocmd!
    autocmd BufWritePost <buffer> call s:on_buf_write_pre()
    autocmd BufWinEnter <buffer> call s:on_buf_win_enter()
    autocmd InsertEnter <buffer> call s:on_action()
    autocmd InsertLeave <buffer> call s:on_action()
    autocmd CursorMoved <buffer> call s:on_action()
    autocmd CursorMovedI <buffer> call s:on_action()
  augroup END

  call s:update()
endfunction

"
" on_buf_write_pre
"
function! s:on_buf_write_pre() abort
  call s:update(v:true)
endfunction

"
" on_buf_win_enter
"
function! s:on_buf_win_enter() abort
  call s:update(v:false)
endfunction

"
" on_action
"
function! s:on_action() abort
  call s:check()
endfunction

"
" lamp#feature#diagnostic#update
"
function! lamp#feature#diagnostic#update(server, diagnostics) abort
  if a:diagnostics.is_decreased() || a:diagnostics.not_modified() || mode()[0] ==# 'n'
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
function! s:update(...) abort
  let l:force = get(a:000, 0, v:false)

  let l:bufnames = {}
  for l:winnr in range(1, tabpagewinnr(tabpagenr(), '$'))
    let l:bufnames[lamp#fnamemodify(bufname(winbufnr(l:winnr)), ':p')] = 1
  endfor

  for l:bufname in keys(l:bufnames)
    let l:uri = lamp#protocol#document#encode_uri(l:bufname)
    for l:server in lamp#server#registry#find_by_filetype(getbufvar(l:bufname, '&filetype'))
      let l:diagnostics = get(l:server.diagnostics, l:uri)
      let l:document = get(l:server.documents, l:uri)
      if !empty(l:diagnostics) && !empty(l:document) && (l:diagnostics.updated(l:document.version) || l:force)
        call s:apply(l:server.name, l:server.diagnostics[l:uri])
      else
        call lamp#log('[LOG]', 'diagnostics skipped: it does not updated', l:server.name)
      endif
    endfor
  endfor
endfunction

"
" apply
"
function! s:apply(server_name, diagnostics) abort
  if !a:diagnostics.is_shown()
    call lamp#log('[LOG]', 'diagnostics skipped: it does not shown', a:server_name)
    return
  endif

  if len(a:diagnostics.applied_diagnostics) == 0 && len(a:diagnostics.diagnostics) == 0
    call lamp#log('[LOG]', 'diagnostics skipped: 0 to 0', a:server_name)
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

  " update.
  for l:diagnostic in a:diagnostics.diagnostics
    let l:line = l:diagnostic.range.start.line

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

