let s:Tooltip = lamp#view#tooltip#import()
let s:tooltip = s:Tooltip.new({})

"
" init
"
function! lamp#feature#diagnostic#init() abort
  augroup lamp#feature#diagnostic
    autocmd!
    autocmd WinEnter * call lamp#feature#diagnostic#update()
    autocmd BufEnter * call lamp#feature#diagnostic#update()
    autocmd CursorMoved * call lamp#feature#diagnostic#show_tooltip()
    autocmd InsertEnter * call lamp#feature#diagnostic#hide_tooltip()
  augroup END
endfunction

"
" lamp#feature#diagnostic#update
"
function! lamp#feature#diagnostic#update() abort
  let l:fn = {}
  function! l:fn.debounce() abort
    for l:winnr in range(1, tabpagewinnr(tabpagenr(), '$'))
      let l:bufnr = winbufnr(l:winnr)
      let l:uri = lamp#protocol#document#encode_uri(l:bufnr)
      let l:servers = values(lamp#server#registry#all())
      let l:servers = filter(l:servers, { k, v -> has_key(v.documents, l:uri) })

      let l:diagnostics = []
      for l:server in l:servers
        let l:diagnostics += l:server.documents[l:uri].diagnostics
      endfor

      call s:update(l:bufnr, l:diagnostics)
    endfor
    call lamp#feature#diagnostic#show_tooltip()
  endfunction
  call lamp#debounce('lamp#feature#diagnostic#update', l:fn.debounce, 500)
endfunction

"
" lamp#feature#diagnostic#show_tooltip
"
function! lamp#feature#diagnostic#show_tooltip() abort
  let l:fn = {}
  function! l:fn.debounce() abort
    if mode() !=# 'n'
      return
    endif

    let l:uri = lamp#protocol#document#encode_uri(bufnr('%'))
    let l:servers = values(lamp#server#registry#all())
    let l:servers = filter(l:servers, { k, v -> has_key(v.documents, l:uri) })

    let l:diagnostics = []
    for l:server in l:servers
      let l:diagnostics += filter(copy(l:server.documents[l:uri].diagnostics), { k, diagnostic ->
            \   lamp#protocol#range#in_line(diagnostic.range, lamp#protocol#position#get())
            \ })
    endfor

    if len(l:diagnostics)
      let l:position = [l:diagnostics[0].range.start.line + 1, l:diagnostics[0].range.start.character + 1]
      let l:contents = map(copy(l:diagnostics), { k, v -> {
            \   'lines': split(get(v, 'message', ''), "\n")
            \ } })
      call s:tooltip.show(l:position, l:contents)
    else
      call lamp#feature#diagnostic#hide_tooltip()
    endif
  endfunction
  call lamp#debounce('lamp#feature#diagnostic#show_tooltip', l:fn.debounce, 200)
endfunction

"
" lamp#feature#diagnostic#hide
"
function! lamp#feature#diagnostic#hide_tooltip() abort
  call s:tooltip.hide()
  call lamp#debounce('lamp#feature#diagnostic#show_tooltip', { -> {} }, 0)
endfunction

"
" s:update_sign
"
function! s:update(bufnr, diagnostics) abort
  call lamp#view#sign#remove(a:bufnr)
  call lamp#view#highlight#remove(a:bufnr)

  for l:diagnostic in a:diagnostics
    let l:severity = get(l:diagnostic, 'severity', 1)
    if l:severity == 1
      call lamp#view#sign#error(a:bufnr, l:diagnostic.range.start.line + 1)
      call lamp#view#highlight#error(a:bufnr, l:diagnostic.range)
    elseif l:severity == 2
      call lamp#view#sign#warning(a:bufnr, l:diagnostic.range.start.line + 1)
      call lamp#view#highlight#warning(a:bufnr, l:diagnostic.range)
    elseif l:severity == 3
      call lamp#view#sign#information(a:bufnr, l:diagnostic.range.start.line + 1)
      call lamp#view#highlight#information(a:bufnr, l:diagnostic.range)
    elseif l:severity == 4
      call lamp#view#sign#hint(a:bufnr, l:diagnostic.range.start.line + 1)
      call lamp#view#highlight#hint(a:bufnr, l:diagnostic.range)
    endif
  endfor
endfunction

