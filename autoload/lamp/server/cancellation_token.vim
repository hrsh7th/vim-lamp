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
  \   'listeners': []
  \ })
endfunction

"
" attach
"
function! s:CancellationToken.attach(listener) abort
  call add(self.listeners, a:listener)
endfunction

"
" cancel
"
function! s:CancellationToken.cancel() abort
  for l:i in range(0, len(self.listeners) - 1)
    call self.listeners[l:i]()
  endfor
endfunction

