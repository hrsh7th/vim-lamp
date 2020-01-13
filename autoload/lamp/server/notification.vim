"
" lamp#server#notification#on
"
function! lamp#server#notification#on(server, notification) abort
  if a:notification.method ==# 'textDocument/publishDiagnostics'
    call s:text_document_publish_diagnostics(a:server, a:notification)
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
  endif
endfunction

"
" text_document_publish_diagnostics
"
function! s:text_document_publish_diagnostics(server, notification) abort
  if !has_key(a:server.documents, a:notification.params.uri)
    return
  endif

  let l:doc = a:server.documents[a:notification.params.uri]
  call l:doc.set_diagnostics(a:notification.params.diagnostics)
  call lamp#feature#diagnostic#update(a:server, l:doc)
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

