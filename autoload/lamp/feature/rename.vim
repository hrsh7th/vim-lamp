let s:Promise = vital#lamp#import('Async.Promise')

"
" for test.
"
let s:test_context = {}
function! lamp#feature#rename#test_context(test_context) abort
  let s:test_context = a:test_context
endfunction

"
" lamp#feature#rename#init
"
function! lamp#feature#rename#init() abort
  " noop
endfunction

"
" lamp#feature#rename#init
"
function! lamp#feature#rename#do() abort
  let l:bufnr = bufnr('%')
  let l:servers = lamp#server#registry#find_by_filetype(getbufvar(l:bufnr, '&filetype'))
  let l:servers = filter(l:servers, { k, v -> v.supports('capabilities.renameProvider') })
  if empty(l:servers)
    return
  endif
  let l:server = l:servers[0]

  let l:p = s:Promise.resolve()
  let l:p = l:p.then({ -> s:request_prepare(l:bufnr, l:server) })
  let l:p = l:p.then({ target -> s:request_rename(l:bufnr, l:server, target) })
  let l:p = l:p.then({ edits -> s:edits(edits) })
  let l:p = l:p.catch(lamp#rescue({}))
endfunction

"
" s:request_prepare
"
function! s:request_prepare(bufnr, server) abort
  if a:server.supports('capabilities.renameProvider.prepareProvider')
    return a:server.request('textDocument/prepareRename', {
          \   'textDocument': lamp#protocol#document#identifier(a:bufnr),
          \   'position': lamp#protocol#position#get()
          \ })
  endif

  return {
        \   'range': lamp#protocol#range#current_word(),
        \   'placeholder': expand('<cword>')
        \ }
endfunction

"
" s:request_rename
"
function! s:request_rename(bufnr, server, target) abort
  if !has_key(s:test_context, 'new_name')
    let l:new_name = input('New name: ', get(a:target, 'placeholder', ''))
    if l:new_name ==# '' || l:new_name ==# get(a:target, 'placeholder', '')
      return
    endif
  else
    let l:new_name = s:test_context.new_name
  endif

  return a:server.request('textDocument/rename', {
        \   'textDocument': lamp#protocol#document#identifier(a:bufnr),
        \   'position': lamp#protocol#position#get(),
        \   'newName': l:new_name
        \ })
endfunction

"
" s:edits
"
function! s:edits(edits) abort
  if empty(a:edits)
    return
  endif
  call lamp#view#edit#apply_workspace(a:edits)

  let l:locations = []
  for [l:uri, l:edits] in items(lamp#view#edit#normalize_workspace_edit(a:edits))
    for l:edit in l:edits
      let l:path = lamp#protocol#document#decode_uri(l:uri) 
      call add(l:locations, {
            \   'bufnr': bufnr(l:path),
            \   'filename': bufname(l:path),
            \   'lnum': l:edit.range.start.line + 1,
            \   'col': l:edit.range.start.character + 1,
            \ })
    endfor
  endfor
  call lamp#config('option.on_renamed')(l:locations)
endfunction

