augroup lamp_floatwin
  " This autocmd for support vim's popup-window.
  autocmd!
  autocmd BufWinEnter * call s:update()
augroup END

" This function for support nvim's floatwin.
" @see lamp#view#floatwin
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
  runtime! syntax/markdown.vim
  syntax include @Markdown syntax/markdown.vim

  let l:done_syntaxes = []
  for [l:mark, l:syntax] in items(s:get_syntax_map(s:find_marks()))
    call s:clear()
    let l:syntax_group = printf('@LampMarkdownFenced_%s', s:escape(l:syntax))

    " include syntax.
    if index(l:done_syntaxes, l:syntax) == -1
      try
        if l:syntax ==# 'vim' && has('nvim')
          execute printf('syntax include %s syntax/vim/generated.vim', l:syntax_group)
        else
          for l:syntax_path in s:find_syntax_path(l:syntax)
            execute printf('syntax include %s %s', l:syntax_group, l:syntax_path)
          endfor
        endif
      catch /.*/
        continue
      endtry
      let l:done_syntaxes += [l:syntax]
    endif

    " apply '```%mark% ... ```' to the syntax.
    call s:clear()
    let l:mark_group = printf('LampMarkdownFencedMark_%s', s:escape(l:mark))
    let l:start_mark = printf('^\s*```\s*%s\s*', l:mark)
    let l:end_mark = '\s*```\s*$'
    execute printf('syntax region %s matchgroup=LampMarkdownFencedStart start="%s" matchgroup=LampMarkdownFencedEnd end="%s" containedin=@Markdown contains=%s concealends',
          \   l:mark_group,
          \   l:start_mark,
          \   l:end_mark,
          \   l:syntax_group
          \ )
  endfor
endfunction

"
" find marks.
" @see autoload/lamp/view/floatwin.vim
"
function! s:find_marks() abort
  let l:text = join(getbufvar(bufnr('%'), 'lamp_floatwin_lines', []), "\n")

  let l:marks = {}
  let l:pos = 0
  while 1
    let l:match = matchlist(l:text, '```\s*\(\w\+\)', l:pos, 1)
    if empty(l:match)
      break
    endif
    let l:marks[l:match[1]] = v:true
    let l:pos = matchend(l:text, '```\s*\(\w\+\)', l:pos, 1)
  endwhile

  return keys(l:marks)
endfunction

"
" get_syntax_map
"
function! s:get_syntax_map(marks) abort
  let l:syntax_map = {}

  for l:mark in a:marks

    " resolve from lamp#config
    for [l:syntax, l:marks] in items(lamp#config('view.floatwin.fenced_languages'))
      if index(l:marks, l:mark) >= 0
        let l:syntax_map[l:mark] = l:syntax
        break
      endif
    endfor

    " resolve from g:markdown_fenced_languages
    for l:config in get(g:, 'markdown_fenced_languages', [])
      " Supports `let g:markdown_fenced_languages = ['sh']`
      if l:config !~# '='
        if l:config ==# l:mark
          let l:syntax_map[l:mark] = l:mark
          break
        endif

      " Supports `let g:markdown_fenced_languages = ['bash=sh']`
      else
        let l:config = split(l:config, '=')
        if l:config[1] ==# l:mark
          let l:syntax_map[l:config[1]] = l:config[0]
          break
        endif
      endif
    endfor

    " add as-is if can't resolved.
    if !has_key(l:syntax_map, l:mark)
      let l:syntax_map[l:mark] = l:mark
    endif
  endfor

  return l:syntax_map
endfunction

"
" find syntax path.
"
function! s:find_syntax_path(name) abort
  let l:syntax_paths = []
  for l:rtp in split(&runtimepath, ',')
    let l:syntax_path = printf('%s/syntax/%s.vim', l:rtp, a:name)
    if filereadable(l:syntax_path)
      call add(l:syntax_paths, l:syntax_path)
    endif
  endfor
  return l:syntax_paths
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

