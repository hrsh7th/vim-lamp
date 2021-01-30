let s:Promise = vital#lamp#import('Async.Promise')
let s:Connection = vital#lamp#import('VS.RPC.JSON.Connection')
let s:Document = lamp#server#document#import()
let s:Capabilities = lamp#server#capabilities#import()
let s:Diagnostics = lamp#server#diagnostics#import()

"
" lamp#server#import
"
function! lamp#server#import() abort
  return s:Server
endfunction

let s:Server = {}

"
" new
"
function! s:Server.new(name, option) abort
  let l:server = extend(deepcopy(s:Server), {
  \   'name': a:name,
  \   'cmd': a:option.command,
  \   'rpc': s:Connection.new(),
  \   'filetypes': a:option.filetypes,
  \   'root_uri': get(a:option, 'root_uri', { bufnr -> '' }),
  \   'root_uri_cache': {},
  \   'initialization_options': get(a:option, 'initialization_options', { -> {} }),
  \   'trace': get(a:option, 'trace', 'off'),
  \   'documents': {},
  \   'diagnostics': {},
  \   'capabilities': s:Capabilities.new(get(a:option, 'capabilities', {})),
  \   'initialized': v:false,
  \   'state': {
  \     'started': v:false,
  \     'initialized': v:null,
  \     'exited': v:false,
  \   },
  \ })
  return l:server
endfunction

"
" start
"
function! s:Server.start() abort
  if !self.state.started && !self.state.exited
    let self.state.started = v:true
    for [l:method, l:Callback] in items({
    \   'workspace/workspaceFolders': self.on_workspace_folders,
    \   'workspace/configuration': self.on_configuration,
    \   'workspace/applyEdit': self.on_apply_edit,
    \   'window/showMessageRequest': self.on_show_message_request,
    \   'client/registerCapability': self.on_register_capability,
    \   'client/unregisterCapability': self.on_unregister_capability,
    \ })
      call self.rpc.on_request(l:method, function(l:Callback, [], self))
    endfor
    for [l:method, l:Callback] in items({
    \   'textDocument/publishDiagnostics': self.on_publish_diagnostics,
    \   'window/showMessage': self.on_show_message,
    \ })
      call self.rpc.on_notification(l:method, function(l:Callback, [], self))
    endfor
    call self.rpc.start({
    \   'cmd': self.cmd,
    \   'cwd': self.root_uri(bufnr('%'))
    \ })
  endif
  return s:Promise.resolve()
endfunction

"
" stop
"
function! s:Server.stop() abort
  let l:p = s:Promise.resolve()
  if self.state.started
    if !empty(self.state.initialized)
      let l:p = l:p.then({ -> self.rpc.request('shutdown', v:null) })
      let l:p = l:p.then({ -> self.rpc.notify('exit') })
      let l:p = l:p.then({ -> execute('doautocmd <nomodeline> User lamp#server#exited') })
    endif
    let l:p = l:p.then({ -> self.rpc.stop() })
    let l:p = l:p.catch(lamp#rescue())
  endif
  let self.state.initialized = v:null
  let self.state.started = v:false
  return s:Promise.race([l:p, s:Promise.new({ resolve -> timer_start(100, resolve) })])
endfunction

"
" exit
"
function! s:Server.exit() abort
  let self.state.exited = v:true
  return self.stop()
endfunction

"
" is_running
"
function! s:Server.is_running() abort
  return self.rpc.is_running()
endfunction

"
" get_root_uri
"
function! s:Server.get_root_uri(bufnr) abort
  if !has_key(self.root_uri_cache, a:bufnr)
    let self.root_uri_cache[a:bufnr] = self.root_uri(a:bufnr)
  endif
  return self.root_uri_cache[a:bufnr]
endfunction

"
" initialize
"
function! s:Server.initialize(bufnr) abort
  try
    call self.start()
  catch /.*/
    echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
    return s:Promise.resolve()
  endtry

  if !empty(self.state.initialized)
    return self.state.initialized
  endif

  let l:ctx = {}
  function! l:ctx.callback(bufnr, response) abort dict
    call self.capabilities.merge(a:response)
    call self.rpc.notify('initialized', {})

    call self.rpc.notify('workspace/didChangeConfiguration', {
    \   'settings': lamp#feature#workspace#get_config()
    \ })
    call self.rpc.notify('workspace/didChangeWorkspaceFolders', {
    \   'event': {
    \     'added': lamp#feature#workspace#get_folders(),
    \     'removed': [],
    \   }
    \ })

    let self.initialized = v:true
    doautocmd <nomodeline> User lamp#server#initialized

    call lamp#view#notice#add({ 'lines': [printf('`%s` initialized', self.name)] })

    return a:response
  endfunction

  let l:root_uri = self.get_root_uri(a:bufnr)
  if l:root_uri ==# ''
    let l:root_uri = lamp#fnamemodify(bufname('%'), ':p:h')
  endif

  call lamp#feature#workspace#update(self, a:bufnr)
  let self.state.initialized = self.rpc.request('initialize', {
  \   'processId': getpid(),
  \   'clientInfo': {
  \     'name': 'lamp',
  \     'version': '0.1'
  \   },
  \   'rootPath': l:root_uri,
  \   'rootUri': lamp#protocol#document#encode_uri(l:root_uri),
  \   'initializationOptions': self.initialization_options(),
  \   'capabilities': lamp#server#capabilities#get_default_capabilities(),
  \   'trace': self.trace,
  \   'locale': 'en',
  \   'workspaceFolders': lamp#feature#workspace#get_folders(),
  \ }).then(function(l:ctx.callback, [a:bufnr], self))
  return self.state.initialized
endfunction

"
" request.
"
function! s:Server.request(method, params, ...) abort
  return self.ensure_document_from_params(a:params).then({ -> self.rpc.request(a:method, a:params) })
endfunction

"
" notify.
"
function! s:Server.notify(method, params) abort
  call self.ensure_document_from_params(a:params).then({ -> self.rpc.notify(a:method, a:params) })
endfunction

"
" supports.
"
function! s:Server.supports(path) abort
  return self.capabilities.supports(a:path)
endfunction

"
" ensure_document_from_params.
"
function! s:Server.ensure_document_from_params(params) abort
  if has_key(a:params, 'textDocument') && has_key(a:params.textDocument, 'uri')
    return self.ensure_document(bufnr(lamp#protocol#document#decode_uri(a:params.textDocument.uri)))
  endif
  return s:Promise.resolve()
endfunction

"
" ensure_document.
"
function! s:Server.ensure_document(bufnr) abort
  return self.initialize(a:bufnr).then({ -> [
  \   self.detect_workspace(a:bufnr),
  \   self.open_document(a:bufnr),
  \   self.sync_document(a:bufnr),
  \ ] })
endfunction

"
" detect_workspace.
"
function! s:Server.detect_workspace(bufnr) abort
  call lamp#feature#workspace#update(self, a:bufnr)
endfunction

"
" open_document.
"
function! s:Server.open_document(bufnr) abort
  let l:uri = lamp#protocol#document#encode_uri(bufname(a:bufnr))
  if has_key(self.documents, l:uri)
    return
  endif

  " create document.
  let self.documents[l:uri] = s:Document.new(a:bufnr)
  call self.detect_workspace(a:bufnr)
  call self.rpc.notify('textDocument/didOpen', {
  \   'textDocument': lamp#protocol#document#item(a:bufnr),
  \ })
endfunction

"
" sync_document.
"
function! s:Server.sync_document(bufnr) abort
  let l:uri = lamp#protocol#document#encode_uri(bufname(a:bufnr))
  if !has_key(self.documents, l:uri)
    return
  endif

  let l:doc = self.documents[l:uri]
  if !l:doc.out_of_date()
    return
  endif

  let l:sync_kind = self.capabilities.get_text_document_sync_kind()

  " full sync.
  if l:sync_kind == 1
    call l:doc.sync()
    call self.detect_workspace(a:bufnr)
    call self.rpc.notify('textDocument/didChange', {
    \   'textDocument': lamp#protocol#document#versioned_identifier(a:bufnr),
    \   'contentChanges': [{ 'text': join(lamp#view#buffer#get_lines(a:bufnr), "\n") }]
    \ })

    " incremental sync.
  elseif l:sync_kind == 2
    let l:diff = l:doc.diff()
    if l:diff.rangeLength != 0 || l:diff.text !=# ''
      call l:doc.sync()
      call self.detect_workspace(a:bufnr)
      call self.rpc.notify('textDocument/didChange', {
      \   'textDocument': lamp#protocol#document#versioned_identifier(a:bufnr),
      \   'contentChanges': [l:diff]
      \ })
    endif
  endif
endfunction

"
" close_document.
"
function! s:Server.close_document(bufnr) abort
  let l:document = get(filter(values(self.documents), { k, v -> v.bufnr == a:bufnr }), 0, {})
  if empty(l:document)
    return
  endif

  let l:path = lamp#protocol#document#decode_uri(l:document.uri)

  " remove managed document.
  if has_key(self.documents, l:document.uri)
    call remove(self.documents, l:document.uri)
  endif
  if has_key(self.diagnostics, l:document.uri)
    call remove(self.diagnostics, l:document.uri)
  endif

  call self.rpc.notify('textDocument/didClose', {
  \   'textDocument': {
  \     'uri': l:document.uri
  \   }
  \ })
endfunction

"
" will_save_document
"
function! s:Server.will_save_document(bufnr) abort
  if self.capabilities.get_text_document_sync_will_save()
    call self.notify('textDocument/willSave', {
    \   'textDocument': lamp#protocol#document#identifier(a:bufnr),
    \   'reason': 1,
    \ })
  endif

  if self.capabilities.get_text_document_sync_will_save_wait_until()
    try
      let l:edits = lamp#sync(
      \   self.notify('textDocument/willSaveWaitUntil', {
      \     'textDocument': lamp#protocol#document#identifier(a:bufnr),
      \   }),
      \   200
      \ )
      call lamp#view#edit#apply(a:bufnr, l:edits)
    catch /.*/
      call lamp#log('[ERROR]', 's:on_text_document_will_save', 'timeout')
    endtry
  endif
endfunction

"
" did_save_document
"
function! s:Server.did_save_document(bufnr) abort
  if self.capabilities.get_text_document_sync_save()
    let l:message = { 'textDocument': lamp#protocol#document#identifier(a:bufnr) }
    if self.capabilities.get_text_document_sync_save_include_text() 
      let l:message.text = join(lamp#view#buffer#get_lines(a:bufnr), "\n")
    endif
    call self.notify('textDocument/didSave', l:message)
  endif
endfunction

"
" on_workspace_folders
"
function! s:Server.on_workspace_folders(params) abort
  return lamp#feature#workspace#get_folders()
endfunction

"
" on_configuration
"
function! s:Server.on_configuration(params) abort
  let l:config = lamp#feature#workspace#get_config()
  return map(copy(a:params.items), { _, item ->
  \   lamp#get(l:config, item.section, v:null)
  \ })
endfunction

"
" on_apply_edit
"
function! s:Server.on_apply_edit(params) abort
  try
    let l:workspace_edit = lamp#view#edit#normalize_workspace_edit(a:params.edit)
    call lamp#view#edit#apply_workspace(l:workspace_edit)
    return { 'applied': v:true }
  catch /.*/
    return { 'applied': v:false }
  endtry
endfunction

"
" on_register_capability
"
function! s:Server.on_register_capability(params) abort
  for l:registration in a:params.registrations
    call self.capabilities.register(l:registration)
  endfor
  return v:null
endfunction

"
" on_unregister_capability
"
function! s:Server.on_unregister_capability(params) abort
  for l:registration in a:params.registrations
    call self.capabilities.unregister(l:registration)
  endfor
  return v:null
endfunction

"
" on_show_message_request
"
function! s:Server.on_show_message_request(params) abort
  if has_key(a:params, 'actions') && type(a:params.actions) == type([])
    let l:index = lamp#view#input#select(
    \   a:params.message,
    \   map(copy(a:params.actions), { _, action -> action.title })
    \ )
    if l:index >= 0
      return a:params.actions[l:index]
    endif
  else
    if a:params.type == 1
      echohl ErrorMsg
    elseif a:params.type == 2
      echohl WarningMsg
    elseif a:params.type == 4
      echohl NonText
    endif
    echomsg join([self.name, a:params.message], "\t")
    echohl None
  endif
  return v:null
endfunction

"
" on_publish_diagnostics
"
function! s:Server.on_publish_diagnostics(params) abort
  let l:document = get(self.documents, a:params.uri, {})
  if !has_key(self.diagnostics, a:params.uri)
    let self.diagnostics[a:params.uri] = s:Diagnostics.new({
    \   'uri': a:params.uri,
    \   'diagnostics': a:params.diagnostics,
    \   'document_version': get(l:document, 'version', -1),
    \ })
  endif
  call self.diagnostics[a:params.uri].set(a:params.diagnostics, get(l:document, 'version', -1))

  call lamp#feature#diagnostic#update(self, self.diagnostics[a:params.uri])
endfunction

"
" on_show_message
"
function! s:Server.on_show_message(params) abort
  if a:params.type == 1
    echohl ErrorMsg
  elseif a:params.type == 2
    echohl WarningMsg
  elseif a:params.type == 4
    echohl NonText
  endif
  echomsg join([self.name, a:params.message], "\t")
  echohl None
endfunction

"
" log
"
function! s:Server.log(...) abort
  if strlen(lamp#config('global.debug')) > 0
    let l:name = strcharpart(self.name, 0, 12)
    let l:name = l:name . repeat(' ', 12 - strlen(l:name))
    call call('lamp#log', [l:name] + a:000)
  endif
endfunction

