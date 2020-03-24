let s:Diagnostics = lamp#server#diagnostics#import()

"
" lamp#server#notification#on
"
function! lamp#server#notification#on(server, notification) abort
  if a:notification.method ==# 'textDocument/publishDiagnostics'
    call s:text_document_publish_diagnostics(a:server, a:notification)
  elseif a:notification.method ==# 'workspace/workspaceFolders'
    call s:workspace_workspace_folders(a:server, a:notification)
  elseif a:notification.method ==# 'workspace/configuration'
    call s:workspace_configuration(a:server, a:notification)
  elseif a:notification.method ==# 'workspace/applyEdit'
    call s:workspace_apply_edit(a:server, a:notification)
  elseif a:notification.method ==# 'window/showMessage'
    call s:window_show_message(a:server, a:notification)
  elseif a:notification.method ==# 'window/showMessageRequest'
    call s:window_show_message_request(a:server, a:notification)
  elseif a:notification.method ==# 'window/logMessage'
    call s:window_log_message(a:server, a:notification)
  elseif a:notification.method ==# 'telemetry/event'
    call s:telemetry_event(a:server, a:notification)
  else
    call lamp#log('[UNHANDLED]', a:notification.method, get(a:notification, 'params', v:null))
    if has_key(a:notification, 'id')
      call a:server.response(a:notification.id, {
      \   'error': {
      \     'code': -32601,
      \     'message': 'MethodNotFound',
      \   }
      \ })
    endif
  endif
endfunction

"
" text_document_publish_diagnostics
"
function! s:text_document_publish_diagnostics(server, notification) abort
  if !has_key(a:server.diagnostics, a:notification.params.uri)
    let a:server.diagnostics[a:notification.params.uri] = s:Diagnostics.new({
    \   'uri': a:notification.params.uri,
    \   'diagnostics': a:notification.params.diagnostics,
    \ })
  endif
  call a:server.diagnostics[a:notification.params.uri].set(a:notification.params.diagnostics)

  call lamp#feature#diagnostic#update(a:server, a:server.diagnostics[a:notification.params.uri])
endfunction

"
" workspace_workspace_folders
"
function! s:workspace_workspace_folders(server, notification) abort
  call a:server.response(a:notification.id, {
  \   'result': lamp#feature#workspace#get_folders()
  \ })
endfunction

"
" workspace_configuration
"
function! s:workspace_configuration(server, notification) abort
  let l:config = lamp#feature#workspace#get_config()
  call a:server.response(a:notification.id, {
  \   'result': map(copy(a:notification.params.items), { _, item ->
  \     lamp#get(l:config, item.section, v:null)
  \   })
  \ })
endfunction

"
" workspace_apply_edit
"
function! s:workspace_apply_edit(server, notification) abort
  let l:workspace_edit = lamp#view#edit#normalize_workspace_edit(a:notification.params.edit)
  call lamp#view#edit#apply_workspace(l:workspace_edit)
  call a:server.response(a:notification.id, {
        \   'result': {
        \     'applied': v:true
        \   }
        \ })
endfunction

"
" window_show_message_request
"
function! s:window_show_message_request(server, notification) abort
  if has_key(a:notification.params, 'actions') && type(a:notification.params.actions) == type([])
    let l:index = lamp#view#input#select(
          \   a:notification.params.message,
          \   map(copy(a:notification.params.actions), { _, action -> action.title })
          \ )
    if l:index >= 0
      call a:server.response(a:notification.id, a:notification.params.actions[l:index])
    endif
  else
    call s:window_show_message(a:server, a:notification)
  endif
endfunction

"
" window_show_message
"
function! s:window_show_message(server, notification) abort
  if a:notification.params.type == 1
    echohl ErrorMsg
  elseif a:notification.params.type == 2
    echohl WarningMsg
  elseif a:notification.params.type == 4
    echohl NonText
  endif
  echomsg join([a:server.name, a:notification.params.message], "\t")
  echohl None
endfunction

"
" window_log_message
"
function! s:window_log_message(server, notification) abort
  " call lamp#log('[window/logMessage]', a:server.name, a:notification.params)
endfunction

"
" telemetry_event
"
function! s:telemetry_event(server, notification) abort
  call lamp#log('[telemetry/event]', a:server.name, a:notification.params)
endfunction

