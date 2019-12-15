let s:initialized = v:false

let s:sign_group = 'lamp'

"
" lamp#view#sign#get_line
"
function! lamp#view#sign#get_line(bufnr, lnum) abort
  let l:signs = get(sign_getplaced(a:bufnr, {
        \   'group': s:sign_group,
        \   'lnum': a:lnum
        \ }), 0, {})
  return get(l:signs, 'signs', [])
endfunction

"
" lamp#view#sign#remove
"
function! lamp#view#sign#remove(...) abort
  call s:initialize()
  if len(a:000) > 0 
    call sign_unplace(s:sign_group, {
          \   'buffer': a:000[0]
          \ })
  else
    call sign_unplace(s:sign_group)
  endif
endfunction

"
" lamp#view#sign#error
"
function! lamp#view#sign#error(bufnr, lnum) abort
  return s:sign_place('LampSignError', a:bufnr, a:lnum)
endfunction

"
" lamp#view#sign#warning
"
function! lamp#view#sign#warning(bufnr, lnum) abort
  return s:sign_place('LampSignWarning', a:bufnr, a:lnum)
endfunction

"
" lamp#view#sign#information
"
function! lamp#view#sign#information(bufnr, lnum) abort
  return s:sign_place('LampSignInformation', a:bufnr, a:lnum)
endfunction

"
" lamp#view#sign#hint
"
function! lamp#view#sign#hint(bufnr, lnum) abort
  return s:sign_place('LampSignHint', a:bufnr, a:lnum)
endfunction

"
" sign_place
"
function! s:sign_place(name, bufnr, lnum) abort
  call lamp#log('[CALL] lamp#view#sign s:sign_place')
  call s:initialize()
  try
    return sign_place(0, s:sign_group, a:name, a:bufnr, { 'lnum': a:lnum, 'priority': 1000 })
  catch /.*/
    call lamp#log('[ERROR]', { 'excption': v:exception, 'throwpoint': v:throwpoint })
  endtry
endfunction

"
" initialize
"
function! s:initialize() abort
  if s:initialized
    return
  endif

  let l:sign_column_bg = synIDattr(hlID('SignColumn'), 'bg', 'gui')
  let l:sign_column_guibg = !empty(l:sign_column_bg) ? printf('guibg=%s', l:sign_column_bg) : ''
  execute printf('highlight! LampSignError guifg=red %s', l:sign_column_guibg)
  execute printf('highlight! LampSignWarning guifg=yellow %s', l:sign_column_guibg)
  execute printf('highlight! LampSignInformation guifg=white %s', l:sign_column_guibg)
  execute printf('highlight! LampSignHint guifg=white %s', l:sign_column_guibg)

  call sign_define('LampSignError', {
        \   'text': lamp#config('view.sign.error.text'),
        \   'texthl': 'LampSignError',
        \   'linehl': 'SignColumn'
        \ })
  call sign_define('LampSignWarning', {
        \   'text': lamp#config('view.sign.warning.text'),
        \   'texthl': 'LampSignWarning',
        \   'linehl': 'SignColumn'
        \ })
  call sign_define('LampSignInformation', {
        \   'text': lamp#config('view.sign.information.text'),
        \   'texthl': 'LampSignInformation',
        \   'linehl': 'SignColumn'
        \ })
  call sign_define('LampSignHint', {
        \   'text': lamp#config('view.sign.hint.text'),
        \   'texthl': 'LampSignHint',
        \   'linehl': 'SignColumn'
        \ })
endfunction

