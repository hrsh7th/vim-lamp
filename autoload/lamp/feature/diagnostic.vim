let s:Floatwin = lamp#view#floatwin#import()
let s:floatwin = s:Floatwin.new({})

let s:highlight_namespace = 'lamp#feature#diagnostic'

"
" init
"
function! lamp#feature#diagnostic#init() abort
  augroup lamp#feature#diagnostic
    autocmd!
    autocmd CursorMoved * call s:show_floatwin()
    autocmd InsertEnter * call s:on_insert_enter()
    autocmd InsertLeave,BufWritePost * call lamp#feature#diagnostic#update()
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
  if s:floatwin.is_showing()
    if empty(lamp#view#sign#get_line(bufnr('%'), line('.')))
      call s:floatwin.hide()
    endif
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
            \   lamp#protocol#range#in_line(diagnostic.range)
            \ })
    endfor

    if !empty(l:diagnostics)
      let l:screenpos = lamp#view#floatwin#screenpos(
            \ l:diagnostics[0].range.start.line + 1,
            \ l:diagnostics[0].range.start.character)
      let l:contents = map(copy(l:diagnostics), { k, v ->
            \   {
            \     'lines': split(get(v, 'message', ''), "\n", v:true)
            \   }
            \ })
      call s:floatwin.show(l:screenpos, l:contents)
    else
      call s:floatwin.hide()
    endif
  endfunction

  if s:floatwin.is_showing()
    call l:fn.debounce()
  else
    call lamp#debounce('lamp#feature#diagnostic:show_floatwin', l:fn.debounce, 800)
  endif
endfunction

"
" s:clear_for_insertmode
"
function! s:on_insert_enter() abort
  call s:floatwin.hide()
  call lamp#view#highlight#remove(s:highlight_namespace, bufnr('%'))
endfunction

"
" s:update
"
function! s:update() abort
  if mode() !=# 'n'
    return
  endif

  let l:updated_bufnrs = {}
  for l:winnr in range(1, tabpagewinnr(tabpagenr(), '$'))
    let l:bufnr = winbufnr(l:winnr)
    if has_key(l:updated_bufnrs, l:bufnr)
      continue
    endif
    let l:updated_bufnrs[l:bufnr] = v:true

    " clear.
    call lamp#view#sign#remove(l:bufnr)
    call lamp#view#highlight#remove(s:highlight_namespace, l:bufnr)

    " update.
    for [l:server_name, l:document] in items(s:get_document_map(lamp#protocol#document#encode_uri(l:bufnr)))
      for l:diagnostic in l:document.diagnostics
        let l:severity = get(l:diagnostic, 'severity', 1)
        if l:severity == 1
          call lamp#view#sign#error(l:bufnr, l:diagnostic.range.start.line + 1)
          call lamp#view#highlight#error(s:highlight_namespace, l:bufnr, l:diagnostic.range)
        elseif l:severity == 2
          call lamp#view#sign#warning(l:bufnr, l:diagnostic.range.start.line + 1)
          call lamp#view#highlight#warning(s:highlight_namespace, l:bufnr, l:diagnostic.range)
        elseif l:severity == 3
          call lamp#view#sign#information(l:bufnr, l:diagnostic.range.start.line + 1)
          call lamp#view#highlight#information(s:highlight_namespace, l:bufnr, l:diagnostic.range)
        elseif l:severity == 4
          call lamp#view#sign#hint(l:bufnr, l:diagnostic.range.start.line + 1)
          call lamp#view#highlight#hint(s:highlight_namespace, l:bufnr, l:diagnostic.range)
        endif
      endfor
    endfor
  endfor
endfunction

"
" s:get_document_map
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

