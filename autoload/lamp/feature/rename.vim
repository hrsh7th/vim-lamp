let s:Position = vital#lamp#import('LSP.Position')
let s:Promise = vital#lamp#import('Async.Promise')

"
" for test.
"
let s:test = {}
function! lamp#feature#rename#test(test) abort
  let s:test= a:test
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
    call lamp#view#notice#add({ 'lines': ['`Rename`: has no `Rename` capability.'] })
    return
  endif
  let l:server = l:servers[0]

  let l:p = s:Promise.resolve()
  let l:p = l:p.then({ -> s:request_prepare(l:bufnr, l:server) })
  let l:p = l:p.then({ target -> s:request_rename(l:bufnr, l:server, target) })
  let l:p = l:p.then({ edits -> s:edits(edits) })
  let l:p = l:p.catch(lamp#rescue())
endfunction

"
" s:request_prepare
"
function! s:request_prepare(bufnr, server) abort
  if a:server.supports('capabilities.renameProvider.prepareProvider')
    return a:server.request('textDocument/prepareRename', {
          \   'textDocument': lamp#protocol#document#identifier(a:bufnr),
          \   'position': s:Position.cursor()
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
  if !has_key(s:test, 'new_name')
    let l:new_name = input('New name: ', get(a:target, 'placeholder', ''))
    if l:new_name ==# '' || l:new_name ==# get(a:target, 'placeholder', '')
      return
    endif
  else
    let l:new_name = s:test.new_name
  endif

  return a:server.request('textDocument/rename', {
        \   'textDocument': lamp#protocol#document#identifier(a:bufnr),
        \   'position': s:Position.cursor(),
        \   'newName': l:new_name
        \ })
endfunction

"
" s:edits
"
function! s:edits(workspace_edit) abort
  if empty(a:workspace_edit)
    return
  endif
  let l:workspace_edit = lamp#view#edit#normalize_workspace_edit(a:workspace_edit)

  call lamp#view#edit#apply_workspace(l:workspace_edit)

  call lamp#view#notice#add({ 'lines': ['`Rename`: renamed.'] })

  " current buffer only.
  let l:current_uri = lamp#protocol#document#encode_uri(bufnr('%'))
  if keys(l:workspace_edit) == [l:current_uri]
    return
  endif

  " multiple files renamed.
  let l:locations = []
  for [l:uri, l:edits] in items(l:workspace_edit)
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
  call lamp#view#location#handle('', {}, l:locations, {
        \   'always_listing': v:true,
        \   'no_fallback': v:true
        \ })
endfunction

