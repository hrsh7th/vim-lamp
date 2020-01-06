"
" lamp#view#diff#compat#import
"
function! lamp#view#diff#compat#import() abort
  return s:Diff
endfunction


let s:Diff = {
      \   'type': 'compat'
      \ }

"
" new
"
function! s:Diff.new() abort
  return extend(deepcopy(s:Diff), {
        \   'type': 'compat',
        \   'bufs': {}
        \ })
endfunction

"
" attach
"
function! s:Diff.attach(bufnr) abort
  if has_key(self.bufs, a:bufnr)
    call self.detach(a:bufnr)
  endif

  let self.bufs[a:bufnr] = {
        \   'lines': lamp#view#buffer#get_lines(a:bufnr),
        \ }
endfunction

"
" detach
"
function! s:Diff.detach(bufnr) abort
  if has_key(self.bufs, a:bufnr)
    unlet self.bufs[a:bufnr]
  endif
endfunction

"
" sync
"
function! s:Diff.sync(bufnr) abort
  if has_key(self.bufs, a:bufnr)
    let self.bufs[a:bufnr].lines = lamp#view#buffer#get_lines(a:bufnr)
  endif
endfunction

"
" flush
"
function! s:Diff.flush(bufnr) abort
  " noop
endfunction

"
" get_lines
"
function! s:Diff.get_lines(bufnr) abort
  if !has_key(self.bufs, a:bufnr)
    return lamp#view#buffer#get_lines(a:bufnr)
  endif
  return self.bufs[a:bufnr].lines
endfunction

"
" compute
"
function! s:Diff.compute(bufnr) abort
  if !has_key(self.bufs, a:bufnr)
    throw 'diffkit: invalid bufnr.'
  endif

  let l:old = self.bufs[a:bufnr].lines
  let l:new = lamp#view#buffer#get_lines(a:bufnr)
  let self.bufs[a:bufnr].lines = l:new
  return lamp#view#diff#compute(l:old, l:new)
endfunction

