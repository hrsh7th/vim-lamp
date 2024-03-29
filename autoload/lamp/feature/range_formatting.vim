function! lamp#feature#range_formatting#init() abort
  " noop
endfunction

function! lamp#feature#range_formatting#do() abort
  if has_key(s:, 'cancellation_token')
    call s:cancellation_token.cancel()
  endif
  let s:cancellation_token = lamp#cancellation_token()

  let l:bufnr = bufnr('%')
  let l:servers = lamp#server#registry#find_by_filetype(&filetype)
  let l:servers = filter(l:servers, { k, v -> v.supports('capabilities.documentRangeFormattingProvider') })
  if empty(l:servers)
    call lamp#view#notice#add({ 'lines': ['`RangeFormatting`: Has no `RangeFormatting` capability.'] })
    return
  endif
  let l:p = l:servers[0].request('textDocument/rangeFormatting', {
        \   'textDocument': lamp#protocol#document#identifier(l:bufnr),
        \   'range': lamp#view#visual#range(),
        \   'options': {
        \     'tabSize': lamp#view#buffer#get_indent_size(),
        \     'insertSpaces': &expandtab ? v:true : v:false
        \   }
        \ }, {
        \   'cancellation_token': s:cancellation_token,
        \ })
  let l:p = l:p.then({ response -> s:on_response(l:bufnr, response) })
  let l:p = l:p.catch(lamp#rescue())
endfunction

function! s:on_response(bufnr, response) abort
  if type(a:response) == type([])
    call lamp#view#edit#apply(a:bufnr, a:response)
  else
    call lamp#view#notice#add({ 'lines': ['`Formatting`: No formatting response found.'] })
  endif
endfunction

