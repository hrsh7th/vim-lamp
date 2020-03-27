let s:Position = vital#lamp#import('VS.LSP.Position')

let s:char = v:null
let s:block = v:false

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

    " TODO: support "\r\n" or "\r"?
    imap <expr><CR> <SID>on_char("\n")
  augroup END
endfunction

"
" clear_cache
"
function! s:clear_cache() abort
  let s:cache = {}
endfunction

"
" on_char
"
function! s:on_char(char) abort
  let v:char = a:char
  call s:on_insert_char_pre()
  if mapcheck(v:char, 'i')
    return maparg(v:char, 'i')
  endif
  return v:char
endfunction

"
" on_insert_char_pre
"
function! s:on_insert_char_pre() abort
  if empty(v:char) || s:block
    return
  endif

  let l:server = s:get_server(bufnr('%'), v:char)
  if empty(l:server)
    return
  endif

  let s:char = v:char
  let v:char = ''

  " Ignore other plugin's feature.
  let s:block = v:true
  call feedkeys(s:char, 'n')
  call feedkeys("\<Plug>(lamp-on-type-formatting:formatting)", '')
  call feedkeys("\<Plug>(lamp-on-type-formatting:finish)", '')
endfunction

"
" on_insert_char_pre_after
"
inoremap <silent><nowait> <Plug>(lamp-on-type-formatting:formatting) <C-r>=<SID>formatting()<CR>
function! s:formatting() abort
  let l:server = s:get_server(bufnr('%'), s:char)
  if empty(l:server)
    return ''
  endif

  try
    let l:edits = lamp#sync(l:server.request('textDocument/onTypeFormatting', {
    \   'textDocument': lamp#protocol#document#identifier(bufnr('%')),
    \   'position': s:Position.cursor(),
    \   'ch': s:char,
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
  let s:block = v:false
  return ''
endfunction

"
" get_server
"
function! s:get_server(bufnr, char) abort
  if has_key(s:cache, a:bufnr) && has_key(s:cache[a:bufnr], a:char)
    return s:cache[a:bufnr][a:char]
  endif

  let s:cache[a:bufnr] = get(s:cache, a:bufnr, {})
  let s:cache[a:bufnr][a:char] = v:null

  for l:server in lamp#server#registry#find_by_filetype(&filetype)
    let l:chars = l:server.capability.get_on_type_formatting_trigger_characters()
    if index(l:chars, a:char) != -1
      let s:cache[a:bufnr] = get(s:cache, a:bufnr, {})
      let s:cache[a:bufnr][a:char] = l:server
      break
    endif
  endfor

  return s:cache[a:bufnr][v:char]
endfunction

