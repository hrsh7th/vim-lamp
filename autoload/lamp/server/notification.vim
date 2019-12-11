"
" lamp#server#notification#on
"
function! lamp#server#notification#on(server, notification) abort
  if a:notification.method ==# 'textDocument/publishDiagnostics'
    call s:text_document_publish_diagnostics(a:server, a:notification)
  elseif a:notification.method ==# 'workspace/applyEdit'
    call s:workspace_apply_edit(a:server, a:notification)
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
  if len(l:doc.diagnostics) == 0 && len(a:notification.params.diagnostics) == 0
    return
  endif

  call l:doc.set_diagnostics(a:notification.params.diagnostics)
  call lamp#feature#diagnostic#update()
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

