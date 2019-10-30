function! lamp#view#floatwin#import() abort
  if has('nvim')
    return lamp#view#floatwin#nvim#import()
  endif
    return lamp#view#floatwin#vim#import()
endfunction

