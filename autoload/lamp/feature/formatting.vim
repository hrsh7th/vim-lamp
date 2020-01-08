function! lamp#feature#formatting#init() abort
  " noop
endfunction

function! lamp#feature#formatting#do(option) abort
  let l:sync = get(a:option, 'sync', v:false)

  let l:bufnr = bufnr('%')
  let l:servers = lamp#server#registry#find_by_filetype(&filetype)
  let l:servers = filter(l:servers, { k, v -> v.supports('capabilities.documentFormattingProvider') })
  if empty(l:servers)
    call lamp#view#notice#add({ 'lines': ['`Formatting`: Has no `Formatting` capability.'] })
    return
  endif
  let l:p = l:servers[0].request('textDocument/formatting', {
        \   'textDocument': lamp#protocol#document#identifier(l:bufnr),
        \   'options': {
        \     'tabSize': lamp#view#buffer#get_indent_size(),
        \     'insertSpaces': &expandtab ? v:true : v:false
        \   }
        \ })
  let l:p = l:p.then({ response -> s:on_response(l:bufnr, response) })
  let l:p = l:p.catch(lamp#rescue())

  if l:sync
    call lamp#sync(l:p)
  endif
endfunction

function! s:on_response(bufnr, response) abort
  if type(a:response) == type([])
    call lamp#view#edit#apply(a:bufnr, a:response)
  else
    call lamp#view#notice#add({ 'lines': ['`Formatting`: No formatting response found.'] })
  endif
endfunction

