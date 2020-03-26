"
" NOTE: LSP spec says diagnostics has possibility to contain unmanaged file related.
"
" So `bufexists(s:Diagnostics.bufname)` may returns false, we should care about it.
"

"
" lamp#server#diagnostics#import
"
function! lamp#server#diagnostics#import() abort
  return s:Diagnostics
endfunction

let s:Diagnostics = {}

"
" new
"
function! s:Diagnostics.new(args) abort
  return extend(deepcopy(s:Diagnostics), {
  \   'uri': a:args.uri,
  \   'bufname': lamp#protocol#document#decode_uri(a:args.uri),
  \   'version': 0,
  \   'document_version': a:args.document_version,
  \   'applied_version': 0,
  \   'diagnostics': a:args.diagnostics,
  \   'applied_diagnostics': [],
  \ })
endfunction

"
" set
"
function! s:Diagnostics.set(diagnostics, document_version) abort
  let l:old_len = len(self.applied_diagnostics)
  let l:new_len = len(a:diagnostics)

  let self.version += 1
  let self.document_version = a:document_version
  let self.diagnostics = a:diagnostics
endfunction

"
" is_shown
"
function! s:Diagnostics.is_shown() abort
  return len(win_findbuf(bufnr(self.bufname))) > 0
endfunction

"
" updated
"
function! s:Diagnostics.updated(document_version) abort
  if !bufexists(self.bufname)
    return v:false
  endif
  return self.applied_version != self.version && (self.document_version == -1 || self.document_version == a:document_version)
endfunction

"
" is_decreased
"
function! s:Diagnostics.is_decreased() abort
  return len(self.applied_diagnostics) >= len(self.diagnostics)
endfunction

"
" applied
"
function! s:Diagnostics.applied() abort
  let self.applied_diagnostics = copy(self.diagnostics)
  let self.applied_version = self.version
endfunction

