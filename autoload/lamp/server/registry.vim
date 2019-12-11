let s:servers = {}

"
" lamp#server#registry#set
"
function! lamp#server#registry#set(server) abort
  let s:servers[a:server.name] = a:server
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
  let l:servers = values(s:servers)
  let l:servers = filter(l:servers, { k, v -> index(v.filetypes, a:filetype) >= 0 })
  return l:servers
endfunction

