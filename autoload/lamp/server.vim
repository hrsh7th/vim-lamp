let s:Promise = vital#lamp#import('Async.Promise')
let s:Document = lamp#server#document#import()
let s:Channel = lamp#server#channel#import()
let s:Capability = lamp#server#capability#import()
let s:Diff = lamp#view#diff#import()

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
  return extend(deepcopy(s:Server), {
  \   'name': a:name,
  \   'channel': s:Channel.new({ 'name': a:name, 'command': a:option.command }),
  \   'filetypes': a:option.filetypes,
  \   'root_uri': get(a:option, 'root_uri', { bufnr -> '' }),
  \   'initialization_options': get(a:option, 'initialization_options', { -> {} }),
  \   'trace': get(a:option, 'trace', 'off'),
  \   'diff': s:Diff.new(),
  \   'documents': {},
  \   'diagnostics': {},
  \   'capability': s:Capability.new({
  \     'capabilities': get(a:option, 'capabilities', {})
  \   }),
  \   'initialized': v:false,
  \   'state': {
  \     'started': v:false,
  \     'initialized': v:null,
  \     'exited': v:false,
  \   },
  \ })
endfunction

"
" start
"
function! s:Server.start() abort
  if !self.state.started && !self.state.exited
    let self.state.started = v:true
    call self.channel.start(function(s:Server.on_notification, [], self), {
    \   'cwd': self.root_uri(bufnr('%'))
    \ })
  endif
  return s:Promise.resolve()
endfunction

"
" stop
"
function! s:Server.stop() abort
  if self.state.started
    if !empty(self.state.initialized)
      try
        call lamp#sync(self.channel.request('shutdown', v:null), 200)
      catch /.*/
        call lamp#log('[ERROR]', { 'exception': v:exception, 'throwpoint': v:throwpoint })
      endtry
      call self.channel.notify('exit')
      doautocmd User lamp#server#exited
    endif
    " call lamp#sync({ -> !self.channel.is_running() }, 100) NOTE: This line is needed maybe but it makes bad experience.
    call self.channel.stop()
    let self.state.started = v:false
    let self.state.initialized = v:null
  endif
  return s:Promise.resolve()
endfunction

"
" exit
"
function! s:Server.exit() abort
  if self.state.started
    if !empty(self.state.initialized)
      try
        call lamp#sync(self.channel.request('shutdown', v:null), 200)
      catch /.*/
        call lamp#log('[ERROR]', { 'exception': v:exception, 'throwpoint': v:throwpoint })
      endtry
      call self.channel.notify('exit')
      doautocmd User lamp#server#exited
    endif
    " call lamp#sync({ -> !self.channel.is_running() }, 100) NOTE: This line is needed maybe but it makes bad experience.
    call self.channel.stop()
    let self.state.initialized = v:null
    let self.state.exited = v:true
  endif
  return s:Promise.resolve()
endfunction

"
" is_running
"
function! s:Server.is_running() abort
  return self.channel.is_running()
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
    call self.capability.merge(a:response)
    call self.channel.notify('initialized', {})
    call self.channel.notify('workspace/didChangeConfiguration', { 'settings': lamp#feature#workspace#get_config() })

    let self.initialized = v:true
    doautocmd User lamp#server#initialized

    call lamp#view#notice#add({ 'lines': [printf('`%s` initialized', self.name)] })

    return a:response
  endfunction

  let l:root_uri = self.root_uri(a:bufnr)
  if l:root_uri ==# ''
    let l:root_uri = lamp#fnamemodify(bufname('%'), ':p:h')
  endif

  call lamp#feature#workspace#update(self, a:bufnr)
  let self.state.initialized = self.channel.request('initialize', {
  \   'processId': getpid(),
  \   'rootPath': l:root_uri,
  \   'rootUri': lamp#protocol#document#encode_uri(l:root_uri),
  \   'initializationOptions': self.initialization_options(),
  \   'trace': self.trace,
  \   'capabilities': lamp#server#capability#get_default_capability(),
  \   'workspaceFolders': lamp#feature#workspace#get_folders(),
  \ }).then(function(l:ctx.callback, [a:bufnr], self))
  return self.state.initialized
endfunction

"
" request.
"
function! s:Server.request(method, params, ...) abort
  let l:option = get(a:000, 0, {})
  let l:p = s:Promise.resolve()
  let l:p = l:p.then({ -> self.ensure_document_from_params(a:params) })
  let l:p = l:p.then({ -> self.channel.request(a:method, a:params, l:option) })
  return l:p
endfunction

"
" response.
"
function! s:Server.response(id, data) abort
  return self.channel.response(a:id, a:data)
endfunction

"
" notify.
"
function! s:Server.notify(method, params) abort
  let l:p = s:Promise.resolve()
  let l:p = l:p.then({ -> self.ensure_document_from_params(a:params) })
  let l:p = l:p.then({ -> self.channel.notify(a:method, a:params) })
  return l:p
endfunction

"
" supports.
"
function! s:Server.supports(path) abort
  return self.capability.supports(a:path)
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
  call self.diff.attach(a:bufnr)
  let self.documents[l:uri] = s:Document.new(a:bufnr)
  call self.channel.notify('textDocument/didOpen', {
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

  let l:sync_kind = self.capability.get_text_document_sync_kind()

  " full sync.
  if l:sync_kind == 1
    call l:doc.sync()
    call self.diff.sync(a:bufnr)
    call self.channel.notify('textDocument/didChange', {
    \   'textDocument': lamp#protocol#document#versioned_identifier(a:bufnr),
    \   'contentChanges': [{ 'text': join(self.diff.get_lines(a:bufnr), "\n") }]
    \ })

    " incremental sync.
  elseif l:sync_kind == 2
    let l:diff = self.diff.compute(a:bufnr)
    if l:diff.rangeLength != 0 || l:diff.text !=# ''
      call l:doc.sync()
      call self.channel.notify('textDocument/didChange', {
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
  call self.diff.detach(a:bufnr)

  call self.channel.notify('textDocument/didClose', {
  \   'textDocument': {
  \     'uri': l:document.uri
  \   }
  \ })
endfunction

"
" will_save_document
"
function! s:Server.will_save_document(bufnr) abort
  if self.capability.get_text_document_sync_will_save()
    call self.notify('textDocument/willSave', {
    \   'textDocument': lamp#protocol#document#identifier(a:bufnr),
    \   'reason': 1,
    \ })
  endif

  if self.capability.get_text_document_sync_will_save_wait_until()
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
  if self.capability.get_text_document_sync_save()
    let l:message = { 'textDocument': lamp#protocol#document#identifier(a:bufnr) }
    if self.capability.get_text_document_sync_save_include_text() 
      let l:message.text = join(lamp#view#buffer#get_lines(a:bufnr), "\n")
    endif
    call self.notify('textDocument/didSave', l:message)
  endif
endfunction

"
" on_notification.
"
function! s:Server.on_notification(notification) abort
  call timer_start(0, { -> lamp#server#notification#on(self, a:notification) })
endfunction

