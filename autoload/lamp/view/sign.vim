let s:initialized = v:false

let s:sign_group = 'lamp'

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

function! lamp#view#sign#error(bufnr, lnum) abort
  return s:sign_place('LampSignError', a:bufnr, a:lnum)
endfunction

function! lamp#view#sign#warning(bufnr, lnum) abort
  return s:sign_place('LampSignWarning', a:bufnr, a:lnum)
endfunction

function! lamp#view#sign#information(bufnr, lnum) abort
  return s:sign_place('LampSignInformation', a:bufnr, a:lnum)
endfunction

function! lamp#view#sign#hint(bufnr, lnum) abort
  return s:sign_place('LampSignHint', a:bufnr, a:lnum)
endfunction

function! s:sign_place(name, bufnr, lnum) abort
  call s:initialize()
  return sign_place(0, s:sign_group, a:name, a:bufnr, { 'lnum': a:lnum, 'priority': 1000 })
endfunction

function! s:initialize() abort
  if s:initialized
    return
  endif

  let l:sign_column_bg = synIDattr(hlID('SignColumn'), 'bg')
  let l:sign_column_guibg = empty(l:sign_column_bg) ? printf('guibg=%s', l:sign_column_bg) : ''
  execute printf('highlight! lampSignError guifg=red %s', l:sign_column_guibg)
  execute printf('highlight! lampSignWarning guifg=yellow %s', l:sign_column_guibg)
  execute printf('highlight! lampSignInformation guifg=white %s', l:sign_column_guibg)
  execute printf('highlight! lampSignHint guifg=white %s', l:sign_column_guibg)

  call sign_define('LampSignError', { 'text': 'x', 'texthl': 'lampSignError', 'linehl': 'SignColumn' })
  call sign_define('LampSignWarning', { 'text': '!', 'texthl': 'lampSignWarning', 'linehl': 'SignColumn' })
  call sign_define('LampSignInformation', { 'text': 'i', 'texthl': 'lampSignInformation', 'linehl': 'SignColumn' })
  call sign_define('LampSignHint', { 'text': '?', 'texthl': 'lampSignHint', 'linehl': 'SignColumn' })
endfunction

