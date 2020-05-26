let s:Position = vital#lamp#import('VS.LSP.Position')
let s:Promise = vital#lamp#import('Async.Promise')

function! lamp#feature#signature_help#init() abort
  call lamp#view#floatwin#configure('signature_help', {
  \   'max_height': 12,
  \ })
  execute printf('augroup lamp#feature#signature_help_%d', bufnr('%'))
    autocmd!
    autocmd InsertLeave,CursorMoved <buffer> call s:close_signature_help()
    autocmd CursorMoved,CursorMovedI <buffer> call s:trigger_signature_help()
  augroup END
endfunction

"
" s:close_signature_help
"
function! s:close_signature_help() abort
  call lamp#view#floatwin#hide('signature_help')
  call lamp#debounce('lamp#feature#signature_help:trigger_signature_help', { -> {} }, 200)
endfunction

"
" s:trigger_signature_help
"
function! s:trigger_signature_help() abort
  let l:ctx = {}
  function! l:ctx.callback() abort
    if index(['i', 's'], mode()[0]) == -1
      return
    endif

    if has_key(s:, 'cancellation_token')
      call s:cancellation_token.cancel()
    endif
    let s:cancellation_token = lamp#cancellation_token()

    let l:bufnr = bufnr('%')
    let l:servers = lamp#server#registry#find_by_filetype(&filetype)
    let l:servers = filter(l:servers, { k, v -> v.supports('capabilities.signatureHelpProvider') })
    if empty(l:servers)
      call s:close_signature_help()
      return
    endif

    " gather trigger characters.
    let l:trigger_chars = []
    for l:server in l:servers
      let l:trigger_chars += l:server.capability.get_signature_help_trigger_characters()
    endfor

    " check trigger character.
    let l:char = lamp#view#cursor#get_before_char_skip_white()
    if index(l:trigger_chars, l:char) == -1
      call s:close_signature_help()
      return
    endif

    let l:promises = map(l:servers, { k, v -> v.request('textDocument/signatureHelp', {
          \   'textDocument': lamp#protocol#document#identifier(l:bufnr),
          \   'position': s:Position.cursor()
          \ }, {
          \   'cancellation_token': s:cancellation_token,
          \ }).catch(lamp#rescue(v:null)) })
    let l:p = s:Promise.all(l:promises)
    let l:p = l:p.then({ responses -> s:on_responses(l:bufnr, responses) })
    let l:p = l:p.catch(lamp#rescue())
  endfunction
  call lamp#debounce('lamp#feature#signature_help:trigger_signature_help', { -> l:ctx.callback() }, 100)
endfunction

"
" s:on_responses
"
function! s:on_responses(bufnr, responses) abort
  if index(['i', 's'], mode()[0]) == -1
    return
  endif

  let l:contents = []
  for l:response in filter(a:responses, { k, v -> !empty(v) })
    let l:contents += s:get_contents(l:response)
  endfor

  if !empty(l:contents)
    let l:screenpos = lamp#view#floatwin#screenpos(line('.'), col('.'))
    call lamp#view#floatwin#show('signature_help', l:screenpos, l:contents, {
    \   'tooltip': v:true
    \ })
    call lamp#view#mode#insert_leave({ -> s:close_signature_help() })
  endif
endfunction

"
" s:get_contents
"
function! s:get_contents(response) abort
  let l:active_signature = get(a:response, 'activeSignature', 0)
  let l:active_parameter = get(a:response, 'activeParameter', 0)
  let l:signature = get(a:response.signatures, l:active_signature, v:null)
  if empty(l:signature)
    return []
  endif
  let l:parameter = get(get(l:signature, 'parameters', []), l:active_parameter, {})

  " parameter_doc
  let l:parameter_doc = ''
  if !empty(l:parameter) && has_key(l:parameter, 'documentation') && !empty(l:parameter.documentation)
    let l:parameter_doc = ''
    let l:parameter_doc .= '__' . s:get_parameter_label(l:signature, l:parameter) . '__'
    let l:parameter_doc .= ' - '
    let l:parameter_doc .= lamp#protocol#markup_content#to_string(l:parameter.documentation)
    let l:parameter_doc .= "\n"
  endif

  " signature label.
  let l:signature_label = l:signature.label
  if !empty(l:parameter)
    let l:signature_label = s:mark_active_parameter(l:signature.label, s:get_parameter_label(l:signature, l:parameter))
  endif

  let l:signature_doc = ''
  if has_key(l:signature, 'documentation')
    let l:signature_doc .= lamp#protocol#markup_content#to_string(l:signature.documentation)
  endif

  " signature_help
  let l:signature_help = ''
  if strlen(l:parameter_doc) > 0
    let l:signature_help .= l:parameter_doc
  endif
  if strlen(l:signature_doc) > 0
    let l:signature_help .= l:signature_doc
  endif

  return lamp#protocol#markup_content#normalize(l:signature_label) + lamp#protocol#markup_content#normalize(l:signature_help)
endfunction

"
" s:mark_active_parameter
"
function! s:mark_active_parameter(signature_label, parameter_label) abort
  if strlen(a:parameter_label) > 0
    return substitute(a:signature_label, '\V\(' . escape(a:parameter_label, '\') . '\)', '`\1`', 'g')
  endif
  return a:signature_label
endfunction

"
" s:get_parameter_label
"
function! s:get_parameter_label(signature, parameter) abort
  if type(a:parameter.label) == type([])
    return strcharpart(a:signature.label, a:parameter.label[0], a:parameter.label[1] - a:parameter.label[0])
  endif
  return a:parameter.label
endfunction

