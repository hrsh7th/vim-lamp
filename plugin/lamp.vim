if exists('g:loaded_lamp')
  finish
endif
let g:loaded_lamp = v:true

"
" initialize features
"
for s:feature in glob(lamp#config('root') . '/autoload/lamp/feature/*.vim', v:false, v:true)
  try
    call lamp#feature#{fnamemodify(s:feature, ':t:r')}#init()
  catch /.*/
    echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
  endtry
endfor

"
" command
"
command! -nargs=1 LampDefinition          call lamp#feature#definition#do('<args>')
command! -nargs=1 LampTypeDefinition      call lamp#feature#type_definition#do('<args>')
command! -nargs=1 LampDeclaration         call lamp#feature#declaration#do('<args>')
command! -nargs=1 LampImplementation      call lamp#feature#declaration#do('<args>')
command! LampRename                       call lamp#feature#rename#do()
command! LampHover                        call lamp#feature#hover#do()
command! LampDocumentHighlight            call lamp#feature#document_highlight#do()
command! LampDocumentHighlightClear       call lamp#feature#document_highlight#clear()
command! LampFormatting                   call lamp#feature#formatting#do()
command! LampRangeFormatting              call lamp#feature#range_formatting#do()
command! LampReferences                   call lamp#feature#references#do(v:false)
command! LampReferencesIncludeDeclaration call lamp#feature#references#do(v:true)
command! -range -nargs=* -complete=customlist,lamp#feature#code_action#complete
      \  LampCodeAction                   call lamp#feature#code_action#do(<range>, '<args>')

"
" mappings
"
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
nnoremap <silent><Plug>(lamp-code-action)                    :<C-u>call lamp#feature#code_action#do(0, '')<CR>
vnoremap <silent><Plug>(lamp-code-action)                    :<C-u>call lamp#feature#code_action#do(2, '')<CR>

"
" events
"
augroup lamp
  autocmd!
  autocmd BufWinEnter,FileType * call <SID>on_text_document_did_open()
  autocmd TextChanged,InsertLeave * call <SID>on_text_document_did_change()
  autocmd BufWipeout,BufDelete,BufUnload * call <SID>on_text_document_did_close()
  autocmd VimLeavePre * call <SID>on_vim_leave_pre()
augroup END

"
" on_text_document_did_open
"
function! s:on_text_document_did_open() abort
  let l:bufnr = bufnr('%')
  let l:servers = lamp#server#registry#find_by_filetype(getbufvar(l:bufnr, '&filetype'))

  if !empty(l:servers)
    doautocmd User lamp#text_document_did_open
  endif

  let l:ctx = {}
  function! l:ctx.callback(bufnr, servers) abort
    for l:server in a:servers
      call l:server.ensure_document(a:bufnr)
    endfor
  endfunction
  call lamp#debounce(
        \   's:on_text_document_did_open:' . l:bufnr,
        \   { -> l:ctx.callback(l:bufnr, l:servers) },
        \   100
        \ )
endfunction

"
" on_text_document_did_change
"
function! s:on_text_document_did_change() abort
  let l:ctx = {}
  function! l:ctx.callback(bufnr) abort
    for l:server in lamp#server#registry#find_by_filetype(getbufvar(a:bufnr, '&filetype'))
      call l:server.ensure_document(a:bufnr)
    endfor
  endfunction

  let l:bufnr = bufnr('%')
  call lamp#debounce(
        \   's:on_text_document_did_change:' . l:bufnr,
        \   { -> l:ctx.callback(l:bufnr) },
        \   100
        \ )
endfunction

"
" on_text_document_did_close
"
function! s:on_text_document_did_close() abort
  let l:ctx = {}
  function! l:ctx.callback(bufnr) abort
    if !lamp#state('exiting')
      for l:server in lamp#server#registry#all()
        let l:bufnrs = map(values(l:server.documents), { k, v -> v.bufnr })
        if index(l:bufnrs, a:bufnr) >= 0
          call l:server.ensure_document(a:bufnr)
        endif
      endfor
    endif
  endfunction

  let l:bufnr = str2nr(expand('<abuf>'))
  call lamp#debounce(
        \   's:on_text_document_did_close:' . l:bufnr,
        \   { -> l:ctx.callback(l:bufnr) },
        \   100
        \ )
endfunction

"
" on_vim_leave_pre
"
function! s:on_vim_leave_pre() abort
  call lamp#state('exiting', v:true)

  for l:server in lamp#server#registry#all()
    try
      call lamp#sync(l:server.exit(), 200)
    catch /.*/
      call lamp#log('[ERROR]', { 'exception': v:exception, 'throwpoint': v:throwpoint })
    endtry
  endfor
endfunction

doautocmd User lamp#initialized

call lamp#log('')
call lamp#log('[STARTED]', strftime('%Y-%m-%d %H:%M:%S'))

