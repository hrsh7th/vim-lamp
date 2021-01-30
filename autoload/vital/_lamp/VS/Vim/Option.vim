" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not modify the code nor insert new lines before '" ___vital___'
function! s:_SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
endfunction
execute join(['function! vital#_lamp#VS#Vim#Option#import() abort', printf("return map({'define': ''}, \"vital#_lamp#function('<SNR>%s_' . v:key)\")", s:_SID()), 'endfunction'], "\n")
delfunction s:_SID
" ___vital___
"
" define
"
function! s:define(map) abort
  let l:old = {}
  for [l:key, l:value] in items(a:map)
    let l:old[l:key] = eval(printf('&%s', l:key))
    execute printf('let &%s = "%s"', l:key, l:value)
  endfor
  return { -> s:define(l:old) }
endfunction

