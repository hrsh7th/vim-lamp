let s:Promise = vital#lamp#import('Async.Promise')
let s:Tooltip = lamp#view#tooltip#import()
let s:tooltip = s:Tooltip.new({})

"
" for test.
"
function! lamp#feature#hover#test_context(context) abort
  let a:context.tooltip = s:tooltip
endfunction

"
" lamp#feature#hover#init
"
function! lamp#feature#hover#init() abort
  augroup lamp#feature#hover
    autocmd!
    autocmd CursorMoved * call s:close()
  augroup END
endfunction

"
" lamp#feature#hover#do
"
function! lamp#feature#hover#do() abort
  if s:tooltip.is_showing()
    call s:tooltip.enter()
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
  call s:Promise.all(l:promises).then({ res -> s:on_response(l:bufnr, res) })
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

  call s:tooltip.show_at_cursor(l:contents)
endfunction

"
" s:close
"
function! s:close() abort
  let l:fn = {}
  function! l:fn.debounce() abort
    if s:tooltip.is_showing()
      if winnr() != s:tooltip.winnr()
        call s:tooltip.hide()
      endif
    endif
  endfunction
  call lamp#debounce('lamp#view#hover:close', l:fn.debounce, 100)
endfunction

