augroup lamp#builtin
  autocmd!
augroup END

"
" lamp#builtin#intelephense
"
function! lamp#builtin#intelephense(...) abort
  if !executable('intelephense')
    echomsg '[vim-lamp] You should install `intelephense`.'
    echomsg '[vim-lamp] > npm install -g intelephense'
    return
  endif

  let l:storagePath = expand('~/.cache/intelephense')
  if !isdirectory(l:storagePath)
    call mkdir(l:storagePath, 'p', '0755')
  endif

  call lamp#register('intelephense', lamp#merge({
  \   'command': ['intelephense', '--stdio'],
  \   'filetypes': ['php'],
  \   'root_uri': { bufnr -> lamp#findup(['.git', 'composer.json'], bufname(bufnr)) },
  \   'initialization_options': { -> {
  \     'storagePath': l:storagePath,
  \     'globalStoragePath': l:storagePath,
  \   } }
  \ }, get(a:000, 0, {})))
  autocmd! lamp#builtin FileType php setlocal iskeyword+=$
endfunction

"
" lamp#builtin#html_languageserver
"
function! lamp#builtin#html_languageserver(...) abort
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
  \       'html': v:true,
  \       'javascript': v:true,
  \     }
  \   } }
  \ }, get(a:000, 0, {})))
endfunction

"
" lamp#builtin#css_languageserver
"
function! lamp#builtin#css_languageserver(...) abort
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
" lamp#builtin#yaml_language_server
"
function! lamp#builtin#yaml_language_server(...) abort
  if !executable('yaml-language-server')
    echomsg '[vim-lamp] You should install `yaml-language-server`.'
    echomsg '[vim-lamp] > npm install -g yaml-language-server'
    return
  endif

  call lamp#feature#workspace#configure({
  \   'yaml': {
  \     'completion': v:true,
  \     'hover': v:true,
  \     'validate': v:true,
  \     'schemas': json_decode(join(readfile(lamp#config('global.root') . '/misc/json/catalog.json'), "\n")).schemas,
  \     'format': {
  \       'enable': v:true
  \     }
  \   }
  \ })

  call lamp#register('yaml-language-server', lamp#merge({
  \   'command': ['yaml-language-server', '--stdio'],
  \   'filetypes': ['yaml', 'yaml.ansible'],
  \ }, get(a:000, 0, {})))
endfunction

"
" lamp#builtin#json_languageserver
"
function! lamp#builtin#json_languageserver(...) abort
  if !executable('json-languageserver')
    echomsg '[vim-lamp] You should install `json-languageserver`.'
    echomsg '[vim-lamp] > npm install -g vscode-json-languageserver-bin'
    return
  endif

  call lamp#feature#workspace#configure({
  \   'json': {
  \     'schemas': json_decode(join(readfile(lamp#config('global.root') . '/misc/json/catalog.json'), "\n")).schemas,
  \     'format': {
  \       'enable': v:true
  \     }
  \   }
  \ })

  call lamp#register('json-languageserver', lamp#merge({
  \   'command': ['json-languageserver', '--stdio'],
  \   'filetypes': ['json'],
  \ }, get(a:000, 0, {})))
endfunction

"
" lamp#builtin#typescript_language_server
"
function! lamp#builtin#typescript_language_server(...) abort
  if !executable('typescript-language-server')
    echomsg '[vim-lamp] You should install `typescript-language-server`.'
    echomsg '[vim-lamp] > npm install -g typescript-language-server'
    return
  endif

  call lamp#register('typescript-language-server', lamp#merge({
  \   'command': ['typescript-language-server', '--stdio'],
  \   'filetypes': ['typescript', 'typescript.tsx', 'typescriptreact', 'javascript', 'javascript.jsx', 'javascriptreact'],
  \   'root_uri': { bufnr -> lamp#findup(['tsconfig.json', '.git'], bufname(bufnr)) },
  \ }, get(a:000, 0, {})))
endfunction

"
" lamp#builtin#vim_language_server
"
function! lamp#builtin#vim_language_server(...) abort
  if !executable('vim-language-server')
    echomsg '[vim-lamp] You should install `vim-language-server`.'
    echomsg '[vim-lamp] > npm install -g vim-language-server'
    return
  endif

  call lamp#register('vim-language-server', lamp#merge({
  \   'command': ['vim-language-server', '--stdio'],
  \   'filetypes': ['vim', 'vimspec'],
  \   'initialization_options': { -> {
  \     'iskeyword': &iskeyword . ',:',
  \    'vimruntime': $VIMRUNTIME,
  \    'runtimepath': &runtimepath,
  \    'diagnostic': {
  \      'enable': v:true,
  \    },
  \    'suggest': {
  \      'fromVimruntime': v:false,
  \      'fromRuntimepath': v:true,
  \    }
  \   } }
  \ }, get(a:000, 0, {})))
endfunction

"
" lamp#builtin#gopls
"
function! lamp#builtin#gopls() abort
  if !executable('gopls')
    echomsg '[vim-lamp] You should install `gopls`.'
    echomsg '[vim-lamp] see https://github.com/golang/tools/blob/master/gopls/doc/user.md'
    return
  endif

  call lamp#register('gopls', {
  \   'command': ['gopls'],
  \   'filetypes': ['go', 'gomod'],
  \   'root_uri': { bufnr -> lamp#findup(['go.mod', 'main.go'], bufname(bufnr)) },
  \   'initialization_options': { -> {
  \     'usePlaceholders': v:true,
  \     'completeUnimported': v:true,
  \     'hoverKind': 'FullDocumentation',
  \   } },
  \ })

  autocmd! lamp#builtin BufWritePre *.go call execute('LampFormattingSync') | call execute('LampCodeActionSync source.organizeImports')
endfunction

"
" lamp#builtin#rls
"
function! lamp#builtin#rls(...) abort
  if !executable('rls')
    echomsg '[vim-lamp] You should install `rls`.'
    echomsg '[vim-lamp] > rustup update && rustup component add rls rust-analysis rust-src'
    return
  endif

  call lamp#register('rls', lamp#merge({
  \   'command': ['rls'],
  \   'filetypes': ['rust'],
  \   'root_uri': { bufnr -> lamp#findup(['.git', 'Cargo.toml'], bufname(bufnr)) }
  \ }, get(a:000, 0, {})))
endfunction

"
" lamp#builtin#pyls
"
function! lamp#builtin#pyls(...) abort
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

