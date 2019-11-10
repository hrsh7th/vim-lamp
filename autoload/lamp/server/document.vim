"
" Create document instance.
"
function! lamp#server#document#import() abort
  return s:Document
endfunction

let s:Document = {}

"
" new.
"
function! s:Document.new(bufnr) abort
  return extend(deepcopy(s:Document), {
        \   'uri': lamp#protocol#document#encode_uri(a:bufnr),
        \   'bufnr': a:bufnr,
        \   'buffer': getbufline(a:bufnr, '^', '$'),
        \   'filetype': getbufvar(a:bufnr, '&filetype'),
        \   'language_id': lamp#protocol#document#language_id(a:bufnr),
        \   'changedtick': getbufvar(a:bufnr, 'changedtick'),
        \   'diagnostics': [],
        \ })
endfunction

"
" diff.
"
function! s:Document.diff() abort
  return lamp#server#document#diff#compute(self.buffer, getbufline(self.bufnr, '^', '$'))
endfunction

"
" Sync.
"
function! s:Document.sync() abort
  let self.buffer = getbufline(self.bufnr, '^', '$')
  let self.changedtick = getbufvar(self.bufnr, 'changedtick')
endfunction

"
" out of date.
"
function! s:Document.out_of_date() abort
  return self.changedtick != getbufvar(self.bufnr, 'changedtick')
endfunction

"
" set_diagnostics.
"
function! s:Document.set_diagnostics(diagnostics) abort
  let self.diagnostics = a:diagnostics
endfunction

