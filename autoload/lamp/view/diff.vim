let s:Diff = vital#lamp#import('VS.Text.Diff')

"
" lamp#view#diff#import
"
function! lamp#view#diff#import() abort
  if exists('g:lamp_experimental_incremental_diff') && exists('*listener_add')
    return lamp#view#diff#vim#import()
  endif
  if exists('g:lamp_experimental_incremental_diff') && has('nvim')
    return lamp#view#diff#nvim#import()
  endif
  return lamp#view#diff#compat#import()
endfunction

"
" lamp#view#diff#compute
"
function! lamp#view#diff#compute(old, new) abort
  return s:Diff.compute(a:old, a:new)
endfunction

