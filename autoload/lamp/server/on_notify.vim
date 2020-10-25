let s:Diagnostics = lamp#server#diagnostics#import()

"
" lamp#server#on_notify#on
"
function! lamp#server#on_notify#on(server, notification) abort
  if a:notification.method ==# 'textDocument/publishDiagnostics'
    call s:text_document_publish_diagnostics(a:server, a:notification)
  elseif a:notification.method ==# 'window/showMessage'
    call s:window_show_message(a:server, a:notification)
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
  let l:document = get(a:server.documents, a:notification.params.uri, {})
  if !has_key(a:server.diagnostics, a:notification.params.uri)
    let a:server.diagnostics[a:notification.params.uri] = s:Diagnostics.new({
    \   'uri': a:notification.params.uri,
    \   'diagnostics': a:notification.params.diagnostics,
    \   'document_version': get(l:document, 'version', -1),
    \ })
  endif
  call a:server.diagnostics[a:notification.params.uri].set(a:notification.params.diagnostics, get(l:document, 'version', -1))

  call lamp#feature#diagnostic#update(a:server, a:server.diagnostics[a:notification.params.uri])
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

