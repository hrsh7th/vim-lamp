function! lamp#view#tooltip#import() abort
  if has('nvim')
    return lamp#view#tooltip#nvim#import()
  endif
    return lamp#view#tooltip#vim#import()
endfunction

