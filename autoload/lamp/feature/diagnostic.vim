let s:Position = vital#lamp#import('VS.LSP.Position')
let s:sign_ns = 'lamp#feature#diagnostic:sign'
let s:highlight_ns = 'lamp#feature#diagnostic:highlight'

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
    autocmd WinEnter <buffer> call s:on_action()
    autocmd CursorMoved <buffer> call s:on_cursor_moved()
  augroup END

  call s:update()
endfunction

"
" lamp#feature#diagnostic#goto_next
"
function! lamp#feature#diagnostic#goto_next() abort
  call s:goto({ cursor_position, start_position ->
  \   lamp#protocol#position#after(cursor_position, start_position) && !lamp#protocol#position#same(cursor_position, start_position)
  \ })
endfunction

"
" lamp#feature#diagnostic#goto_prev
"
function! lamp#feature#diagnostic#goto_prev() abort
  call s:goto({ cursor_position, start_position ->
  \   lamp#protocol#position#after(start_position, cursor_position) && !lamp#protocol#position#same(cursor_position, start_position)
  \ })
endfunction

"
" s:goto
"
function! s:goto(filter) abort
  let l:cursor_position = s:Position.cursor()

  let l:diagnostics = []
  for l:server in lamp#server#registry#find_by_filetype(&filetype)
    let l:d = get(l:server.diagnostics, lamp#protocol#document#encode_uri(bufname('%')), {})
    for l:diagnostic in copy(get(l:d, 'applied_diagnostics', []))
      if a:filter(l:cursor_position, l:diagnostic.range.start)
        call add(l:diagnostics, l:diagnostic)
      endif
    endfor
  endfor

  if empty(l:diagnostics)
    return lamp#view#notice#add({ 'lines': ['`Diagnostics`: No diagnostics found.'] })
  endif

  let l:diagnostics = sort(l:diagnostics, { d1, d2 ->
  \   lamp#protocol#range#compare_nearest(d1.range, d2.range, l:cursor_position)
  \ })
  call cursor(s:Position.lsp_to_vim('%', l:diagnostics[0].range.start))
endfunction

"
" on_buf_write_pre
"
function! s:on_buf_write_pre() abort
  call s:update()
endfunction

"
" on_buf_win_enter
"
function! s:on_buf_win_enter() abort
  call s:update()
endfunction

"
" on_action
"
function! s:on_action() abort
  call lamp#view#floatwin#hide('diagnostic')
  call lamp#debounce('lamp#feature#diagnostic:on_cursor_moved', { -> {} }, 0)
endfunction

"
" on_cursor_moved
"
function! s:on_cursor_moved() abort
  call lamp#view#floatwin#hide('diagnostic')

  if mode()[0] !=# 'n'
    return
  endif

  let l:signs = get(sign_getplaced(bufnr('%'), { 'group': '*', 'lnum': line('.') }), 0, { 'signs': [] }).signs
  let l:signs = filter(copy(l:signs), { i, sign -> stridx(sign.group, s:sign_ns) == 0 })
  if len(l:signs) == 0
    return
  endif

  let l:ctx = {}
  function! l:ctx.callback() abort
    if mode()[0] !=# 'n'
      return
    endif

    let l:signs = get(sign_getplaced(bufnr('%'), { 'group': '*', 'lnum': line('.') }), 0, { 'signs': [] }).signs
    let l:signs = filter(copy(l:signs), { i, sign -> stridx(sign.group, s:sign_ns) == 0 })
    if len(l:signs) == 0
      return
    endif

    let l:position = s:Position.cursor()

    " Gaather diagnotics in range.
    let l:diagnostics = []
    for l:server in lamp#server#registry#find_by_filetype(&filetype)
      let l:ds = get(l:server.diagnostics, lamp#protocol#document#encode_uri(bufname('%')), {})
      let l:ds = get(l:ds, 'applied_diagnostics', [])
      let l:ds = filter(copy(l:ds), { _, diagnostic ->
      \   lamp#protocol#position#in_range(l:position, diagnostic.range) || (
      \     lamp#protocol#range#in_line(diagnostic.range) && match(lamp#protocol#range#get_text(bufnr('%'), diagnostic.range), '[^[:blank:]]') == -1
      \   )
      \ })
      let l:diagnostics += l:ds
    endfor

    if empty(l:diagnostics)
      call lamp#view#floatwin#hide('diagnostic')
      return
    endif

    try
      let l:position = l:diagnostics[0].range.start
      for l:diagnostic in l:diagnostics[1 : -1]
        if lamp#protocol#position#after(l:diagnostic.range.start, l:position)
          let l:position = l:diagnostic.range.start
        endif
      endfor

      let l:contents = []
      for l:diagnostic in l:diagnostics
        let l:content = ''
        if has_key(l:diagnostic, 'source')
          let l:content .= printf('`[%s]` ', l:diagnostic.source)
        endif
        let l:content .= l:diagnostic.message
        call add(l:contents, l:content)
      endfor

      if !empty(l:contents)
        let l:screenpos = lamp#view#floatwin#screenpos(l:position.line + 1, l:position.character + 1)
        call lamp#view#floatwin#show('diagnostic', l:screenpos, lamp#protocol#markup_content#normalize(l:contents), {
        \   'tooltip': v:true
        \ })
      else
        call lamp#view#floatwin#hide('diagnostic')
      endif
    catch /.*/
      echomsg string([v:exception, v:throwpoint])
    endtry
  endfunction
  call lamp#debounce('lamp#feature#diagnostic:on_cursor_moved', { -> l:ctx.callback() }, 500)
endfunction

"
" lamp#feature#diagnostic#update
"
function! lamp#feature#diagnostic#update(server, diagnostics) abort
  call s:update()
endfunction

"
" update
"
function! s:update() abort
  let l:bufnames = {}
  for l:winnr in range(1, tabpagewinnr(tabpagenr(), '$'))
    let l:bufnames[lamp#fnamemodify(bufname(winbufnr(l:winnr)), ':p')] = 1
  endfor

  for l:bufname in keys(l:bufnames)
    let l:uri = lamp#protocol#document#encode_uri(l:bufname)
    for l:server in lamp#server#registry#find_by_filetype(getbufvar(l:bufname, '&filetype'))
      let l:diagnostics = get(l:server.diagnostics, l:uri)
      let l:document = get(l:server.documents, l:uri)
      if !empty(l:diagnostics) && !empty(l:document) && l:diagnostics.updated(l:document.version)
        call s:apply(l:server.name, l:server.diagnostics[l:uri])
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
  let l:sign_ns = printf('%s:%s', s:sign_ns, a:server_name)
  call lamp#view#sign#remove(l:sign_ns, l:bufnr)
  call lamp#view#highlight#remove(l:highlight_ns, l:bufnr)

  " update.
  for l:diagnostic in a:diagnostics.diagnostics
    let l:line = l:diagnostic.range.start.line
    let l:severity = get(l:diagnostic, 'severity', 1)
    if l:severity == 1
      call lamp#view#sign#error(l:sign_ns, l:bufnr, l:line + 1)
      call lamp#view#highlight#error(l:highlight_ns, l:bufnr, l:diagnostic.range)
    elseif l:severity == 2
      call lamp#view#sign#warning(l:sign_ns, l:bufnr, l:line + 1)
      call lamp#view#highlight#warning(l:highlight_ns, l:bufnr, l:diagnostic.range)
    elseif l:severity == 3
      call lamp#view#sign#information(l:sign_ns, l:bufnr, l:line + 1)
      call lamp#view#highlight#information(l:highlight_ns, l:bufnr, l:diagnostic.range)
    elseif l:severity == 4
      call lamp#view#sign#hint(l:sign_ns, l:bufnr, l:line + 1)
      call lamp#view#highlight#hint(l:highlight_ns, l:bufnr, l:diagnostic.range)
    endif
  endfor
endfunction

