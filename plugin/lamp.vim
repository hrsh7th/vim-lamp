if exists('g:loaded_lamp')
  finish
endif
let g:loaded_lamp = v:true

let s:Promise = vital#lamp#import('Async.Promise')

augroup lamp#silent
  autocmd!
  autocmd User lamp#text_document_did_open silent
  autocmd User lamp#initialized silent
  autocmd User lamp#server#exited silent
  autocmd User lamp#server#initialized silent
augroup END

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
command! LampFormatting                   call lamp#feature#formatting#do({ 'sync': v:false })
command! LampFormattingSync               call lamp#feature#formatting#do({ 'sync': v:true })
command! LampRangeFormatting              call lamp#feature#range_formatting#do()
command! LampReferences                   call lamp#feature#references#do(v:false)
command! LampReferencesIncludeDeclaration call lamp#feature#references#do(v:true)
command! LampSelectionRangeExpand         call lamp#feature#selection_range#do(+1)
command! LampSelectionRangeCollapse       call lamp#feature#selection_range#do(-1)
command! -range -nargs=* -complete=customlist,lamp#feature#code_action#complete
      \  LampCodeAction                   call lamp#feature#code_action#do({ 'range': <range> != 0, 'query': '<args>', 'sync': v:false })
command! -range -nargs=* -complete=customlist,lamp#feature#code_action#complete
      \  LampCodeActionSync               call lamp#feature#code_action#do({ 'range': <range> != 0, 'query': '<args>', 'sync': v:true })

"
" events
"
augroup lamp
  autocmd!
  autocmd BufEnter,BufWinEnter,FileType * call <SID>on_text_document_did_open()
  if lamp#view#diff#import().type ==# 'compat'
    autocmd BufWritePost,TextChanged,InsertLeave * call <SID>on_text_document_did_change()
  else
    autocmd BufWritePost,TextChanged,TextChangedI,TextChangedP * call <SID>on_text_document_did_change()
  endif
  autocmd BufWipeout,BufDelete,BufUnload * call <SID>on_text_document_did_close()
  autocmd VimLeave * call <SID>on_vim_leave_pre()
augroup END

"
" on_text_document_did_open
"
function! s:on_text_document_did_open() abort
  let l:bufnr = bufnr('%')
  let l:servers = lamp#server#registry#find_by_filetype(getbufvar(l:bufnr, '&filetype'))

  if !empty(l:servers)
    call s:initialize_buffer()
  endif

  let l:ctx = {}
  function! l:ctx.callback(bufnr, servers) abort
    for l:server in a:servers
      call l:server.initialize(a:bufnr).then({ -> l:server.ensure_document(a:bufnr) })
    endfor
  endfunction
  call lamp#debounce(
        \   's:on_text_document_did_open:' . l:bufnr,
        \   { -> l:ctx.callback(l:bufnr, l:servers) },
        \   200
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
        \   200
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
        \   200
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
  call lamp#log('[FINISHED]')
endfunction

"
" initialize_buffer
"
function! s:initialize_buffer() abort
  if has_key(b:, 'lamp_text_document_did_open')
    return
  endif
  let b:lamp_text_document_did_open = v:true

  call lamp#log('[LOG]', 's:initialize_buffer', bufnr('%'))

  for s:feature in glob(lamp#config('global.root') . '/autoload/lamp/feature/*.vim', v:false, v:true)
    try
      call lamp#feature#{fnamemodify(s:feature, ':t:r')}#init()
    catch /.*/
      echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
    endtry
  endfor
  doautocmd User lamp#text_document_did_open
endfunction

doautocmd User lamp#initialized

call lamp#log_clear()
call lamp#log('')
call lamp#log('[STARTED]', strftime('%Y-%m-%d %H:%M:%S'))

