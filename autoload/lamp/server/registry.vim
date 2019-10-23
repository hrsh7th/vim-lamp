let s:servers = {}

function! lamp#server#registry#set(server) abort
  let s:servers[a:server.name] = a:server
endfunction

function! lamp#server#registry#all() abort
  return s:servers
endfunction

function! lamp#server#registry#get_by_name(name) abort
  return get(s:servers, a:name, {})
endfunction

function! lamp#server#registry#find_by_filetype(filetype) abort
  let l:servers = values(s:servers)
  let l:servers = filter(l:servers, { k, v -> index(v.filetypes, a:filetype) >= 0 })
  return l:servers
endfunction

