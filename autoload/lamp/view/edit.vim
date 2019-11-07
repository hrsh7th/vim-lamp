"
" lamp#view#edit#normalize_workspace_edit
"
function! lamp#view#edit#normalize_workspace_edit(workspace_edit) abort
  let l:changes = {}

  " support changes.
  if has_key(a:workspace_edit, 'changes')
    let l:changes = copy(a:workspace_edit.changes)
  endif

  " support document changes.
  if has_key(a:workspace_edit, 'documentChanges')
    for l:edit in a:workspace_edit.documentChanges
      if has_key(l:edit, 'edits')
        if !has_key(l:changes, l:edit.textDocument.uri)
          let l:changes[l:edit.textDocument.uri] = []
        endif
        let l:changes[l:edit.textDocument.uri] += l:edit.edits
      endif
    endfor
  endif

  return l:changes
endfunction

"
" lamp#view#edit#apply_workspace
"
function! lamp#view#edit#apply_workspace(workspace_edit) abort
  for [l:uri, l:edits] in items(a:workspace_edit)
    let l:bufnr = bufnr(lamp#protocol#document#decode_uri(l:uri), v:true)
    if !bufloaded(l:bufnr)
      call bufload(l:bufnr)
      call setbufvar(l:bufnr, '&buflisted', v:true)
    endif
    call lamp#view#edit#apply(l:bufnr, l:edits)
  endfor
endfunction

"
" lamp#view#edit#apply
"
function! lamp#view#edit#apply(bufnr, edits) abort
  let l:edits = a:edits
  let l:edits = s:range(l:edits)
  let l:edits = s:sort(l:edits)
  let l:edits = s:overlap(l:edits)

  " apply edit.
  let l:position = lamp#protocol#position#to_vim(lamp#protocol#position#get())
  for l:edit in reverse(copy(l:edits))
    call s:edit(a:bufnr, l:edit, l:position)
  endfor

  if bufnr('%') == a:bufnr
    " adjust curops.
    call setpos('.', [a:bufnr, l:position.line, l:position.character])
  else
    " fire TextChanged.
    call lamp#view#buffer#touch(a:bufnr)
  endif
endfunction

"
" s:edit
"
function! s:edit(bufnr, edit, position) abort
  let l:start_line = getbufline(a:bufnr, a:edit.range.start.line)[0]
  let l:before_line = strcharpart(l:start_line, 0, a:edit.range.start.character - 1)
  let l:end_line = getbufline(a:bufnr, a:edit.range.end.line)[0]
  let l:after_line = strcharpart(l:end_line, a:edit.range.end.character - 1, strchars(l:end_line) - (a:edit.range.end.character - 1))

  let l:lines = split(a:edit.newText, "\n", v:true)
  let l:lines[0] = l:before_line . l:lines[0]
  let l:lines[-1] = l:lines[-1] . l:after_line

  let l:lines_len = len(l:lines)
  let l:range_len = a:edit.range.end.line - a:edit.range.start.line

  " fix cursor pos
  if a:edit.range.end.line <= a:position.line
    if a:edit.range.end.line == a:position.line
      if a:position.character <= a:edit.range.end.character
        let a:position.character = a:edit.range.end.character
      else
        let a:position.character = a:position.character + (strchars(l:lines[-1]) - strchars(l:after_line))
      endif
    endif

    let a:position.line += l:lines_len - l:range_len - 1
  endif

  " update or append.
  let l:i = 0
  while l:i < l:lines_len
    let l:lnum = a:edit.range.start.line + l:i
    if l:i <= l:range_len
      if get(getbufline(a:bufnr, l:lnum), 0) !=# l:lines[l:i]
        call setbufline(a:bufnr, l:lnum, l:lines[l:i])
      endif
    else
      call appendbufline(a:bufnr, l:lnum - 1, l:lines[l:i])
    endif
    let l:i += 1
  endwhile

  " delete.
  if l:lines_len <= l:range_len
    let l:start = a:edit.range.end.line - (l:range_len - l:lines_len)
    let l:end = a:edit.range.end.line
    call deletebufline(a:bufnr, l:start, l:end)
  endif
endfunction

"
" s:range
"
function! s:range(edits) abort
  let l:edits = []
  for l:edit in a:edits
    let l:range = lamp#protocol#range#to_vim(l:edit.range)
    if l:range.start.line > l:range.end.line || (
          \   l:range.start.line == l:range.end.line &&
          \   l:range.start.character > l:range.end.character
          \ )
      let l:range = {
            \   'start': l:range.end,
            \   'end': l:range.start
            \ }
    endif
    call add(l:edits, {
          \   'range': l:range,
          \   'newText': l:edit.newText
          \ })
  endfor
  return l:edits
endfunction

"
" s:sort
"
function! s:sort(edits) abort
  function! s:compare(edit1, edit2) abort
    let l:diff = a:edit1.range.start.line - a:edit2.range.start.line
    if l:diff == 0
      return a:edit1.range.start.character - a:edit2.range.start.character
    endif
    return l:diff
  endfunction
  return sort(copy(a:edits), function('s:compare', [], {}))
endfunction

"
" s:overlap
"
function! s:overlap(edits) abort
  if len(a:edits) > 1
    let l:range = a:edits[0].range
    for l:edit in a:edits[1 : -1]
      if l:range.end.line > l:edit.range.start.line || (
            \   l:range.end.line == l:edit.range.start.line &&
            \   l:range.end.character > l:edit.range.start.character
            \ )
        throw 'lamp#view#edit#apply: range overlapped.'
      endif

      let l:range = l:edit.range
    endfor
  endif
  return a:edits
endfunction

