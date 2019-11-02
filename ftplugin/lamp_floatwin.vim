augroup lamp_floatwin
  autocmd!
  autocmd FileType,BufWinEnter * call s:update()
augroup END

function! LampFloatwinSyntaxUpdate()
  call s:update()
endfunction

"
" s:update
"
function! s:update()
  if &filetype !=# 'lamp_floatwin'
    return
  endif
  set conceallevel=2

  call s:clear()
  syntax clear
  syntax include @Markdown syntax/markdown.vim

  for [l:syntax, l:marks] in items(lamp#config('view.floatwin.fenced_language'))
    call s:clear()
    let l:grouplist = printf('@MarkdownFenced_%s', s:escape(l:syntax))
    try
      execute printf('syntax include %s syntax/%s.vim', l:grouplist, l:syntax)
      execute printf('syntax include %s after/syntax/%s.vim', l:grouplist, l:syntax)
    catch /.*/
      continue
    endtry

    for l:mark in l:marks
      call s:clear()
      let l:group = printf('MarkdownFenced_%s', s:escape(l:mark))
      let l:start_mark = printf('^\s*```\s*%s', l:mark)
      let l:end_mark = '^\s*```\s*$'
      execute printf('syntax region %s start="%s" end="%s" containedin=@Markdown contains=%s,MarkdownFencedEnd,MarkdownFencedStart',
            \   l:group,
            \   l:start_mark,
            \   l:end_mark,
            \   l:grouplist
            \ )
    endfor
  endfor
  execute printf('syntax match MarkdownFencedStart "^\s*```\s*\w\+" contained conceal')
  execute printf('syntax match MarkdownFencedEnd "^\s*```\s*$" contained conceal')
endfunction

"
" s:escape
"
function! s:escape(group)
  let l:group = a:group
  let l:group = substitute(l:group, '\.', '_', '')
  return l:group
endfunction

"
" s:clear
"
function! s:clear()
  let b:current_syntax = ''
  unlet b:current_syntax

  let g:main_syntax = ''
  unlet g:main_syntax
endfunction

