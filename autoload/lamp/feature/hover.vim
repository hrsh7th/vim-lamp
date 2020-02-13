let s:Position = vital#lamp#import('LSP.Position')
let s:Promise = vital#lamp#import('Async.Promise')
let s:Floatwin = lamp#view#floatwin#import()
let s:floatwin = s:Floatwin.new({})

"
" for test.
"
function! lamp#feature#hover#test(test) abort
  let a:test.floatwin = s:floatwin
endfunction

"
" lamp#feature#hover#init
"
function! lamp#feature#hover#init() abort
  execute printf('augroup lamp#feature#hover_%d', bufnr('%'))
    autocmd!
    autocmd InsertEnter,CursorMoved <buffer> call s:close()
  augroup END
endfunction

"
" lamp#feature#hover#do
"
function! lamp#feature#hover#do() abort
  if s:floatwin.is_showing()
    call s:floatwin.enter()
    return
  endif

  let l:servers = lamp#server#registry#find_by_filetype(&filetype)
  let l:servers = filter(l:servers, { k, v -> v.supports('capabilities.hoverProvider') })
  if empty(l:servers)
    call lamp#view#notice#add({ 'lines': ['`Hover`: has no `Hover` capability.'] })
    return
  endif

  let l:bufnr = bufnr('%')
  let l:promises = map(l:servers, { k, v ->
        \   v.request('textDocument/hover', {
        \     'textDocument': lamp#protocol#document#identifier(l:bufnr),
        \     'position': s:Position.cursor()
        \   }).catch(lamp#rescue(v:null))
        \ })
  let l:p = s:Promise.all(l:promises)
  let l:p = l:p.then({ res -> s:on_response(l:bufnr, res) })
  let l:p = l:p.catch(lamp#rescue())
endfunction

"
" s:on_response
"
function! s:on_response(bufnr, responses) abort
  let l:contents = a:responses
  let l:contents = filter(l:contents, { k, v -> !empty(v) })
  let l:contents = map(l:contents, { k, v -> v.contents })
  let l:contents = lamp#protocol#markup_content#normalize(l:contents)
  if empty(l:contents)
    call lamp#view#notice#add({ 'lines': ['`Hover`: No hover content found.'] })
    return
  endif

  call s:floatwin.show_tooltip(lamp#view#floatwin#screenpos(line('.'), col('.')), l:contents)
endfunction

"
" s:close
"
function! s:close() abort
  if s:floatwin.is_showing()
    if win_getid() != s:floatwin.winid()
      call s:floatwin.hide()
    endif
  endif
endfunction

