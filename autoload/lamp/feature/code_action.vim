let s:Promise = vital#lamp#import('Async.Promise')

"
" lamp#feature#code_action#init
"
function! lamp#feature#code_action#init() abort
  " noop
endfunction

"
" lamp#feature#code_action#do
"
function! lamp#feature#code_action#do(range) abort
  let l:bufnr = bufnr('%')
  let l:servers = lamp#server#registry#find_by_filetype(&filetype)
  let l:servers = filter(l:servers, { k, v -> v.supports('capabilities.codeActionProvider') })
  if empty(l:servers)
    return
  endif

  let l:promises = []
  for l:server in l:servers
    let l:diagnostic = s:get_nearest_diagnostic(a:range, l:bufnr, l:server)
    call add(l:promises, l:server.request('textDocument/codeAction', {
          \   'textDocument': lamp#protocol#document#identifier(l:bufnr),
          \   'range': s:get_range(a:range, l:diagnostic),
          \   'context': {
          \     'diagnostics': !empty(l:diagnostic) ? [l:diagnostic] : []
          \   }
          \ }).then({ data -> { 'server': l:server, 'data': data } }))
  endfor

  let l:p = s:Promise.all(l:promises)
  let l:p = l:p.then({ responses -> s:on_responses(responses) })
  let l:p = l:p.catch(lamp#rescue())
endfunction

"
" s:on_responses
"
" responses = [{ 'server': ..., 'data': [...CodeAction] }]
"
function! s:on_responses(responses) abort
  let l:code_actions = [] " [{ 'server': ..., 'action': CodeAction }]
  for l:response in a:responses
    let l:code_actions += map(l:response.data, { k, v ->
          \   {
          \     'server': l:response.server,
          \     'action': v
          \   }
          \ })
  endfor

  if empty(l:code_actions)
    return
  endif

  let l:index = lamp#view#input#select('Select code actions:', map(copy(l:code_actions), { k, v ->
        \   v.action.title
        \ }))
  if l:index < 0
    return
  endif

  let l:code_action = l:code_actions[l:index]
  if has_key(l:code_action.action, 'command')
    call l:code_action.server.request('workspace/executeCommand', {
          \   'command': l:code_action.action.command,
          \   'arguments': get(l:code_action.action, 'arguments', v:null)
          \ })
  elseif has_key(l:code_action.action, 'edit')
    let l:workspace_edit = lamp#view#edit#normalize_workspace_edit(l:code_action.action.edit)
    call lamp#view#edit#apply_workspace(l:workspace_edit)
  endif
endfunction

"
" s:get_diagnostic
"
function! s:get_nearest_diagnostic(range, bufnr, server) abort
  if a:range != 0
    return []
  endif

  let l:uri = lamp#protocol#document#encode_uri(a:bufnr)
  if !has_key(a:server.documents, l:uri)
    return []
  endif

  let l:diagnostics = copy(a:server.documents[l:uri].diagnostics)
  let l:diagnostics = filter(l:diagnostics, { k, v -> lamp#protocol#range#in_line(v.range) })
  let l:diagnostics = sort(l:diagnostics, { v1, v2 ->
        \   lamp#protocol#range#compare_nearest(v1, v2, lamp#protocol#position#get())
        \ })
  return get(l:diagnostics, 0, {})
endfunction

"
" s:get_range
"
function! s:get_range(range, diagnostic) abort
  " diagnostics.
  if a:range == 0 && !empty(a:diagnostic)
    return a:diagnostic.range
  endif

  " visual selection.
  if a:range != 0
    let l:start = getpos("'<")
    let l:end = getpos("'>")
    return {
          \   'start': {
          \     'line': l:start[1] - 1,
          \     'character': l:start[2] - 1
          \   },
          \   'end': {
          \     'line': l:end[1] - 1,
          \     'character': l:end[2] - 1
          \   }
          \ }
  endif

  " line range.
  return lamp#protocol#range#get_current_line()
endfunction

