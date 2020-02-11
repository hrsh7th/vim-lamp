let s:TextEdit = vital#lamp#import('LSP.TextEdit')

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
      call setbufvar(l:bufnr, '&buflisted', v:true)
    endif
    call lamp#view#edit#apply(l:bufnr, l:edits)
  endfor
endfunction

"
" lamp#view#edit#apply
"
function! lamp#view#edit#apply(bufnr, edits) abort
  call s:TextEdit.apply(a:bufnr, a:edits)
endfunction

