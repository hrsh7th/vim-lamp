let s:workspace = {
\   'config': {},
\   'folders': []
\ }

"
" lamp#feature#workspace#init
"
function! lamp#feature#workspace#init() abort
  " noop
endfunction

"
" lamp#feature#workspace#get_config
"
function! lamp#feature#workspace#get_config() abort
  return copy(s:workspace.config)
endfunction

"
" lamp#feature#workspace#get_folders
"
function! lamp#feature#workspace#get_folders() abort
  return s:workspace.folders
endfunction

"
" lamp#feature#workspace#update
"
function! lamp#feature#workspace#update(server, bufnr) abort
  if index(a:server.filetypes, getbufvar(a:bufnr, '&filetype', '')) == -1
    return
  endif

  let l:uri = lamp#protocol#document#encode_uri(a:server.get_root_uri(a:bufnr))
  if l:uri ==# ''
    return
  endif

  " Find workspace folder.
  let l:folder = v:null
  for l:folder in s:workspace.folders
    if l:folder.uri ==# l:uri
      break
    endif
    let l:folder = v:null
  endfor

  " Add new workspace folder automatically.
  if empty(l:folder)
    let l:folder = {
    \   'name': printf('[LAMP] Automatic workspace folder: %s', l:uri),
    \   'uri': l:uri,
    \ }
    let s:workspace.folders += [l:folder]

    " Send folder changes if server supported.
    if a:server.capability.is_workspace_folder_supported()
      call a:server.notify('workspace/didChangeWorkspaceFolders', {
      \   'event': {
      \     'added': [l:folder],
      \     'removed': [],
      \   }
      \ })
    endif
  endif
endfunction

"
" lamp#feature#workspace#configure
"
function! lamp#feature#workspace#configure(config) abort
  let s:workspace.config = lamp#merge(s:workspace.config, a:config)
  let l:servers = lamp#server#registry#all()
  let l:servers = filter(l:servers, { _, server -> !empty(server.state.initialized) })
  call map(l:servers, { _, server ->
  \   server.notify('workspace/didChangeConfiguration', {
  \     'settings': s:workspace.config
  \   })
  \ })
endfunction

