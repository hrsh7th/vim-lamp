let s:Floatwin = lamp#view#floatwin#import()
let s:floatwin = s:Floatwin.new({})


"
" init
"
function! lamp#feature#diagnostic#init() abort
  augroup lamp#feature#diagnostic
    autocmd!

    " update tooltip.
    autocmd CursorMoved * call s:show_floatwin()
    autocmd InsertEnter * call s:clear_for_insertmode()

    " update signs & highlights.
    autocmd WinEnter,BufEnter * call s:update()
    autocmd InsertLeave * call s:update()
  augroup END
endfunction

"
" lamp#feature#diagnostic#update
"
function! lamp#feature#diagnostic#update() abort
  if mode() !=# 'n'
    return
  endif

  let l:fn = {}
  function! l:fn.debounce() abort
    call s:update()
    call s:show_floatwin()
  endfunction
  call lamp#debounce('lamp#feature#diagnostic#update', l:fn.debounce, 100)
endfunction

"
" lamp#feature#diagnostic#show_floatwin
"
function! s:show_floatwin() abort
  if mode() !=# 'n' || empty(lamp#view#sign#get_line(bufnr('%'), line('.')))
    call s:floatwin.hide()
    return
  endif

  let l:fn = {}
  function! l:fn.debounce() abort
    if mode() !=# 'n' || empty(lamp#view#sign#get_line(bufnr('%'), line('.')))
      call s:floatwin.hide()
      return
    endif

    let l:uri = lamp#protocol#document#encode_uri(bufnr('%'))
    let l:servers = lamp#server#registry#all()
    let l:servers = filter(l:servers, { k, v -> has_key(v.documents, l:uri) })

    let l:diagnostics = []
    for l:server in l:servers
      let l:diagnostics += filter(copy(l:server.documents[l:uri].diagnostics), { k, diagnostic ->
            \   lamp#protocol#range#in_line(diagnostic.range, lamp#protocol#position#get())
            \ })
    endfor

    if !empty(l:diagnostics)
      let l:screenpos = lamp#view#floatwin#screenpos(l:diagnostics[0].range.start.line + 1, l:diagnostics[0].range.start.character + 1)
      let l:contents = map(copy(l:diagnostics), { k, v ->
            \   {
            \     'lines': split(get(v, 'message', ''), "\n", v:true)
            \   }
            \ })
      call s:floatwin.show_tooltip(l:screenpos, l:contents)
    else
      call s:floatwin.hide()
    endif
  endfunction

  if s:floatwin.is_showing()
    call l:fn.debounce()
  else
    call lamp#debounce('lamp#feature#diagnostic:show_floatwin', l:fn.debounce, 500)
  endif
endfunction

"
" s:clear_for_insertmode
"
function! s:clear_for_insertmode() abort
  call s:floatwin.hide()
  call lamp#view#highlight#remove(bufnr('%'))
endfunction

"
" s:update
"
function! s:update() abort
  if mode() !=# 'n'
    return
  endif

  for l:winnr in range(1, tabpagewinnr(tabpagenr(), '$'))
    let l:bufnr = winbufnr(l:winnr)

    call lamp#view#sign#remove(l:bufnr)
    call lamp#view#highlight#remove(l:bufnr)

    " update.
    for [l:server_name, l:diagnostics] in items(s:get_diagnostic_map(lamp#protocol#document#encode_uri(l:bufnr)))
      for l:diagnostic in l:diagnostics
        let l:severity = get(l:diagnostic, 'severity', 1)
        if l:severity == 1
          call lamp#view#sign#error(l:bufnr, l:diagnostic.range.start.line + 1)
          call lamp#view#highlight#error(l:bufnr, l:diagnostic.range)
        elseif l:severity == 2
          call lamp#view#sign#warning(l:bufnr, l:diagnostic.range.start.line + 1)
          call lamp#view#highlight#error(l:bufnr, l:diagnostic.range)
        elseif l:severity == 3
          call lamp#view#sign#information(l:bufnr, l:diagnostic.range.start.line + 1)
          call lamp#view#highlight#error(l:bufnr, l:diagnostic.range)
        elseif l:severity == 4
          call lamp#view#sign#hint(l:bufnr, l:diagnostic.range.start.line + 1)
          call lamp#view#highlight#error(l:bufnr, l:diagnostic.range)
        endif
      endfor
    endfor
  endfor
endfunction

"
" s:get_diagnostic_map
"
function! s:get_diagnostic_map(uri) abort
  let l:servers = lamp#server#registry#all()
  let l:servers = filter(l:servers, { k, v -> has_key(v.documents, a:uri) })
  if empty(l:servers)
    return {}
  endif

  let l:diagnostic_map = {}
  for l:server in l:servers
    let l:diagnostic_map[l:server.name] = l:server.documents[a:uri].diagnostics
  endfor
  return l:diagnostic_map
endfunction

