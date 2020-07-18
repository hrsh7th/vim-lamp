let s:Diff = vital#lamp#import('VS.Text.Diff')

"
" lamp#view#diff#import
"
function! lamp#view#diff#import() abort
  return lamp#view#diff#compat#import()
endfunction

"
" lamp#view#diff#compute
"
function! lamp#view#diff#compute(old, new) abort
  return s:Diff.compute(a:old, a:new)
endfunction

