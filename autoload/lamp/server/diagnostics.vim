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
  \   'changedtick': -1,
  \   'applied_version': 0,
  \   'diagnostics': a:args.diagnostics,
  \   'applied_diagnostics': [],
  \ })
endfunction

"
" set
"
function! s:Diagnostics.set(diagnostics) abort
  let self.version += 1
  let self.changedtick = getbufvar(self.bufname, 'changedtick', -1)
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
function! s:Diagnostics.updated() abort
  if !bufexists(self.bufname)
    return v:false
  endif
  return self.applied_version != self.version && (self.changedtick == -1 || self.changedtick == getbufvar(self.bufname, 'changedtick', -1))
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

