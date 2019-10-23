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
  return s:sign_place('lampSignError', a:bufnr, a:lnum)
endfunction

function! lamp#view#sign#warning(bufnr, lnum) abort
  return s:sign_place('lampSignWarning', a:bufnr, a:lnum)
endfunction

function! lamp#view#sign#information(bufnr, lnum) abort
  return s:sign_place('lampSignInformation', a:bufnr, a:lnum)
endfunction

function! lamp#view#sign#hint(bufnr, lnum) abort
  return s:sign_place('lampSignHint', a:bufnr, a:lnum)
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
  execute printf('highlight! lampSignError guifg=red guibg=%s', l:sign_column_bg)
  execute printf('highlight! lampSignWarning guifg=yellow guibg=%s', l:sign_column_bg)
  execute printf('highlight! lampSignInformation guifg=white guibg=%s', l:sign_column_bg)
  execute printf('highlight! lampSignHint guifg=white guibg=%s', l:sign_column_bg)

  call sign_define('lampSignError', { 'text': 'x', 'texthl': 'lampSignError', 'linehl': 'SignColumn' })
  call sign_define('lampSignWarning', { 'text': '!', 'texthl': 'lampSignWarning', 'linehl': 'SignColumn' })
  call sign_define('lampSignInformation', { 'text': 'i', 'texthl': 'lampSignInformation', 'linehl': 'SignColumn' })
  call sign_define('lampSignHint', { 'text': '?', 'texthl': 'lampSignHint', 'linehl': 'SignColumn' })
endfunction

