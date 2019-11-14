let s:Promise = vital#lamp#import('Async.Promise')
let s:Floatwin  = lamp#view#floatwin#import()
let s:floatwin = s:Floatwin.new({ 'max_height': 12 })

function! lamp#feature#signature_help#init() abort
  augroup lamp#feature#signature_help
    autocmd!
    autocmd TextChangedI,TextChangedP,InsertEnter,InsertLeave * call s:trigger_signature_help()
  augroup END
endfunction

"
" s:trigger_signature_help
"
function! s:trigger_signature_help() abort
  let l:bufnr = bufnr('%')
  let l:servers = lamp#server#registry#find_by_filetype(&filetype)
  let l:servers = filter(l:servers, { k, v -> v.supports('capabilities.signatureHelpProvider') })
  if empty(l:servers)
    call lamp#debounce('lamp#feature#signature_help:trigger_signature_help', { -> {} }, 0)
    return
  endif

  call s:floatwin.hide()

  " gather trigger characters.
  let l:trigger_chars = []
  for l:server in l:servers
    let l:trigger_chars += l:server.capability.get_signature_help_trigger_characters()
  endfor


  " check trigger character.
  let l:charinfo = lamp#view#cursor#search_before_char(l:trigger_chars + [')'], 2)
  if index(l:trigger_chars, l:charinfo[0]) == -1
    call lamp#debounce('lamp#feature#signature_help:trigger_signature_help', { -> {} }, 0)
    return
  endif

  let l:fn = {}
  function! l:fn.debounce(bufnr, servers) abort
    if mode()[0] !=# 'i'
      call lamp#debounce('lamp#feature#signature_help:trigger_signature_help', { -> {} }, 0)
      return
    endif

    let l:promises = map(a:servers, { k, v -> v.request('textDocument/signatureHelp', {
          \   'textDocument': lamp#protocol#document#identifier(a:bufnr),
          \   'position': lamp#protocol#position#get()
          \ }).catch(lamp#rescue(v:null)) })
    let l:p = s:Promise.all(l:promises)
    let l:p = l:p.then({ responses -> s:on_responses(a:bufnr, responses) })
    let l:p = l:p.catch(lamp#rescue())
  endfunction
  call lamp#debounce('lamp#feature#signature_help:trigger_signature_help', { -> l:fn.debounce(l:bufnr, l:servers) }, 500)
endfunction

"
" s:on_responses
"
function! s:on_responses(bufnr, responses) abort
  let l:lines = []
  for l:response in filter(a:responses, { k, v -> !empty(v) })
    for l:content in s:get_contents(l:response)
      let l:lines += l:content.lines
    endfor
  endfor

  if !empty(l:lines)
    let l:screenpos = lamp#view#floatwin#screenpos(line('.'), col('.'))
    call s:floatwin.show_tooltip(l:screenpos, [{ 'lines': l:lines }])
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

  let l:contents = []

  " parameter_doc
  let l:parameter_doc = ''
  if !empty(l:parameter) && has_key(l:parameter, 'documentation')
    let l:parameter_doc = ''
    let l:parameter_doc .= '**' . s:get_parameter_label(l:signature, l:parameter) . '**'
    let l:parameter_doc .= ' - '
    let l:parameter_doc .= lamp#protocol#markup_content#to_string(l:parameter.documentation)
    let l:parameter_doc .= "\n"
  endif

  " signature label.
  let l:signature_label = l:signature.label . "\n"
  if !empty(l:parameter)
    let l:signature_label = s:mark_active_parameter(l:signature.label, s:get_parameter_label(l:signature, l:parameter))
  endif

  let l:signature_doc = ''
  if has_key(l:signature, 'documentation')
    let l:signature_doc .= lamp#protocol#markup_content#to_string(l:signature.documentation) . "\n"
  endif

  " signature_help
  let l:signature_help = ''
  let l:signature_help .= lamp#protocol#markup_content#to_string(l:signature_label)
  let l:signature_help .= "\n"
  let l:signature_help .= l:parameter_doc
  let l:signature_help .= "\n"
  let l:signature_help .= l:signature_doc

  return lamp#protocol#markup_content#normalize(l:signature_help)
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

