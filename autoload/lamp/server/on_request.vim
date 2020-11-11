"
" lamp#server#on_request#on
"
function! lamp#server#on_request#on(server, request) abort
  if a:request.method ==# 'workspace/workspaceFolders'
    call s:workspace_workspace_folders(a:server, a:request)
  elseif a:request.method ==# 'workspace/configuration'
    call s:workspace_configuration(a:server, a:request)
  elseif a:request.method ==# 'workspace/applyEdit'
    call s:workspace_apply_edit(a:server, a:request)
  elseif a:request.method ==# 'window/showMessageRequest'
    call s:window_show_message_request(a:server, a:request)
  elseif a:request.method ==# 'client/registerCapability'
    call s:client_register_capability(a:server, a:request)
  elseif a:request.method ==# 'client/unregisterCapability'
    call s:client_unregister_capability(a:server, a:request)
  else
    call lamp#log('[UNHANDLED]', a:request.method, get(a:request, 'params', v:null))
    if has_key(a:request, 'id')
      call a:server.response(a:request.id, {
      \   'error': {
      \     'code': -32601,
      \     'message': 'MethodNotFound',
      \   }
      \ })
    endif
  endif
endfunction

"
" client_register_capability
"
function! s:client_register_capability(server, request) abort
  call a:server.capabilities.register(a:request.params)
  call a:server.response(a:request.id, {
  \   'result': v:null
  \ })
endfunction

"
" client_unregister_capability
"
function! s:client_unregister_capability(server, request) abort
  call a:server.capabilities.unregister(a:request.params.id)
  call a:server.response(a:request.id, {
  \   'result': v:null
  \ })
endfunction

"
" workspace_workspace_folders
"
function! s:workspace_workspace_folders(server, request) abort
  call a:server.response(a:request.id, {
  \   'result': lamp#feature#workspace#get_folders()
  \ })
endfunction

"
" workspace_configuration
"
function! s:workspace_configuration(server, request) abort
  let l:config = lamp#feature#workspace#get_config()
  call a:server.response(a:request.id, {
  \   'result': map(copy(a:request.params.items), { _, item ->
  \     lamp#get(l:config, item.section, v:null)
  \   })
  \ })
endfunction

"
" workspace_apply_edit
"
function! s:workspace_apply_edit(server, request) abort
  let l:workspace_edit = lamp#view#edit#normalize_workspace_edit(a:request.params.edit)
  call lamp#view#edit#apply_workspace(l:workspace_edit)
  call a:server.response(a:request.id, {
        \   'result': {
        \     'applied': v:true
        \   }
        \ })
endfunction

"
" window_show_message_request
"
function! s:window_show_message_request(server, request) abort
  if has_key(a:request.params, 'actions') && type(a:request.params.actions) == type([])
    let l:index = lamp#view#input#select(
          \   a:request.params.message,
          \   map(copy(a:request.params.actions), { _, action -> action.title })
          \ )
    if l:index >= 0
      call a:server.response(a:request.id, a:request.params.actions[l:index])
    endif
  else
    if a:request.params.type == 1
      echohl ErrorMsg
    elseif a:request.params.type == 2
      echohl WarningMsg
    elseif a:request.params.type == 4
      echohl NonText
    endif
    echomsg join([a:server.name, a:request.params.message], "\t")
    echohl None
  endif
endfunction

