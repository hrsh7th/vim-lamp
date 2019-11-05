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

  call s:clear()
  syntax clear
  runtime! syntax/markdown.vim
  syntax include @Markdown syntax/markdown.vim

  for [l:syntax, l:marks] in items(lamp#config('view.floatwin.fenced_language'))
    call s:clear()
    let l:grouplist = printf('@MarkdownFenced_%s', s:escape(l:syntax))

    " include syntax.
    try
      if l:syntax ==# 'vim' && has('nvim')
        execute printf('syntax include %s syntax/vim/generated.vim', l:grouplist)
      else
        for l:syntax_file in s:find_syntax_files(l:syntax)
          execute printf('syntax include %s %s', l:grouplist, l:syntax_file)
        endfor
      endif
    catch /.*/
      continue
    endtry

    " apply '```%mark% ... ```' to the syntax.
    for l:mark in l:marks
      call s:clear()
      let l:group = printf('MarkdownFenced_%s', s:escape(l:mark))
      let l:start_mark = printf('^\s*```\s*%s\s*', l:mark)
      let l:end_mark = '\s*```\s*$'
      execute printf('syntax region %s matchgroup=MarkdownFencedStart start="%s" matchgroup=MarkdownFencedEnd end="%s" containedin=@Markdown contains=%s concealends',
            \   l:group,
            \   l:start_mark,
            \   l:end_mark,
            \   l:grouplist
            \ )
    endfor
  endfor
endfunction

"
" find syntax file.
"
function! s:find_syntax_files(name) abort
  let l:syntax_files = []
  for l:rtp in split(&runtimepath, ',')
    let l:syntax_file = printf('%s/syntax/%s.vim', l:rtp, a:name)
    if filereadable(l:syntax_file)
      call add(l:syntax_files, l:syntax_file)
    endif
  endfor
  return l:syntax_files
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

call s:update()
