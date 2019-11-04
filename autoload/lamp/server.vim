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
        \   'capability': v:null,
        \   'state': {
        \     'started': v:false,
        \     'initialized': v:false,
        \     'result': v:null,
        \     'error': v:null
        \   },
        \ })
endfunction

"
" Start server process.
"
function! s:Server.start() abort
  if !self.state.started
    call self.channel.start(function(s:Server.on_notification, [], self))
    let self.state.started = v:true
  endif
  return s:Promise.resolve()
endfunction

"
" Stop server process.
"
function! s:Server.stop() abort
  if self.state.started
   call self.channel.stop()
    let self.state.started = v:false
  endif
  return s:Promise.resolve()
endfunction

"
" Get current process status.
"
function! s:Server.is_running() abort
  return self.channel.is_running()
endfunction

"
" Request for language server.
"
function! s:Server.request(method, params) abort
  let l:fn = {}
  function! l:fn.on_response(promise, method, params, data) abort dict
    if a:promise._state == 2
      call lamp#log('[ERROR]', a:data)
      let self.state.error = a:data
      return s:Promise.reject(a:data)
    else
      call lamp#log('<- [RESPONSE]', a:method, a:data)
      return a:data
    endif
  endfunction

  " request.
  let l:p = s:Promise.resolve()
  if !self.state.started
    let l:p = l:p.then({ -> self.start() })
  endif
  if !self.state.initialized
    let l:p = l:p.then({ -> self.initialize() })
  endif
  let l:p = l:p.then({ -> self.ensure_document_from_params(a:params) })
  let l:p = l:p.then({ -> lamp#log('-> [REQUEST]', a:method, a:params) })
  let l:p = l:p.then({ -> self.channel.request(a:method, a:params) })
  let l:p = l:p.then(
        \ function(l:fn.on_response, [l:p, a:method, a:params], self),
        \ function(l:fn.on_response, [l:p, a:method, a:params], self))
  return l:p.finally({ -> self.finally(l:p) })
endfunction

"
" Response for language server.
"
function! s:Server.response(id, data) abort
  let l:p = s:Promise.resolve()
  let l:p = l:p.then({ -> lamp#log('-> [RESPONSE]', a:id, a:data) })
  let l:p = l:p.then({ -> self.channel.response(a:id, a:data) })
  let l:p = l:p.finally({ -> self.finally(l:p) })
  return l:p
endfunction

"
" Notify for language server.
"
function! s:Server.notify(method, params) abort
  let l:p = s:Promise.resolve()
  if !self.state.started
    let l:p = l:p.then({ -> self.start() })
  endif
  if !self.state.initialized
    let l:p = l:p.then({ -> self.initialize() })
  endif
  let l:p = l:p.then({ -> self.ensure_document_from_params(a:params) })
  let l:p = l:p.then({ -> lamp#log('  -> [NOTIFY]', a:method, a:params) })
  let l:p = l:p.then({ -> self.channel.notify(a:method, a:params) })
  return l:p.finally({ -> self.finally(l:p) })
endfunction

"
" supports.
"
function! s:Server.supports(path) abort
  if empty(self.capability)
    return v:false
  endif
  return self.capability.supports(a:path)
endfunction

"
" has document.
"
function! s:Server.has_document(bufnr) abort
  let l:uri = lamp#protocol#document#encode_uri(bufname(a:bufnr))
  return has_key(self.documents, l:uri)
endfunction

"
" Initialize.
"
function! s:Server.initialize() abort
  if self.state.initialized
    return s:Promise.resolve()
  endif
  let self.state.initialized = v:true

  " callback
  let l:fn = {}
  function! l:fn.on_initialize(response) abort dict
    let self.capability = s:Capability.new(a:response)
    call self.notify('initialized', {})
    return a:response
  endfunction

  " request.
  return self.request('initialize', {
        \   'processId': v:null,
        \   'rootUri': lamp#protocol#document#encode_uri(self.root_uri()),
        \   'initializationOptions': self.initialization_options(),
        \   'capabilities': g:lamp#server#capability#definition,
        \ }).then(function(l:fn.on_initialize, [], self))
endfunction

"
" Ensure document from request or notify params.
"
function! s:Server.ensure_document_from_params(params) abort
  if !has_key(a:params, 'textDocument')
    return s:Promise.resolve()
  endif
  return self.ensure_document(bufnr(lamp#protocol#document#decode_uri(a:params.textDocument.uri)))
endfunction

"
" Ensure document.
"
function! s:Server.ensure_document(bufnr) abort
  let l:p = s:Promise.resolve()
  let l:p = l:p.then({ -> self.open_document(a:bufnr) })
  let l:p = l:p.then({ -> self.close_document(a:bufnr) })
  let l:p = l:p.then({ -> self.change_document(a:bufnr) })
  return l:p.finally({ -> self.finally(l:p) })
endfunction

"
" Open document.
"
function! s:Server.open_document(bufnr) abort
  " check managed document.
  let l:uri = lamp#protocol#document#encode_uri(bufname(a:bufnr))
  if has_key(self.documents, l:uri)
    return s:Promise.resolve()
  endif
  let self.documents[l:uri] = s:Document.new(a:bufnr)

  " create document.
  let l:p = self.notify('textDocument/didOpen', {
        \   'textDocument': lamp#protocol#document#item(a:bufnr),
        \ })
  return l:p.finally({ -> self.finally(l:p) })
endfunction

"
" Change document.
"
function! s:Server.change_document(bufnr) abort
  " check managed document.
  let l:uri = lamp#protocol#document#encode_uri(bufname(a:bufnr))
  if !has_key(self.documents, l:uri)
    return s:Promise.resolve()
  endif

  " document is not change.
  let l:doc = self.documents[l:uri]

  let l:sync_kind  = self.capability.get_text_document_sync_kind()

  " full sync.
  if l:sync_kind == 1
    if !l:doc.out_of_date()
      return s:Promise.resolve()
    endif
    call l:doc.sync()
    let l:p = self.notify('textDocument/didChange', {
          \   'textDocument': lamp#protocol#document#versioned_identifier(a:bufnr),
          \   'contentChanges': [{ 'text': join(l:doc.buffer, "\n") }]
          \ })

  " incremental sync.
  elseif l:sync_kind == 2
    let l:diff = l:doc.diff()
    if l:diff.rangeLength == 0 && l:diff.text ==# '' 
      return s:Promise.resolve()
    endif
    call l:doc.sync()
    let l:p = self.notify('textDocument/didChange', {
          \   'textDocument': lamp#protocol#document#versioned_identifier(a:bufnr),
          \   'contentChanges': [l:diff]
          \ })
  endif
  return l:p.finally({ -> self.finally(l:p) })
endfunction

"
" Close document.
"
function! s:Server.close_document(bufnr) abort
  " ignore if buffer is not related file.
  " if remove this, occure inifinite loop because bufexists always return -1.
  if !filereadable(fnamemodify(bufname(a:bufnr), ':p'))
    return s:Promise.resolve()
  endif

  " buffer is not unloaded.
  if bufexists(a:bufnr)
    return s:Promise.resolve()
  endif

  " remove managed document.
  let l:uri = lamp#protocol#document#encode_uri(bufname(a:bufnr))
  if !has_key(self.documents, l:uri)
    return s:Promise.resolve()
  endif
  call remove(self.documents, l:uri)

  let l:p = self.notify('textDocument/didClose', {
        \   'textDocument': lamp#protocol#document#identifier(a:bufnr)
        \ })
  return l:p.finally({ -> self.finally(l:p) })
endfunction

"
" On notification from server.
"
function! s:Server.on_notification(notification) abort
  try
    if has_key(a:notification, 'id')
      call lamp#log('<- [REQUEST]', a:notification)
    else
      call lamp#log('  <- [NOTIFY]', a:notification)
    endif
    call lamp#server#notification#on(self, a:notification)
  catch /.*/
    call lamp#log('[ERROR]', { 'exception': v:exception, 'throwpoint': v:throwpoint })
  endtry
endfunction

"
" Rejected promise handling.
"
function! s:Server.finally(promise) abort
  if a:promise._state != 2
    return
  endif

  let l:result = a:promise._result


  " result is error.
  if !(has_key(l:result, 'exception') && has_key(l:result, 'throwpoint'))
    return
  endif

  " the error is logged.
  if l:result isnot self.state.error
    return
  endif

  " log error.
  call lamp#log('[ERROR]', l:result)
  let self.state.error = l:result
endfunction

