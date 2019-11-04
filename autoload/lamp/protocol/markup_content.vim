"
" lamp#protocol#markup_content#normalize
"
function! lamp#protocol#markup_content#normalize(markup_contents) abort
  let l:markup_contents = type(a:markup_contents) == type([]) ? a:markup_contents : [a:markup_contents]

  let l:normalized = []
  for l:markup_content in l:markup_contents
    if type(l:markup_content) == type('')
      let l:normalized += [{
            \   'lines': split(s:string(l:markup_content), "\n", v:true)
            \ }]
    elseif type(l:markup_content) == type({})
      let l:string = l:markup_content.value
      if has_key(l:markup_content, 'language')
        let l:string = '```' . l:markup_content.language . "\n" . l:string
        let l:string = l:string . "\n" . '```'
      endif

      let l:normalized += [{
            \   'lines': split(s:string(l:string), "\n", v:true)
            \ }]
    elseif type(l:markup_content) == type([])
      let l:normalized += lamp#protocol#markup_content#normalize(l:markup_content)
    endif
  endfor
  return filter(l:normalized, { k, v -> v.lines != [''] })
endfunction

"
" s:string
"
function! s:string(string) abort
  let l:string = a:string

  " remove \r.
  let l:string = substitute(l:string, "\r", '', 'g')

  " compact fenced code block satrting.
  let l:string = substitute(l:string, '\%(^\|' . "\n" . '\)\(```\s*\w\+\s*\)' . "\n", '\1 ', 'g')

  " compact fenced code block ending.
  let l:string = substitute(l:string, "\n\\(```\\s*\\)", ' ```', 'g')

  " trim first/last whitespace.
  let l:string = substitute(l:string, '^\s*\|\s*$', '', 'g')

  " remove trailing whitspae.
  let l:string = substitute(l:string, '\s*\n', '\n', 'g')
  return l:string
endfunction

