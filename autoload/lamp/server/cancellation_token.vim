let s:id = 0

"
" lamp#server#cancellation_token#import
"
function! lamp#server#cancellation_token#import() abort
  return s:CancellationToken
endfunction

let s:CancellationToken = {}

"
" new
"
function! s:CancellationToken.new() abort
  return extend(deepcopy(s:CancellationToken), {
  \   '_canceled': v:false,
  \   '_listeners': []
  \ })
endfunction

"
" attach
"
function! s:CancellationToken.attach(listener) abort
  if self._canceled
    call a:listener()
    return
  endif
  call add(self._listeners, a:listener)
endfunction

"
" cancel
"
function! s:CancellationToken.cancel() abort
  if self._canceled
    return
  endif
  let self._canceled = v:true
  for l:i in range(0, len(self._listeners) - 1)
    call self._listeners[l:i]()
  endfor
endfunction

