"
" lamp#view#floatwin#vim#show
"
function! lamp#view#floatwin#vim#show(floatwin) abort
  if lamp#view#floatwin#vim#is_showing(a:floatwin)
    call popup_move(a:floatwin.vim_winid, s:get_config(a:floatwin))
  else
    let a:floatwin.vim_winid = popup_create(a:floatwin.bufnr, s:get_config(a:floatwin))
  endif
endfunction

"
" lamp#view#floatwin#vim#hide
"
function! lamp#view#floatwin#vim#hide(floatwin) abort
  try
    call popup_hide(a:floatwin.vim_winid)
  catch /.*/
  endtry
  let a:floatwin.vim_winid = v:null
endfunction

"
" lamp#view#floatwin#vim#write
"
function! lamp#view#floatwin#vim#write(floatwin, lines) abort
  call deletebufline(a:floatwin.bufnr, '^', '$')
  for l:line in reverse(a:lines)
    call appendbufline(a:floatwin.bufnr, 0, l:line)
  endfor
  call deletebufline(a:floatwin.bufnr, '$')
endfunction

"
" lamp#view#floatwin#vim#enter
"
function! lamp#view#floatwin#vim#enter(floatwin) abort
  " noop
endfunction

"
" lamp#view#floatwin#vim#is_showing
"
function! lamp#view#floatwin#vim#is_showing(floatwin) abort
  if !has_key(a:floatwin, 'vim_winid') || a:floatwin.vim_winid is v:null
    return v:false
  endif

  if win_id2win(a:floatwin.vim_winid) == -1
    let a:floatwin.vim_winid = v:null
    return v:false
  endif
  return v:true
endfunction

"
" lamp#view#floatwin#vim#winid
"
function! lamp#view#floatwin#vim#winid(floatwin) abort
  if lamp#view#floatwin#vim#is_showing(a:floatwin)
    return a:floatwin.vim_winid
  endif
  return -1
endfunction

"
" s:get_config
"
function! s:get_config(floatwin) abort
  return {
        \   'line': a:floatwin.screenpos[0] + 1,
        \   'col':  a:floatwin.screenpos[1] + 1,
        \   'pos': 'topleft',
        \   'moved': [0, 0, 0],
        \   'scrollbar': 0,
        \   'maxwidth': a:floatwin.get_width(a:floatwin.contents),
        \   'maxheight': a:floatwin.get_height(a:floatwin.contents),
        \   'minwidth': a:floatwin.get_width(a:floatwin.contents),
        \   'minheight': a:floatwin.get_height(a:floatwin.contents),
        \   'tabpage': 0
        \ }
endfunction

