let s:Position = vital#lamp#import('VS.LSP.Position')

let s:context = v:null
let s:processing = v:false

"
" [bufnr]: {
"   [v:char]: Server
" }
"
let s:cache = {}

"
" lamp#feature#on_type_formatting#init
"
function! lamp#feature#on_type_formatting#init() abort
  execute printf('augroup lamp#feature#on_type_formatting_%d', bufnr('%'))
    autocmd!
    autocmd User lamp#server#initialized call s:clear_cache()
    autocmd User lamp#server#exited call s:clear_cache()
    autocmd InsertCharPre <buffer> call s:on_insert_char_pre()
  augroup END
endfunction

"
" clear_cache
"
function! s:clear_cache() abort
  let s:cache = {}
endfunction

"
" on_type
"
function! s:on_type(char, default) abort
  let v:char = a:char
  call s:on_insert_char_pre()
  if empty(s:context)
    return a:default
  endif
  return ''
endfunction

"
" on_insert_char_pre
"
function! s:on_insert_char_pre() abort
  if empty(v:char) || s:processing
    return
  endif

  let s:context = s:get_on_type_formatting_context(bufnr('%'), v:char)
  if empty(s:context)
    return
  endif
  let s:context.original_char = v:char

  " Ignore other plugin's feature.
  let s:processing = v:true
  let v:char = ''
  call feedkeys(s:context.original_char, 'ni')
  call feedkeys("\<Plug>(lamp-on-type-formatting:formatting)", '')
  call feedkeys("\<Plug>(lamp-on-type-formatting:finish)", '')
endfunction

"
" on_insert_char_pre_after
"
inoremap <silent><nowait> <Plug>(lamp-on-type-formatting:formatting) <C-r>=<SID>formatting()<CR>
function! s:formatting() abort
  try
    let l:edits = lamp#sync(s:context.server.request('textDocument/onTypeFormatting', {
    \   'textDocument': lamp#protocol#document#identifier(bufnr('%')),
    \   'position': s:Position.cursor(),
    \   'ch': s:context.char,
    \   'options': {
    \     'tabSize': lamp#view#buffer#get_indent_size(),
    \     'insertSpaces': &expandtab ? v:true : v:false
    \   }
    \ }), 200)

    if !empty(l:edits)
      call lamp#view#edit#apply(bufnr('%'), l:edits)
    endif
  catch /.*/
    call lamp#log('[ERROR]', { 'exception': v:exception, 'throwpoint': v:throwpoint })
  endtry

  return ''
endfunction
"
" finish
"
inoremap <silent><nowait> <Plug>(lamp-on-type-formatting:finish) <C-r>=<SID>finish()<CR>
function! s:finish() abort
  let s:processing = v:false
  return ''
endfunction

"
" get_on_type_formatting_context
"
function! s:get_on_type_formatting_context(bufnr, char) abort
  if has_key(s:cache, a:bufnr) && has_key(s:cache[a:bufnr], a:char)
    return s:cache[a:bufnr][a:char]
  endif

  let s:cache[a:bufnr] = get(s:cache, a:bufnr, {})
  let s:cache[a:bufnr][a:char] = v:null

  for l:server in lamp#server#registry#find_by_filetype(&filetype)
    let l:chars = l:server.capability.get_on_type_formatting_trigger_characters()

    if index(l:chars, a:char) != -1
      let s:cache[a:bufnr][a:char] = { 'server': l:server, 'char': a:char }
      break
    elseif a:char ==# "\<CR>"
      if index(l:chars, "\n") != -1
        let s:cache[a:bufnr][a:char] = { 'server': l:server, 'char': "\n" }
      elseif index(l:chars, "\r") != -1
        let s:cache[a:bufnr][a:char] = { 'server': l:server, 'char': "\r" }
      elseif index(l:chars, "\r\n") != -1
        let s:cache[a:bufnr][a:char] = { 'server': l:server, 'char': "\r\n" }
      endif
      break
    endif
  endfor

  return s:cache[a:bufnr][a:char]
endfunction

