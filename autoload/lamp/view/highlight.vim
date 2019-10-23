let s:initialized = v:false
let s:highlights = {}

"
" remove.
"
function! lamp#view#highlight#remove(bufnr) abort
  let l:winnr = bufwinnr(a:bufnr)
  if has_key(s:highlights, l:winnr)
    let l:current_winnr = winnr()
    for l:id in s:highlights[l:winnr]
      try
        execute printf('keepalt keepjumps %swindo call matchdelete(%s)', l:winnr, l:id)
      catch /.*/
      endtry
    endfor
    execute printf('%swincmd w', l:current_winnr)
    call remove(s:highlights, l:winnr)
  endif
endfunction

"
" error.
"
function! lamp#view#highlight#error(bufnr, range) abort
  call s:add_highlight('lampError', a:bufnr, a:range)
endfunction

"
" warning.
"
function! lamp#view#highlight#warning(bufnr, range) abort
  call s:add_highlight('lampWarning', a:bufnr, a:range)
endfunction

"
" information.
"
function! lamp#view#highlight#information(bufnr, range) abort
  call s:add_highlight('lampInformation', a:bufnr, a:range)
endfunction

"
" hint.
"
function! lamp#view#highlight#hint(bufnr, range) abort
  call s:add_highlight('lampHint', a:bufnr, a:range)
endfunction


"
" s:add_highlight
"
function! s:add_highlight(highlight, bufnr, range) abort
  call s:initialize()

  let l:winnr = bufwinnr(a:bufnr)
  if !has_key(s:highlights, l:winnr)
    let s:highlights[l:winnr] = []
  endif
  let s:highlights[l:winnr] += [matchaddpos(a:highlight, s:positions(a:bufnr, a:range), 100, -1, {
        \   'window': l:winnr
        \ })]
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

  execute printf('highlight! lampError guibg=darkred')
  execute printf('highlight! lampWarning guibg=darkmagenta')
  execute printf('highlight! lampInformation gui=underline')
  execute printf('highlight! lampHint gui=underline')
endfunction

