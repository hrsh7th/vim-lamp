if exists('g:loaded_lamp')
  finish
endif
let g:loaded_lamp = v:true

if (!has('nvim') && v:version < 801) || (has('nvim') && !has('nvim-0.4.0'))
  echomsg 'vim-lamp is supported only vim-8.1(later) or nvim-0.4.0(later)'
  finish
endif

" initialize features.
for s:feature in glob(lamp#config('root') . '/autoload/lamp/feature/*.vim', v:false, v:true)
  try
    call lamp#feature#{fnamemodify(s:feature, ':t:r')}#init()
  catch /.*/
    echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
  endtry
endfor

nnoremap <silent><Plug>(lamp-definition)                     :<C-u>call lamp#feature#definition#do('edit')<CR>
nnoremap <silent><Plug>(lamp-definition-split)               :<C-u>call lamp#feature#definition#do('split')<CR>
nnoremap <silent><Plug>(lamp-definition-vsplit)              :<C-u>call lamp#feature#definition#do('vsplit')<CR>
nnoremap <silent><Plug>(lamp-type-definition)                :<C-u>call lamp#feature#type_definition#do('edit')<CR>
nnoremap <silent><Plug>(lamp-type-definition-split)          :<C-u>call lamp#feature#type_definition#do('split')<CR>
nnoremap <silent><Plug>(lamp-type-definition-vsplit)         :<C-u>call lamp#feature#type_definition#do('vsplit')<CR>
nnoremap <silent><Plug>(lamp-declaration)                    :<C-u>call lamp#feature#declaration#do('edit')<CR>
nnoremap <silent><Plug>(lamp-declaration-split)              :<C-u>call lamp#feature#declaration#do('split')<CR>
nnoremap <silent><Plug>(lamp-declaration-vsplit)             :<C-u>call lamp#feature#declaration#do('vsplit')<CR>
nnoremap <silent><Plug>(lamp-implementation)                 :<C-u>call lamp#feature#implementation#do('edit')<CR>
nnoremap <silent><Plug>(lamp-implementation-split)           :<C-u>call lamp#feature#implementation#do('split')<CR>
nnoremap <silent><Plug>(lamp-implementation-vsplit)          :<C-u>call lamp#feature#implementation#do('vsplit')<CR>
nnoremap <silent><Plug>(lamp-rename)                         :<C-u>call lamp#feature#rename#do()<CR>
nnoremap <silent><Plug>(lamp-hover)                          :<C-u>call lamp#feature#hover#do()<CR>
nnoremap <silent><Plug>(lamp-document-highlight)             :<C-u>call lamp#feature#document_highlight#do()<CR>
nnoremap <silent><Plug>(lamp-document-highlight-clear)       :<C-u>call lamp#feature#document_highlight#clear()<CR>
nnoremap <silent><Plug>(lamp-references)                     :<C-u>call lamp#feature#references#do(v:false)<CR>
nnoremap <silent><Plug>(lamp-references-include-declaration) :<C-u>call lamp#feature#references#do(v:true)<CR>
nnoremap <silent><Plug>(lamp-formatting)                     :<C-u>call lamp#feature#formatting#do()<CR>
vnoremap <silent><Plug>(lamp-range-formatting)               :<C-u>call lamp#feature#range_formatting#do()<CR>
nnoremap <silent><Plug>(lamp-code-action)                    :<C-u>call lamp#feature#code_action#do(0)<CR>
vnoremap <silent><Plug>(lamp-code-action)                    :<C-u>call lamp#feature#code_action#do(2)<CR>

augroup lamp
  autocmd!
  autocmd BufWinEnter,FileType * call <SID>on_text_document_did_open()
  autocmd TextChanged,InsertLeave * call <SID>on_text_document_did_change()
  autocmd BufWipeout,BufDelete,BufUnload * call <SID>on_text_document_did_close()
augroup END

"
" textDocument/didOpen
"
function! s:on_text_document_did_open() abort
  let l:bufnr = bufnr('%')
  let l:servers = lamp#server#registry#find_by_filetype(getbufvar(l:bufnr, '&filetype'))

  if !empty(l:servers)
    doautocmd User lamp#text_document_did_open
  endif

  let l:fn = {}
  function! l:fn.debounce(bufnr, servers) abort
    for l:server in a:servers
      call l:server.ensure_document(a:bufnr)
    endfor
  endfunction
  call lamp#debounce('s:on_text_document_did_open:' . l:bufnr, { -> l:fn.debounce(l:bufnr, l:servers) }, 100)
endfunction

"
" textDocument/didChange
"
function! s:on_text_document_did_change() abort
  let l:fn = {}
  function! l:fn.debounce(bufnr) abort
    for l:server in lamp#server#registry#find_by_filetype(getbufvar(a:bufnr, '&filetype'))
      call l:server.ensure_document(a:bufnr)
    endfor
  endfunction

  let l:bufnr = bufnr('%')
  call lamp#debounce('s:on_text_document_did_change:' . l:bufnr, { -> l:fn.debounce(l:bufnr) }, 100)
endfunction

"
" textDocument/didClose
"
function! s:on_text_document_did_close() abort
  let l:fn = {}
  function! l:fn.debounce(bufnr) abort
    for l:server in lamp#server#registry#find_by_filetype(getbufvar(a:bufnr, '&filetype'))
      call l:server.ensure_document(a:bufnr)
    endfor
  endfunction

  let l:bufnr = bufnr('%')
  call lamp#debounce('s:on_text_document_did_close:' . l:bufnr, { -> l:fn.debounce(l:bufnr) }, 100)
endfunction

doautocmd User lamp#initialized

