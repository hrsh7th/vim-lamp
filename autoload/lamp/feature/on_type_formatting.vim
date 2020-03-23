let s:Position = vital#lamp#import('VS.LSP.Position')

let s:char = v:null

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
  augroup lamp#feature#on_type_formatting
    autocmd!
    autocmd User lamp#server#initialized call s:clear_cache()
    autocmd User lamp#server#exited call s:clear_cache()
    autocmd InsertCharPre * call s:on_insert_char_pre()
  augroup END
endfunction

"
" clear_cache
"
function! s:clear_cache() abort
  let s:cache = {}
endfunction

"
" on_insert_char_pre
"
function! s:on_insert_char_pre() abort
  if empty(v:char)
    return
  endif

  let l:server = s:get_server(bufnr('%'), v:char)
  if empty(l:server)
    return
  endif

  let s:char = v:char
  call feedkeys("\<Plug>(lamp-on-type-formatting:insert_char_pre_after)", '')
endfunction

"
" on_insert_char_pre_after
"
inoremap <silent><nowait> <Plug>(lamp-on-type-formatting:insert_char_pre_after) <C-r>=<SID>on_insert_char_pre_after()<CR>
function! s:on_insert_char_pre_after() abort
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
    \ }))

    if !empty(l:edits)
      call lamp#view#edit#apply(bufnr('%'), l:edits)
    endif
  catch /.*/
  endtry

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

