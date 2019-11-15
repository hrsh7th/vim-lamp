let s:Promise = vital#lamp#import('Async.Promise')
let s:Document = lamp#server#document#import()
let s:Channel = lamp#server#channel#import()
let s:Capability = lamp#server#capability#import()

"
" Create server instance.
"
function! lamp#server#import() abort
  return s:Server
endfunction

let s:Server = {}

"
" new.
"
function! s:Server.new(name, option) abort
  return extend(deepcopy(s:Server), {
        \   'name': a:name,
        \   'channel': s:Channel.new({ 'command': a:option.command }),
        \   'filetypes': a:option.filetypes,
        \   'root_uri': get(a:option, 'root_uri', { -> '' }),
        \   'initialization_options': get(a:option, 'initialization_options', { -> {} }),
        \   'documents': {},
        \   'capability': s:Capability.new({
        \     'capabilities': get(a:option, 'capabilities', {})
        \   }),
        \   'state': {
        \     'started': v:false,
        \     'initialized': v:null,
        \   },
        \ })
endfunction

"
" start.
"
function! s:Server.start() abort
  if !self.state.started
    let self.state.started = v:true
    call self.channel.start(function(s:Server.on_notification, [], self))
  endif
  return s:Promise.resolve()
endfunction

"
" stop.
"
function! s:Server.stop() abort
  if self.state.started
   call self.channel.stop()
    let self.state.started = v:false
    let self.initialized = v:null
  endif
  return s:Promise.resolve()
endfunction

"
" is_running.
"
function! s:Server.is_running() abort
  return self.channel.is_running()
endfunction

"
" initialize.
"
function! s:Server.initialize() abort
  if !empty(self.state.initialized)
    return self.state.initialized
  endif

  " callback
  let l:fn = {}
  function! l:fn.on_initialize(response) abort dict
    call self.capability.merge(a:response)
    call self.channel.notify('initialized', {})
    return a:response
  endfunction

  " request.
  let self.state.initialized = self.channel.request('initialize', {
        \   'processId': v:null,
        \   'rootUri': lamp#protocol#document#encode_uri(self.root_uri()),
        \   'initializationOptions': self.initialization_options(),
        \   'capabilities': lamp#server#capability#get_default_capability(),
        \ }).then(function(l:fn.on_initialize, [], self))
  return self.state.initialized
endfunction

"
" request.
"
function! s:Server.request(method, params) abort
  let l:p = s:Promise.resolve()
  let l:p = l:p.then({ -> self.start() })
  let l:p = l:p.then({ -> self.initialize() })
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
  let l:p = l:p.then({ -> self.start() })
  let l:p = l:p.then({ -> self.initialize() })
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
        \   self.open_document(a:bufnr),
        \   self.close_document(a:bufnr),
        \   self.change_document(a:bufnr)
        \ ] })
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

  " full sync.
  if self.capability.get_text_document_sync_kind() == 1
    call l:doc.sync()
    call self.channel.notify('textDocument/didChange', {
          \   'textDocument': lamp#protocol#document#versioned_identifier(a:bufnr),
          \   'contentChanges': [{ 'text': join(l:doc.buffer, "\n") }]
          \ })

  " incremental sync.
  elseif self.capability.get_text_document_sync_kind() == 2
    let l:diff = l:doc.diff()
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
  " ignore if buffer is not related file.
  " if remove this, occurs infinite loop because bufloaded always return -1
  if !filereadable(fnamemodify(bufname(a:bufnr), ':p'))
    return
  endif

  " buffer is not unloaded.
  if bufloaded(a:bufnr)
    return
  endif

  " remove managed document.
  call remove(self.documents, lamp#protocol#document#encode_uri(bufname(a:bufnr)))

  call self.channel.notify('textDocument/didClose', {
        \   'textDocument': lamp#protocol#document#identifier(a:bufnr)
        \ })
endfunction

"
" on_notification.
"
function! s:Server.on_notification(notification) abort
  call lamp#server#notification#on(self, a:notification)
endfunction

