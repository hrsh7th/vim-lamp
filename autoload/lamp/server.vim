let s:Promise = vital#lamp#import('Async.Promise')
let s:JSON = vital#lamp#import('VS.RPC.JSON')
let s:Document = lamp#server#document#import()
let s:Capabilities = lamp#server#capabilities#import()

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
  \   'rpc': s:JSON.new({
  \     'command': a:option.command,
  \   }),
  \   'filetypes': a:option.filetypes,
  \   'root_uri': get(a:option, 'root_uri', { bufnr -> '' }),
  \   'root_uri_cache': {},
  \   'initialization_options': get(a:option, 'initialization_options', { -> {} }),
  \   'trace': get(a:option, 'trace', 'off'),
  \   'request_id': 0,
  \   'documents': {},
  \   'diagnostics': {},
  \   'capabilities': s:Capabilities.new(),
  \   'initialized': v:false,
  \   'state': {
  \     'started': v:false,
  \     'initialized': v:null,
  \     'exited': v:false,
  \   },
  \ })
  call l:server.rpc.events.on('stderr', function(l:server.on_stderr, [], l:server))
  call l:server.rpc.events.on('exit', function(l:server.on_exit, [], l:server))
  call l:server.rpc.events.on('request', function(l:server.on_request, [], l:server))
  call l:server.rpc.events.on('notify', function(l:server.on_notify, [], l:server))
  return l:server
endfunction

"
" create_request_id
"
function! s:Server.create_request_id() abort
  let l:request_id = self.request_id
  let self.request_id += 1
  return l:request_id
endfunction

"
" start
"
function! s:Server.start() abort
  if !self.state.started && !self.state.exited
    let self.state.started = v:true
    call self.rpc.start({
    \   'cwd': self.get_root_uri(bufnr('%'))
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
      let l:p = l:p.then({ -> self.request_raw(self.create_request_id(), 'shutdown', v:null) })
      let l:p = l:p.then({ -> self.notify_raw('exit') })
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
  call self.start()
  if !empty(self.state.initialized)
    return self.state.initialized
  endif

  let l:ctx = {}
  function! l:ctx.callback(bufnr, response) abort dict
    call self.capabilities.merge(a:response)
    call self.notify_raw('initialized', {})
    call self.notify_raw('workspace/didChangeConfiguration', {
    \   'settings': lamp#feature#workspace#get_config()
    \ })
    call self.notify_raw('workspace/didChangeWorkspaceFolders', {
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
  let self.state.initialized = self.request_raw(self.create_request_id(), 'initialize', {
  \   'processId': getpid(),
  \   'rootPath': l:root_uri,
  \   'rootUri': lamp#protocol#document#encode_uri(l:root_uri),
  \   'initializationOptions': self.initialization_options(),
  \   'trace': self.trace,
  \   'capabilities': lamp#server#capabilities#get_default_capabilities(),
  \   'workspaceFolders': lamp#feature#workspace#get_folders(),
  \ }).then(function(l:ctx.callback, [a:bufnr], self))
  return self.state.initialized
endfunction

"
" request.
"
function! s:Server.request(method, params, ...) abort
  let l:request_id = self.create_request_id()

  let l:option = get(a:000, 0, {})
  if has_key(l:option, 'cancellation_token')
    call l:option.cancellation_token.attach({ -> self.rpc.cancel(l:request_id) })
  endif

  let l:p = s:Promise.resolve()
  let l:p = l:p.then({ -> self.ensure_document_from_params(a:params) })
  let l:p = l:p.then({ -> self.request_raw(l:request_id, a:method, a:params) })
  return l:p
endfunction

"
" response.
"
function! s:Server.response(id, data) abort
  return self.response_raw(a:id, a:data)
endfunction

"
" notify.
"
function! s:Server.notify(method, params) abort
  let l:p = s:Promise.resolve()
  let l:p = l:p.then({ -> self.ensure_document_from_params(a:params) })
  let l:p = l:p.then({ -> self.notify_raw(a:method, a:params) })
  return l:p
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
  call self.notify_raw('textDocument/didOpen', {
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
    call self.notify_raw('textDocument/didChange', {
    \   'textDocument': lamp#protocol#document#versioned_identifier(a:bufnr),
    \   'contentChanges': [{ 'text': join(lamp#view#buffer#get_lines(a:bufnr), "\n") }]
    \ })

    " incremental sync.
  elseif l:sync_kind == 2
    let l:diff = l:doc.diff()
    if l:diff.rangeLength != 0 || l:diff.text !=# ''
      call l:doc.sync()
      call self.detect_workspace(a:bufnr)
      call self.notify_raw('textDocument/didChange', {
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

  call self.notify_raw('textDocument/didClose', {
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
" request_raw
"
function! s:Server.request_raw(id, method, params) abort
  call self.log('-> REQUEST', a:id, a:method, a:params)
  return self.rpc.request(a:id, a:method, a:params).then(function(self.on_response, [a:id], self))
endfunction

"
" notify_raw
"
function! s:Server.notify_raw(method, ...) abort
  let l:params = get(a:000, 0, v:null)
  call self.log('-> NOTIFY', a:method, l:params)
  return self.rpc.notify(a:method, l:params)
endfunction

"
" response_raw
"
function! s:Server.response_raw(id, result) abort
  call self.log('-> RESPONSE', a:id, a:result)
  return self.rpc.response(a:id, a:result)
endfunction

"
" on_request.
"
function! s:Server.on_request(request) abort
  call self.log('<- ON_REQUEST', a:request.id, a:request.method, a:request.params)
  call timer_start(0, { -> lamp#server#on_request#on(self, a:request) })
endfunction

"
" on_notification.
"
function! s:Server.on_notify(notification) abort
  call self.log('<- ON_NOTIFY', a:notification.method, a:notification.params)
  call timer_start(0, { -> lamp#server#on_notify#on(self, a:notification) })
endfunction

"
" on_response
"
function! s:Server.on_response(id, response) abort
  call self.log('<- ON_RESPONSE', a:id, a:response)
  return a:response
endfunction

"
" on_stderr
"
function! s:Server.on_stderr(data) abort
  call self.log('[STDERR]', a:data)
endfunction

"
" on_exit
"
function! s:Server.on_exit(code) abort
  call self.log('[EXIT]', a:code)
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

