"
" lamp#view#sign#remove
"
function! lamp#view#sign#remove(namespace, bufnr) abort
  try
    call sign_unplace(a:namespace, {
    \   'buffer': a:bufnr
    \ })
  catch /.*/
    call lamp#log('[ERROR]', { 'exception': v:exception, 'throwpoint': v:throwpoint })
  endtry
endfunction

"
" lamp#view#sign#error
"
function! lamp#view#sign#error(namespace, bufnr, lnum) abort
  return s:sign_place(a:namespace, a:bufnr, a:lnum, 'LampSignError')
endfunction

"
" lamp#view#sign#warning
"
function! lamp#view#sign#warning(namespace, bufnr, lnum) abort
  return s:sign_place(a:namespace, a:bufnr, a:lnum, 'LampSignWarning')
endfunction

"
" lamp#view#sign#information
"
function! lamp#view#sign#information(namespace, bufnr, lnum) abort
  return s:sign_place(a:namespace, a:bufnr, a:lnum, 'LampSignInformation')
endfunction

"
" lamp#view#sign#hint
"
function! lamp#view#sign#hint(namespace, bufnr, lnum) abort
  return s:sign_place(a:namespace, a:bufnr, a:lnum, 'LampSignHint')
endfunction

"
" sign_place
"
function! s:sign_place(namespace, bufnr, lnum, highlight) abort
  try
    return sign_place(
          \   0,
          \   a:namespace,
          \   a:highlight,
          \   a:bufnr,
          \   {
          \     'lnum': a:lnum,
          \     'priority': 1000
          \   }
          \ )
  catch /.*/
    call lamp#log('[ERROR]', { 'excption': v:exception, 'throwpoint': v:throwpoint })
  endtry
endfunction

"
" initialize
"
function! s:initialize() abort
  let l:sign_column_bg = synIDattr(hlID('SignColumn'), 'bg', 'gui')
  let l:sign_column_guibg = !empty(l:sign_column_bg) ? printf('guibg=%s', l:sign_column_bg) : ''
  execute printf('highlight! LampSignError guifg=red %s', l:sign_column_guibg)
  execute printf('highlight! LampSignWarning guifg=yellow %s', l:sign_column_guibg)
  execute printf('highlight! LampSignInformation guifg=white %s', l:sign_column_guibg)
  execute printf('highlight! LampSignHint guifg=white %s', l:sign_column_guibg)

  call sign_define('LampSignError', {
        \   'text': lamp#config('view.sign.error.text'),
        \   'texthl': 'LampSignError',
        \   'numhl': 'LampSignError',
        \ })
  call sign_define('LampSignWarning', {
        \   'text': lamp#config('view.sign.warning.text'),
        \   'texthl': 'LampSignWarning',
        \   'numhl': 'LampSignWarning',
        \ })
  call sign_define('LampSignInformation', {
        \   'text': lamp#config('view.sign.information.text'),
        \   'texthl': 'LampSignInformation',
        \   'numhl': 'LampSignInformation',
        \ })
  call sign_define('LampSignHint', {
        \   'text': lamp#config('view.sign.hint.text'),
        \   'texthl': 'LampSignHint',
        \   'numhl': 'LampSignHint',
        \ })
endfunction
call s:initialize()

