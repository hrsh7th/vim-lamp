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
  augroup lamp#feature#hover
    autocmd!
    autocmd InsertEnter,CursorMoved * call s:close()
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
    return
  endif

  let l:bufnr = bufnr('%')
  let l:promises = map(l:servers, { k, v ->
        \   v.request('textDocument/hover', {
        \     'textDocument': lamp#protocol#document#identifier(l:bufnr),
        \     'position': lamp#protocol#position#get()
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
    return
  endif

  call s:floatwin.show_tooltip(lamp#view#floatwin#screenpos(line('.'), col('.')), l:contents)
endfunction

"
" s:close
"
function! s:close() abort
  if s:floatwin.is_showing()
    if winnr() != s:floatwin.winnr()
      call s:floatwin.hide()
    endif
  endif
endfunction

