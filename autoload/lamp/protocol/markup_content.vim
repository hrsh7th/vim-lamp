let s:start = '\%(^\|' . "\n" . '\)\s*'
let s:end = '\s*\%($\|' . "\n" . '\)'
let s:white_nr = '\%(\s\|' . "\n" . '\)*'

"
" lamp#protocol#markup_content#combine
"
function! lamp#protocol#markup_content#combine(contents) abort
  let l:lines = []
  for l:content in a:contents
    let l:lines += l:content.lines
  endfor
  return get(lamp#protocol#markup_content#normalize(join(l:lines, "\n")), 0, [])
endfunction

"
" lamp#protocol#markup_content#normalize
"
function! lamp#protocol#markup_content#normalize(markup_contents) abort
  let l:markup_contents = type(a:markup_contents) == type([]) ? a:markup_contents : [a:markup_contents]

  let l:normalized = []
  for l:markup_content in l:markup_contents
    if type(l:markup_content) == type([])
      let l:normalized += lamp#protocol#markup_content#normalize(l:markup_content)
    else
      let l:string = lamp#protocol#markup_content#to_string(l:markup_content)
      if l:string !=# ''
        let l:normalized += [{
              \   'lines': split(l:string, "\n", v:true)
              \ }]
      endif
    endif
  endfor
  return filter(l:normalized, { k, v -> v.lines != [''] })
endfunction

"
" lamp#protocol#markup_content#to_string
"
function! lamp#protocol#markup_content#to_string(markup_content) abort
  if type(a:markup_content) == type('')
    return s:string(a:markup_content)
  elseif type(a:markup_content) == type({})
    let l:string = a:markup_content.value
    if has_key(a:markup_content, 'language') && l:string !~# '^' . s:white_nr . '$'
      let l:string = '```' . a:markup_content.language . ' ' . l:string
      let l:string = l:string . ' ```'
    endif
    return s:string(l:string)
  endif
endfunction

"
" s:string
"
function! s:string(string) abort
  let l:string = a:string

  " remove \r.
  let l:string = substitute(l:string, "\\(\r\n\\|\r\\)", "\n", 'g')

  " compact fenced code block satrting.
  let l:string = substitute(l:string, s:start . '\zs\(```\s*\w\+\)' . s:white_nr, '\1 ', 'g')

  " compact fenced code block ending.
  let l:string = substitute(l:string, s:white_nr . '```\s*' . '\ze' . s:end, ' ```', 'g')

  " trim first/last whitespace.
  let l:string = substitute(l:string, '^\s*\|\s*$', '', 'g')

  " remove trailing whitspae.
  let l:string = substitute(l:string, '\s*\(' . s:end . '\)', '\1', 'g')

  return l:string
endfunction

