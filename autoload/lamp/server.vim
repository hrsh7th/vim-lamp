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
        \   'root_uri': get(a:option, 'root_uri', { -> '' }),
        \   'initialization_options': get(a:option, 'initialization_options', { -> {} }),
        \   'trace': get(a:option, 'trace', 'off'),
        \   'workspace_path': '',
        \   'workspace_folders': [],
        \   'workspace_configurations': get(a:option, 'workspace_configurations', {}),
        \   'diff': s:Diff.new(),
        \   'documents': {},
        \   'capability': s:Capability.new({
        \     'capabilities': get(a:option, 'capabilities', {})
        \   }),
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
    call self.channel.start(function(s:Server.on_notification, [], self))
  endif
  return s:Promise.resolve()
endfunction

"
" stop
"
function! s:Server.stop() abort
  if self.state.started
    if !empty(self.state.initialized)
      call lamp#sync(self.channel.request('shutdown'), 200)
      call self.channel.notify('exit')
      doautocmd User lamp#server#exited
    endif
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
        call lamp#sync(self.channel.request('shutdown'), 200)
      catch /.*/
      endtry
      call self.channel.notify('exit')
      doautocmd User lamp#server#exited
    endif
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
function! s:Server.initialize() abort
  if !empty(self.state.initialized)
    return self.state.initialized
  endif

  let l:ctx = {}
  function! l:ctx.callback(response) abort dict
    call self.capability.merge(a:response)
    call self.channel.notify('initialized', {})

    doautocmd User lamp#server#initialized

    call lamp#view#notice#add({ 'lines': [printf('`%s` initialized', self.name)] })

    return a:response
  endfunction

  let self.state.initialized = self.channel.request('initialize', {
        \   'processId': getpid(),
        \   'rootPath': self.root_uri(),
        \   'rootUri': lamp#protocol#document#encode_uri(self.root_uri()),
        \   'initializationOptions': self.initialization_options(),
        \   'trace': self.trace,
        \   'capabilities': lamp#server#capability#get_default_capability(),
        \ }).then(function(l:ctx.callback, [], self))
  return self.state.initialized
endfunction

"
" request.
"
function! s:Server.request(method, params) abort
  let l:p = s:Promise.resolve()
  let l:p = l:p.then({ -> [self.start(), self.initialize()] })
  let l:p = l:p.then({ -> self.ensure_document_from_params(a:params) })
  let l:p = l:p.then({ -> self.channel.request(a:method, a:params) })
  return l:p
endfunction

"
" response.
"
function! s:Server.response(id, data) abort
  let l:p = s:Promise.resolve()
  let l:p = l:p.then({ -> self.channel.response(a:id, a:data) })
  return l:p
endfunction

"
" notify.
"
function! s:Server.notify(method, params) abort
  let l:p = s:Promise.resolve()
  let l:p = l:p.then({ -> [self.start(), self.initialize()] })
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
  call self.start()
  return self.initialize().then({ -> [
        \   self.workspace_folder(a:bufnr),
        \   self.workspace_configuration(a:bufnr),
        \   self.open_document(a:bufnr),
        \   self.close_document(a:bufnr),
        \   self.change_document(a:bufnr)
        \ ] })
endfunction

"
" workspace_folder.
"
function! s:Server.workspace_folder(bufnr) abort
  if !self.capability.is_workspace_folder_supported()
    return
  endif

  let l:root_uri = self.root_uri()
  for l:folder in self.workspace_folders
    if l:folder.uri == l:root_uri
      return
    endif
  endfor

  let l:folder = {
  \   'uri': l:root_uri,
  \   'name': 'auto detected workspace'
  \ }

  call self.channel.notify('workspace/didChangeWorkspaceFolders', {
  \   'event': {
  \     'added': [l:folder]
  \   }
  \ })
  let self.workspace_folders += [l:folder]
endfunction

"
" workspace_configuration.
"
function! s:Server.workspace_configuration(bufnr) abort
  let l:workspace_path = '*'

  let l:path = fnamemodify(bufname(a:bufnr), ':p')
  for [l:workspace_path, l:configuration] in items(self.workspace_configurations)
    if stridx(l:workspace_path, l:path) == 0
      break
    endif
  endfor

  if has_key(self.workspace_configurations, l:workspace_path) && self.workspace_path != l:workspace_path
    let self.workspace_path = l:workspace_path
    call self.channel.notify('workspace/didChangeConfiguration', {
          \   'settings': self.workspace_configurations[l:workspace_path]
          \ })
  endif
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
" change_document.
"
function! s:Server.change_document(bufnr) abort
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
      call l:doc.sync()
    if l:diff.rangeLength != 0 || l:diff.text !=# ''
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

  " buffer is not unloaded.
  if bufexists(l:path)
    return
  endif

  " ignore if buffer is not related to file.
  " if remove this, occurs infinite loop because bufloaded always return -1
  if !filereadable(l:path)
    return
  endif

  " remove managed document.
  call remove(self.documents, l:document.uri)
  call self.diff.detach(a:bufnr)

  call self.channel.notify('textDocument/didClose', {
        \   'textDocument': {
        \     'uri': l:document.uri
        \   }
        \ })
endfunction

"
" on_notification.
"
function! s:Server.on_notification(notification) abort
  call timer_start(0, { -> lamp#server#notification#on(self, a:notification) })
endfunction

