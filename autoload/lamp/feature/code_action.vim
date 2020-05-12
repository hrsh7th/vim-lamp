let s:Position = vital#lamp#import('VS.LSP.Position')
let s:Promise = vital#lamp#import('Async.Promise')

let s:test = {}

"
" lamp#feature#code_action#test
"
function! lamp#feature#code_action#test(test) abort
  let s:test = a:test
endfunction

"
" lamp#feature#code_action#init
"
function! lamp#feature#code_action#init() abort
  " noop
endfunction

"
" lamp#feature#code_action#complete
"
function! lamp#feature#code_action#complete(input, command, len) abort
  let l:servers = lamp#server#registry#find_by_filetype(&filetype)
  let l:servers = filter(l:servers, { _, server -> server.supports('capabilities.codeActionProvider') })
  let l:kinds = []
  for l:server in l:servers
    let l:kinds += l:server.capability.get_code_action_kinds()
  endfor
  return filter(l:kinds, { _, k -> k =~ '^' . a:input })
endfunction

"
" lamp#feature#code_action#do
"
function! lamp#feature#code_action#do(option) abort
  if has_key(s:, 'cancellation_token')
    call s:cancellation_token.cancel()
  endif
  let s:cancellation_token = lamp#cancellation_token()

  let l:range = get(a:option, 'range', v:false)
  let l:query = get(a:option, 'query', '')
  let l:sync = get(a:option, 'sync', v:false)

  let l:bufnr = bufnr('%')
  let l:servers = lamp#server#registry#find_by_filetype(&filetype)
  let l:servers = filter(l:servers, { _, server -> server.supports('capabilities.codeActionProvider') })
  if empty(l:servers)
    call lamp#view#notice#add({ 'lines': ['`CodeAction`: Has no `CodeAction` capability.'] })
    return
  endif

  " TODO: l:server is invalid (when using multiple servers.)
  let l:promises = []
  for l:server in l:servers
    let l:diagnostic = s:get_nearest_diagnostic(l:range, l:bufnr, l:server)
    call add(l:promises, l:server.request('textDocument/codeAction', {
          \   'textDocument': lamp#protocol#document#identifier(l:bufnr),
          \   'range': s:get_range(l:range, l:diagnostic),
          \   'context': {
          \     'diagnostics': !empty(l:diagnostic) ? [l:diagnostic] : [],
          \     'only': ['', 'quickfix', 'refactor', 'refactor.extract', 'refactor.inline', 'refactor.rewrite', 'source', 'source.organizeImports']
          \   }
          \ }, {
          \   'cancellation_token': s:cancellation_token
          \ }).then({ data -> { 'server': l:server, 'data': data } }).catch(lamp#rescue([])))
  endfor

  let l:p = s:Promise.all(l:promises)
  let l:p = l:p.then({ responses -> s:on_responses(l:query, l:sync, responses) })
  let l:p = l:p.catch(lamp#rescue())

  if l:sync
    try
      call lamp#sync(l:p)
    catch /.*/
      echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
    endtry
  endif
endfunction

"
" on_responses
"
" responses = [{ 'server': ..., 'data': [...CodeAction] }]
"
function! s:on_responses(query, sync, responses) abort
  let l:code_actions = [] " [{ 'server': ..., 'action': CodeAction }]
  for l:response in a:responses
    let l:response.data = type(l:response.data) == type([]) ? l:response.data : []
    let l:code_actions += map(l:response.data, { k, v ->
          \   {
          \     'server': l:response.server,
          \     'action': v
          \   }
          \ })
  endfor

  if empty(l:code_actions)
    call lamp#view#notice#add({ 'lines': ['`CodeAction`: No code action found.'] })
    return
  endif

  if has_key(s:test, 'action_index')
    let l:index = s:test.action_index
  else
    let l:code_actions = filter(copy(l:code_actions), { _, a -> get(a.action, 'kind', '') =~ a:query })
    if len(l:code_actions) > 1 || empty(a:query)
      let l:index = lamp#view#input#select('Select code actions:', map(copy(l:code_actions), { k, v ->
            \   substitute(v.action.title, '\r\n\|\n\|\r', '', 'g')
            \ }))
    elseif len(l:code_actions) == 1
      let l:index = 0
    else
      echoerr 'can not specified code action.'
      return
    endif
  endif

  if l:index < 0
    return
  endif

  let l:code_action = l:code_actions[l:index]

  let l:p = s:Promise.resolve()

  " has WorkspaceEdit.
  if has_key(l:code_action.action, 'edit')
    let l:workspace_edit = lamp#view#edit#normalize_workspace_edit(l:code_action.action.edit)
    call lamp#view#edit#apply_workspace(l:workspace_edit)
  endif

  " Command
  if has_key(l:code_action.action, 'command') && type(l:code_action.action.command) == type('')
    let l:p = l:code_action.server.request('workspace/executeCommand', {
          \   'command': l:code_action.action.command,
          \   'arguments': get(l:code_action.action, 'arguments', v:null)
          \ })

  " has Command
  elseif has_key(l:code_action.action, 'command') && type(l:code_action.action.command) == type({})
    let l:p = l:code_action.server.request('workspace/executeCommand', {
          \   'command': l:code_action.action.command.command,
          \   'arguments': get(l:code_action.action.command, 'arguments', v:null)
          \ })
  endif

  if a:sync
    try
      call lamp#sync(l:p)
    catch /.*/
      echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
    endtry
  endif
endfunction

"
" get_diagnostic
"
function! s:get_nearest_diagnostic(range, bufnr, server) abort
  if a:range != 0
    return []
  endif

  let l:uri = lamp#protocol#document#encode_uri(a:bufnr)
  if !has_key(a:server.diagnostics, l:uri)
    return []
  endif

  let l:diagnostics = copy(a:server.diagnostics[l:uri].diagnostics)
  let l:diagnostics = filter(l:diagnostics, { k, v -> lamp#protocol#range#in_line(v.range) })
  let l:diagnostics = sort(l:diagnostics, { v1, v2 ->
        \   lamp#protocol#range#compare_nearest(v1.range, v2.range, s:Position.cursor())
        \ })
  return get(l:diagnostics, 0, {})
endfunction

"
" get_range
"
function! s:get_range(range, diagnostic) abort
  " diagnostics.
  if a:range == 0 && !empty(a:diagnostic)
    return a:diagnostic.range
  endif

  " visual selection.
  if a:range != 0
    return lamp#view#visual#range()
  endif

  " line range.
  return lamp#protocol#range#get_current_line()
endfunction

