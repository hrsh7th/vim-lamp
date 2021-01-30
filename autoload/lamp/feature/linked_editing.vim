let s:Position = vital#lamp#import('VS.LSP.Position')
let s:TextEdit = vital#lamp#import('VS.LSP.TextEdit')
let s:TextMark = vital#lamp#import('VS.Vim.Buffer.TextMark')

let s:state = {
\   'bufnr': -1,
\   'changenr': -1,
\   'changedtick': -1,
\ }

"
" lamp#feature#linked_editing#init
"
function! lamp#feature#linked_editing#init() abort
  execute printf('augroup lamp#feature#linked_editing_%d', bufnr('%'))
    autocmd!
    autocmd InsertEnter <buffer> call s:prepare(v:true)
    autocmd InsertLeave <buffer> call s:TextMark.clear(bufnr('%'), 'linkedEditingRange')
    autocmd TextChanged,TextChangedI,TextChangedP <buffer> call s:sync()
  augroup END
endfunction


"
" lamp#feature#linked_editing#prepare
"
function! lamp#feature#linked_editing#prepare() abort
  call s:prepare(v:true)
endfunction

"
" prepare
"
function! s:prepare(sync) abort
  let l:servers = lamp#server#registry#find_by_filetype(&filetype)
  let l:servers = filter(l:servers, { _, server -> server.supports('capabilities.linkedEditingRangeProvider') })
  if empty(l:servers)
    return
  endif
  let l:server = l:servers[0]

  let l:bufnr = bufnr('%')
  let l:p = l:server.request('textDocument/linkedEditingRange', {
  \   'textDocument': lamp#protocol#document#identifier(bufnr('%')),
  \   'position': s:Position.cursor(),
  \ }).catch(lamp#rescue([])).then({ response -> s:on_response(l:bufnr, response) })
  if a:sync
    call lamp#sync(l:p)
  endif
endfunction

"
" on_response
"
function! s:on_response(bufnr, response) abort
  if empty(a:response) || !has_key(a:response, 'ranges') || empty(get(a:response, 'ranges', []))
    return
  endif

  let l:marks = map(copy(a:response.ranges), {
  \   _, range -> {
  \     'start_pos': s:Position.lsp_to_vim(a:bufnr, range.start),
  \     'end_pos': s:Position.lsp_to_vim(a:bufnr, range.end),
  \     'highlight': 'Underlined'
  \   }
  \ })
  if empty(l:marks)
    return
  endif

  let s:state.bufnr = a:bufnr
  let s:state.changenr = changenr()
  let s:state.changedtick = b:changedtick
  call s:TextMark.clear(a:bufnr, 'linkedEditingRange')
  call s:TextMark.set(a:bufnr, 'linkedEditingRange', l:marks)

  if has('nvim') " TODO: Currently, neovim's extmark does not have gravity option but if we update range once, it will be have a gravity.
    let l:new_text = lamp#protocol#range#get_text(a:bufnr, a:response.ranges[0])
    call s:TextEdit.apply(a:bufnr, map(copy(a:response.ranges), { _, range -> {
    \   'range': range,
    \   'newText': l:new_text
    \ } }))
  endif
endfunction

"
" sync
"
function! s:sync() abort
  let l:bufnr = bufnr('%')
  " check buffer.
  if s:state.bufnr != l:bufnr
    return
  endif

  " check modified.
  if s:state.changedtick == b:changedtick
    return
  endif

  " check undo.
  if s:state.changenr > changenr()
    return
  endif

  let l:position = s:Position.cursor()
  let l:target_mark = v:null
  let l:related_marks = []
  for l:mark in s:TextMark.get(l:bufnr, 'linkedEditingRange')
    if lamp#protocol#position#in_range(l:position, {
    \   'start': s:Position.vim_to_lsp(l:bufnr, l:mark.start_pos),
    \   'end': s:Position.vim_to_lsp(l:bufnr, l:mark.end_pos),
    \ })
      let l:target_mark = l:mark
    else
      call add(l:related_marks, l:mark)
    endif
  endfor

  if empty(l:target_mark)
    return
  endif

  let l:new_text = lamp#protocol#range#get_text(l:bufnr, {
  \   'start': s:Position.vim_to_lsp(l:bufnr, l:target_mark.start_pos),
  \   'end': s:Position.vim_to_lsp(l:bufnr, l:target_mark.end_pos),
  \ })
  if l:new_text =~# '[^[:keyword:]]$'
    call s:TextMark.clear(l:bufnr, 'linkedEditingRange')
    call feedkeys("\<C-G>u", 'n')
    return
  endif
  call s:TextEdit.apply(l:bufnr, map(l:related_marks, { _, mark -> {
  \   'range': {
  \     'start': s:Position.vim_to_lsp(l:bufnr, mark.start_pos),
  \     'end': s:Position.vim_to_lsp(l:bufnr, mark.end_pos),
  \   },
  \   'newText': l:new_text
  \ } }))
  let s:state.bufnr = l:bufnr
  let s:state.changenr = changenr()
  let s:state.changedtick = b:changedtick
endfunction

