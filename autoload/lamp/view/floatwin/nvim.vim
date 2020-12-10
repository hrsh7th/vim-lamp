"
" lamp#view#floatwin#nvim#show
"
function! lamp#view#floatwin#nvim#show(floatwin) abort
  if lamp#view#floatwin#nvim#is_showing(a:floatwin)
    call nvim_win_set_config(a:floatwin.nvim_window, s:get_config(a:floatwin))
  else
    let a:floatwin.nvim_window = nvim_open_win(a:floatwin.bufnr, v:false, s:get_config(a:floatwin))
  endif
endfunction

"
" lamp#view#floatwin#nvim#hide
"
function! lamp#view#floatwin#nvim#hide(floatwin) abort
  if lamp#view#floatwin#nvim#is_showing(a:floatwin)
    call nvim_win_close(a:floatwin.nvim_window, v:true)
    let a:floatwin.nvim_window = v:null
  endif
endfunction

"
" lamp#view#floatwin#nvim#write
"
function! lamp#view#floatwin#nvim#write(floatwin, lines) abort
  try
    call nvim_buf_set_lines(a:floatwin.bufnr, 0, -1, v:true, a:lines)
  catch /.*/
  endtry
endfunction

"
" lamp#view#floatwin#nvim#enter
"
function! lamp#view#floatwin#nvim#enter(floatwin) abort
  if lamp#view#floatwin#nvim#is_showing(a:floatwin)
    execute printf('keepalt keepjumps %swincmd w', win_id2win(lamp#view#floatwin#nvim#winid(a:floatwin)))
  endif
endfunction

"
" lamp#view#floatwin#nvim#is_showing
"
function! lamp#view#floatwin#nvim#is_showing(floatwin) abort
  if !has_key(a:floatwin,'nvim_window') || a:floatwin.nvim_window is v:null || !nvim_win_is_valid(a:floatwin.nvim_window)
    return v:false
  endif

  try
    return nvim_win_get_number(a:floatwin.nvim_window) != -1
  catch /.*/
    let a:floatwin.nvim_window = v:null
  endtry
  return v:false
endfunction

"
" lamp#view#floatwin#nvim#winid
"
function! lamp#view#floatwin#nvim#winid(floatwin) abort
  if lamp#view#floatwin#nvim#is_showing(a:floatwin)
    return win_getid(nvim_win_get_number(a:floatwin.nvim_window))
  endif
  return -1
endfunction

"
" s:get_config
"
function! s:get_config(floatwin) abort
  return {
        \   'relative': 'editor',
        \   'width': a:floatwin.get_width(a:floatwin.contents),
        \   'height': a:floatwin.get_height(a:floatwin.contents),
        \   'row': a:floatwin.screenpos[0],
        \   'col': a:floatwin.screenpos[1],
        \   'focusable': v:true,
        \   'style': 'minimal'
        \ }
endfunction

