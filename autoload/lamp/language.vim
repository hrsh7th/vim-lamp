augroup lamp#language
  autocmd!
augroup END

"
" lamp#language#php
"
function! lamp#language#php(...) abort
  if !executable('intelephense')
    echoerr 'You should install `intelephense`.'
    echoerr '------------------------------------------------------------'
    echoerr '> npm install -g intelephense'
    echoerr '------------------------------------------------------------'
    return
  endif

  call lamp#register('intelephense', lamp#merge({
        \   'command': ['intelephense', '--stdio'],
        \   'filetypes': ['php'],
        \   'root_uri': { -> lamp#findup('.git', 'composer.json') },
        \   'initialization_options': { -> {
        \     'storagePath': expand('~/.cache/intelephense')
        \   } }
        \ }, get(a:000, 0, {})))

  autocmd! lamp#language FileType php setlocal iskeyword+=$
endfunction

"
" lamp#language#html
"
function! lamp#language#html(...) abort
  if !executable('html-languageserver')
    echoerr 'You should install `html-languageserver`.'
    echoerr '------------------------------------------------------------'
    echoerr '> npm install -g vscode-html-languageserver-bin'
    echoerr '------------------------------------------------------------'
    return
  endif

  call lamp#register('html-languageserver', lamp#merge({
        \   'command': ['html-languageserver', '--stdio'],
        \   'filetypes': ['html', 'css', 'scss'],
        \   'initialization_options': { -> {
        \     'embeddedLanguages': {
        \       'css': v:true,
        \       'html': v:true
        \     }
        \   } },
        \   'capabilities': {
        \     'completionProvider': {
        \       'triggerCharacters': ['>']
        \     }
        \   }
        \ }, get(a:000, 0, {})))
        \ 
  autocmd! lamp#language FileType html setlocal iskeyword+=/
endfunction

"
" lamp#language#typescript
"
function! lamp#language#typescript(...) abort
  if !executable('typescript-language-server')
    echoerr 'You should install `typescript-language-server`.'
    echoerr '------------------------------------------------------------'
    echoerr '> npm install -g typescript-language-server'
    echoerr '------------------------------------------------------------'
    return
  endif

  call lamp#register('typescript-language-server', lamp#merge({
        \   'command': ['typescript-language-server', '--stdio'],
        \   'filetypes': ['typescript', 'typescript.tsx', 'typescriptreact', 'javascript', 'javascript.jsx', 'javascriptreact'],
        \   'root_uri': { -> lamp#findup('tsconfig.json', '.git') },
        \   'capabilities': {
        \     'triggerCharacters': [',']
        \   }
        \ }, get(a:000, 0, {})))
endfunction

"
" lamp#language#vim
"
function! lamp#language#vim(...) abort
  if !executable('vim-language-server')
    echoerr 'You should install `vim-language-server`.'
    echoerr '------------------------------------------------------------'
    echoerr '> npm install -g vim-language-server'
    echoerr '------------------------------------------------------------'
    return
  endif

  call lamp#register('vim-language-server', lamp#merge({
        \   'command': ['vim-language-server', '--stdio'],
        \   'filetypes': ['vim', 'vimspec'],
        \ }, get(a:000, 0, {})))
endfunction


"
" lamp#language#rust
"
function! lamp#language#rust(...) abort
  if !executable('rls')
    echoerr 'You should install `rls`.'
    echoerr '------------------------------------------------------------'
    echoerr '> rustup update && rustup component add rls rust-analysis rust-src'
    echoerr '------------------------------------------------------------'
    return
  endif

  call lamp#register('rls', lamp#merge({
        \   'command': ['rustup run stable rls'],
        \   'filetypes': ['rust'],
        \   'root_uri': { -> lamp#findup('.git', 'cargo.toml') }
        \ }, get(a:000, 0, {})))
endfunction

