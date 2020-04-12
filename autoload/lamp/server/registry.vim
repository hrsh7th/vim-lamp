let s:servers = {}
let s:server_per_filetype = {}

"
" lamp#server#registry#set
"
function! lamp#server#registry#set(server) abort
  call lamp#server#registry#unset(a:server.name)

  let s:servers[a:server.name] = a:server
  for l:filetype in a:server.filetypes
    if !has_key(s:server_per_filetype, l:filetype)
      let s:server_per_filetype[l:filetype] = []
    endif
    let s:server_per_filetype[l:filetype] += [a:server]
  endfor
endfunction

"
" lamp#server#registry#unset
"
function! lamp#server#registry#unset(server_name) abort
  let l:server = get(s:servers, a:server_name, {})
  if empty(l:server)
    return
  endif

  call remove(s:servers, l:server.name)

  for [l:filetype, l:servers] in items(s:server_per_filetype)
    let l:idx = index(l:servers, l:server)
    if l:idx >= 0
      call remove(l:servers, l:idx)
    endif
  endfor
endfunction

"
" lamp#server#registry#all
"
function! lamp#server#registry#all() abort
  return values(s:servers)
endfunction

"
" lamp#server#registry#get_by_name
"
function! lamp#server#registry#get_by_name(name) abort
  return get(s:servers, a:name, {})
endfunction

"
" lamp#server#registry#find_by_filetype
"
function! lamp#server#registry#find_by_filetype(filetype) abort
  return copy(get(s:server_per_filetype, a:filetype, []))
endfunction

