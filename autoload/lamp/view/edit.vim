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
    try
      call lamp#view#edit#apply(l:bufnr, l:edits)
    catch /.*/
      call lamp#log('[ERROR]', json_encode({ 'exception': v:exception, 'throwpoint': v:throwpoint }))
    endtry
  endfor
endfunction

"
" lamp#view#edit#apply
"
function! lamp#view#edit#apply(bufnr, edits) abort
  let l:edits = a:edits
  let l:edits = lamp#view#edit#rangefix(l:edits)
  let l:edits = lamp#view#edit#sort(l:edits)
  let l:edits = lamp#view#edit#merge(l:edits)

  for l:edit in l:edits
    call s:edit(a:bufnr, l:edit)
  endfor

  if bufnr('%') != a:bufnr
    call lamp#view#buffer#touch(a:bufnr)
  endif
endfunction

"
" lamp#view#edit#rangefix
"
function! lamp#view#edit#rangefix(edits) abort
  let l:edits = []
  for l:edit in a:edits
    call add(l:edits, {
          \   'range': lamp#protocol#range#to_vim(l:edit.range),
          \   'newText': l:edit.newText
          \ })
  endfor
  return l:edits
endfunction

"
" lamp#view#edit#sort
"
function! lamp#view#edit#sort(edits) abort
  function! s:compare(edit1, edit2) abort
    if a:edit1.range.start.line < a:edit2.range.start.line
      return 1
    endif
    if a:edit1.range.start.line == a:edit2.range.start.line
      if a:edit1.range.start.character < a:edit2.range.start.character
        return 1
      endif
    endif
    return -1
  endfunction
  return sort(copy(a:edits), function('s:compare', [], {}))
endfunction

"
" lamp#view#edit#merge
"
function! lamp#view#edit#merge(edits) abort
  let l:edits = []

  let l:i = 0
  while l:i < len(a:edits)
    let l:edit_i = a:edits[l:i]

    let l:j = l:i + 1
    while l:j < len(a:edits)
      let l:edit_j = a:edits[l:j]
      if l:edit_i.range.start.line == l:edit_j.range.start.line
            \ && l:edit_i.range.start.character == l:edit_j.range.start.character
        let l:edit_i.newText .= l:edit_j.newText

        let l:j += 1
      else
        break
      endif
    endwhile

    let l:edits += [l:edit_i]
    let l:i = l:j
  endwhile

  return l:edits
endfunction

"
" s:edit
"
function! s:edit(bufnr, edit) abort
  let l:start_line = get(getbufline(a:bufnr, a:edit.range.start.line), 0, '')
  let l:before_line = strcharpart(l:start_line, 0, a:edit.range.start.character - 1)
  let l:end_line = get(getbufline(a:bufnr, a:edit.range.end.line), 0, '')
  let l:after_line = strcharpart(l:end_line, a:edit.range.end.character - 1, strchars(l:end_line) - (a:edit.range.end.character - 1))

  let l:lines = split(a:edit.newText, "\n", v:true)
  let l:lines[0] = l:before_line . l:lines[0]
  let l:lines[-1] = l:lines[-1] . l:after_line

  let l:lines_len = len(l:lines)
  let l:range_len = a:edit.range.end.line - a:edit.range.start.line

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

  if l:lines_len <= l:range_len
    let l:start = a:edit.range.end.line - (l:range_len - l:lines_len)
    let l:end = a:edit.range.end.line
    call deletebufline(a:bufnr, l:start, l:end)
  endif
endfunction

