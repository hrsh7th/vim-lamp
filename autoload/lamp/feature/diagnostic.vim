let s:Floatwin = lamp#view#floatwin#import()
let s:floatwin = s:Floatwin.new({})

let s:highlight_ns = 'lamp#feature#diagnostic:highlight'
let s:virtual_text_ns = 'lamp#feature#diagnostic:virtual_text'

"
" init
"
function! lamp#feature#diagnostic#init() abort
  augroup lamp#feature#diagnostic
    autocmd!
    autocmd CursorMoved * call s:show_floatwin()
    autocmd InsertEnter * call s:on_insert_enter()
    autocmd InsertLeave * call lamp#feature#diagnostic#update()
  augroup END
endfunction

"
" lamp#feature#diagnostic#update
"
function! lamp#feature#diagnostic#update() abort
  call s:show_floatwin()

  let l:ctx = {}
  function! l:ctx.callback() abort
    call s:update()
  endfunction
  call lamp#debounce('lamp#feature#diagnostic#update', l:ctx.callback, 200)
endfunction

"
" show_floatwin
"
function! s:show_floatwin() abort
  if s:floatwin.is_showing()
    if empty(lamp#view#sign#get_line(bufnr('%'), line('.')))
      call s:floatwin.hide()
    endif
    return
  endif

  let l:ctx = {}
  function! l:ctx.callback() abort
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
    call l:ctx.callback()
  else
    call lamp#debounce('lamp#feature#diagnostic:show_floatwin', l:ctx.callback, 800)
  endif
endfunction

"
" on_insert_enter
"
function! s:on_insert_enter() abort
  call s:floatwin.hide()
  call lamp#view#highlight#remove(s:highlight_ns, bufnr('%'))
endfunction

"
" update
"
function! s:update() abort
  call lamp#log('[CALL] lamp#feature#diagnostic s:update')

  let l:updated_bufnrs = {}
  for l:winnr in range(1, tabpagewinnr(tabpagenr(), '$'))
    let l:bufnr = winbufnr(l:winnr)
    if has_key(l:updated_bufnrs, l:bufnr)
      continue
    endif
    let l:updated_bufnrs[l:bufnr] = v:true

    " clear.
    call lamp#view#sign#remove(l:bufnr)
    call lamp#view#highlight#remove(s:highlight_ns, l:bufnr)
    call lamp#view#virtual_text#remove(s:virtual_text_ns, l:bufnr)

    " update.
    for [l:server_name, l:document] in items(s:get_document_map(lamp#protocol#document#encode_uri(l:bufnr)))
      for l:diagnostic in l:document.diagnostics
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

