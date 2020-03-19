"
" lamp#server#document#import
"
function! lamp#server#document#import() abort
  return s:Document
endfunction

let s:Document = {}

"
" new
"
function! s:Document.new(bufnr) abort
  return extend(deepcopy(s:Document), {
        \   'uri': lamp#protocol#document#encode_uri(a:bufnr),
        \   'bufnr': a:bufnr,
        \   'filetype': getbufvar(a:bufnr, '&filetype'),
        \   'language_id': lamp#protocol#document#language_id(a:bufnr),
        \   'changedtick': getbufvar(a:bufnr, 'changedtick'),
        \   'dianostics_decreased': v:false,
        \   'diagnostics': [],
        \ })
endfunction

"
" get_changedtick
"
function! s:Document.get_changedtick() abort
  return getbufvar(self.bufnr, 'changedtick')
endfunction

"
" sync
"
function! s:Document.sync() abort
  let self.changedtick = getbufvar(self.bufnr, 'changedtick')
endfunction

"
" out_of_date
"
function! s:Document.out_of_date() abort
  return self.changedtick != getbufvar(self.bufnr, 'changedtick')
endfunction

"
" set_diagnostics
"
function! s:Document.set_diagnostics(diagnostics) abort
  let self.diagnostics_decreased = len(a:diagnostics) < len(self.diagnostics)
  let self.diagnostics = a:diagnostics
endfunction

