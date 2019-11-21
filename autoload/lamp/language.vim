augroup lamp#language
  autocmd!
augroup END

"
" lamp#language#php
"
function! lamp#language#php(...) abort
  if !executable('intelephense')
    echomsg '[vim-lamp] You should install `intelephense`.'
    echomsg '[vim-lamp] > npm install -g intelephense'
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
    echomsg '[vim-lamp] You should install `html-languageserver`.'
    echomsg '[vim-lamp] > npm install -g vscode-html-languageserver-bin'
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
  autocmd! lamp#language FileType html setlocal iskeyword+=/
endfunction

"
" lamp#language#typescript
"
function! lamp#language#typescript(...) abort
  if !executable('typescript-language-server')
    echomsg '[vim-lamp] You should install `typescript-language-server`.'
    echomsg '[vim-lamp] > npm install -g typescript-language-server'
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
    echomsg '[vim-lamp] You should install `vim-language-server`.'
    echomsg '[vim-lamp] > npm install -g vim-language-server'
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
    echomsg '[vim-lamp] You should install `rls`.'
    echomsg '[vim-lamp] > rustup update && rustup component add rls rust-analysis rust-src'
    return
  endif

  call lamp#register('rls', lamp#merge({
        \   'command': ['rustup run stable rls'],
        \   'filetypes': ['rust'],
        \   'root_uri': { -> lamp#findup('.git', 'cargo.toml') }
        \ }, get(a:000, 0, {})))
endfunction

