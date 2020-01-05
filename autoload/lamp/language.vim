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
        \   'filetypes': ['html'],
        \   'initialization_options': { -> {
        \     'embeddedLanguages': {
        \       'css': v:true,
        \       'html': v:true
        \     }
        \   } },
        \   'capabilities': {
        \     'completionProvider': {
        \       'triggerCharacters': ['>', '"']
        \     }
        \   }
        \ }, get(a:000, 0, {})))
endfunction

"
" lamp#language#css
"
function! lamp#language#css(...) abort
  if !executable('css-languageserver')
    echomsg '[vim-lamp] You should install `css-languageserver`.'
    echomsg '[vim-lamp] > npm install -g vscode-css-languageserver-bin'
    return
  endif

  call lamp#register('css-languageserver', lamp#merge({
        \   'command': ['css-languageserver', '--stdio'],
        \   'filetypes': ['css', 'scss'],
        \ }, get(a:000, 0, {})))
endfunction

"
" lamp#language#yaml
"
function! lamp#language#yaml(...) abort
  if !executable('yaml-language-server')
    echomsg '[vim-lamp] You should install `yaml-language-server`.'
    echomsg '[vim-lamp] > npm install -g yaml-language-server'
    return
  endif

  call lamp#register('yaml-language-server', lamp#merge({
        \   'command': ['yaml-language-server', '--stdio'],
        \   'filetypes': ['yaml', 'yaml.ansible'],
        \   'workspace_configurations': {
        \     '*': {
        \       'yaml': {
        \         'completion': v:true,
        \         'hover': v:true,
        \         'validate': v:true,
        \         'schemas': {
        \           'https://raw.githubusercontent.com/VSChina/vscode-ansible/master/snippets/ansible-data.json': '*ansible*/**/*.{yml,yaml}',
        \         },
        \         'format': {
        \           'enable': v:true
        \         }
        \       }
        \     }
        \   }
        \ }, get(a:000, 0, {})))
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
        \   'initialization_options': { -> {
        \     'iskeyword': &iskeyword,
        \     'vimruntime': $VIMRUNTIME,
        \     'runtimepath': &runtimepath,
        \     'suggest': {
        \       'fromVimruntime': v:true,
        \       'fromRuntimepath': v:true
        \     }
        \   } }
        \ }, get(a:000, 0, {})))
endfunction

"
" lamp#language#go
"
function! lamp#language#go() abort
  if !executable('vim-language-server')
    echomsg '[vim-lamp] You should install `gopls`.'
    echomsg '[vim-lamp] see https://github.com/golang/tools/blob/master/gopls/doc/user.md'
    return
  endif

  call lamp#register('gopls', {
        \   'command': ['gopls'],
        \   'filetypes': ['go'],
        \   'initialization_options': { -> {
        \     'usePlaceholders': v:true,
        \     'completeUnimported': v:true
        \   } }
        \ })
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
        \   'command': ['rls'],
        \   'filetypes': ['rust'],
        \   'root_uri': { -> lamp#findup('.git', 'Cargo.toml') }
        \ }, get(a:000, 0, {})))
endfunction

"
" lamp#language#python
"
function! lamp#language#python(...) abort
  if !executable('pyls')
    echomsg '[vim-lamp] You should install `pyls`.'
    echomsg '[vim-lamp] see https://github.com/palantir/python-language-server'
    return
  endif

  call lamp#register('pyls', lamp#merge({
        \   'command': ['pyls'],
        \   'filetypes': ['python'],
        \ }, get(a:000, 0, {})))
endfunction

