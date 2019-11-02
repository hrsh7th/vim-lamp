let s:initialized = v:false
let s:highlights = {}

"
" remove.
"
function! lamp#view#highlight#remove(bufnr) abort
  for l:winid in win_findbuf(a:bufnr)
    call lamp#view#window#do(l:winid, { -> clearmatches() })
  endfor
endfunction

"
" error.
"
function! lamp#view#highlight#error(bufnr, range) abort
  call s:add_highlight('LampError', a:bufnr, a:range)
endfunction

"
" warning.
"
function! lamp#view#highlight#warning(bufnr, range) abort
  call s:add_highlight('LampWarning', a:bufnr, a:range)
endfunction

"
" information.
"
function! lamp#view#highlight#information(bufnr, range) abort
  call s:add_highlight('LampInformation', a:bufnr, a:range)
endfunction

"
" hint.
"
function! lamp#view#highlight#hint(bufnr, range) abort
  call s:add_highlight('LampHint', a:bufnr, a:range)
endfunction


"
" s:add_highlight
"
function! s:add_highlight(highlight, bufnr, range) abort
  call s:initialize()

  if !lamp#protocol#range#has_length(a:range)
    return
  endif

  for l:winid in win_findbuf(a:bufnr)
    call matchaddpos(a:highlight, s:positions(a:bufnr, a:range), 100, -1, { 'window': l:winid })
  endfor
endfunction

"
" s:positions => [[lnum, col-start, length]]
"
function! s:positions(bufnr, range) abort
  if a:range.end.character == 0
    let a:range.end.character = strlen(get(getbufline(a:bufnr, a:range.end.line), 0, ''))
    let a:range.end.line -= 1
  endif

  if a:range.start.line == a:range.end.line
    return [[a:range.start.line + 1, a:range.start.character + 1, a:range.end.character - a:range.start.character]]
  endif

  let l:positions = []
  for l:line in range(a:range.start.line, a:range.end.line)
    if a:range.start.line == l:line
      let l:bytes = strlen(get(getbufline(a:bufnr, a:range.start.line + 1), 0, ''))
      call add(l:positions, [l:line + 1, a:range.start.character + 1, l:bytes - a:range.start.character])
    elseif a:range.end.line == l:line
      call add(l:positions, [l:line + 1, 0, a:range.end.character])
    else
      call add(l:positions, l:line + 1)
    endif
  endfor
  return l:positions
endfunction

"
" s:initialize
"
function! s:initialize() abort
  if s:initialized
    return
  endif
  let s:initialized = v:true

  execute printf('highlight! LampError guibg=darkred')
  execute printf('highlight! LampWarning guibg=darkmagenta')
  execute printf('highlight! LampInformation gui=underline')
  execute printf('highlight! LampHint gui=underline')
endfunction

