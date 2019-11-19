# vim-lamp
Language Server Protocol client for Vim.

# Status
Well works but APIs aren't stable.

# Requirement

- vim
    - 8.1 or later
- nvim
    - 0.4.0 or later

# Setting

```vim
if !isdirectory(expand('~/.vim/plugged/vim-plug'))
  silent !curl -fLo ~/.vim/plugged/vim-plug/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
end
execute printf('source %s', expand('~/.vim/plugged/vim-plug/plug.vim'))

call plug#begin('~/.vim/plugged')
Plug 'https://github.com/hrsh7th/vim-lamp'
Plug 'https://github.com/hrsh7th/vim-vsnip'
call plug#end()

"
" required options.
"
set hidden
set ambiwidth=double

augroup vimrc
  autocmd!
augroup END

"
" initialize servers.
"
autocmd! vimrc User lamp#initialized * call s:on_initialized()
function! s:on_initialized()
  call lamp#config('feature.completion.snippet.expand', { option -> vsnip#anonymous(option.body) })

  call lamp#register('typescript-language-server', {
      \   'command': ['typescript-language-server', '--stdio'],
      \   'filetypes': ['typescript', 'javascript', 'typescript.tsx', 'javascript.jsx'],
      \   'root_uri': { -> vimrc#get_project_root() },
      \   'initialization_options': { -> {} },
      \   'capabilities': {
      \     'completionProvider': {
      \       'triggerCharacters': [',']
      \     }
      \   }
      \ })
endfunction

"
" initialize buffers.
"
autocmd! vimrc User lamp#text_document_did_open call s:on_text_document_did_open()
function! s:on_text_document_did_open() abort
  setlocal omnifunc=lamp#complete

  noremap <buffer><expr> <Tab> lamp#map#confirm('<Tab>')

  nmap <buffer> gf<CR>         <Plug>(lamp-definition)
  nmap <buffer> gfs            <Plug>(lamp-definition-split)
  nmap <buffer> gfv            <Plug>(lamp-definition-vsplit)

  nmap <buffer> tgf<CR>        <Plug>(lamp-type-definition)
  nmap <buffer> tgfs           <Plug>(lamp-type-definition-split)
  nmap <buffer> tgfv           <Plug>(lamp-type-definition-vsplit)

  nmap <buffer> dgf<CR>        <Plug>(lamp-declaration)
  nmap <buffer> dgfs           <Plug>(lamp-declaration-split)
  nmap <buffer> dgfv           <Plug>(lamp-declaration-vsplit)

  nmap <buffer> igf<CR>        <Plug>(lamp-implementation)
  nmap <buffer> igfs           <Plug>(lamp-implementation-split)
  nmap <buffer> igfv           <Plug>(lamp-implementation-vsplit)

  nmap <buffer> <Leader>i      <Plug>(lamp-hover)

  nmap <buffer> <Leader>r      <Plug>(lamp-rename)

  nmap <buffer> <Leader>g      <Plug>(lamp-references)

  nmap <buffer> <Leader>f      <Plug>(lamp-formatting)
  vmap <buffer> <Leader>f      <Plug>(lamp-range-formatting)

  nmap <buffer> <Leader><CR>   <Plug>(lamp-code-action)
  vmap <buffer> <Leader><CR>   <Plug>(lamp-code-action)

  nmap <buffer> @              <Plug>(lamp-document-highlight)
  nmap <buffer> <Esc>          <Plug>(lamp-document-highlight-clear)
  nnoremap <buffer><Esc>       :<C-u>call lamp#feature#document_highlight#clear()<CR>
endfunction
```

# [Spec compatibility](https://microsoft.github.io/language-server-protocol/specifications/specification-3-14/)

- General
    - [x] initialize
    - [x] initialized
    - [ ] ~~shutdown~~
    - [ ] ~~exit~~
    - [ ] ~~$/cancelRequest~~

- Window
    - [ ] window/showMessage
    - [ ] window/showMessageRequest
    - [ ] window/logMessage

- Telemetry
    - [ ] telemetry/event

- Client
    - [ ] ~~client/registerCapability~~ (Maybe unneeded)
    - [ ] ~~client/unregisterCapability~~ (Maybe unneeded)

- Workspace
    - [ ] workspace/workspaceFolders
    - [ ] workspace/didChangeWorkspaceFolders
    - [ ] workspace/didChangeConfiguration
    - [ ] workspace/configuration
    - [ ] workspace/didChangeWatchedFiles
    - [ ] workspace/symbol
    - [x] workspace/executeCommand
    - [x] workspace/applyEdit

- Synchronization
    - [x] textDocument/didOpen
    - [x] textDocument/didChange
    - [ ] textDocument/willSave
    - [ ] textDocument/willSaveWaitUntil
    - [ ] textDocument/didSave
    - [x] textDocument/didClose

- Diagnostics
    - [x] textDocument/publishDiagnostics

- Language Features
    - [x] textDocument/completion (Snippet/Documentation/AdditionalTextEdits are supported!)
    - [x] completionItem/resolve
    - [x] textDocument/hover
    - [x] textDocument/signatureHelp
    - [x] textDocument/declaration
    - [x] textDocument/definition
    - [x] textDocument/typeDefinition
    - [x] textDocument/implementation
    - [x] textDocument/references
    - [x] textDocument/documentHighlight
    - [ ] textDocument/documentSymbol
    - [x] textDocument/codeAction
    - [ ] textDocument/codeLens
    - [ ] codeLens/resolve
    - [ ] textDocument/documentLink
    - [ ] documentLink/resolve
    - [ ] textDocument/documentColor
    - [ ] textDocument/colorPresentation
    - [x] textDocument/formatting
    - [x] textDocument/rangeFormatting
    - [ ] ~~textDocument/onTypeFormatting~~ (No supported server found.)
    - [x] textDocument/rename
    - [x] textDocument/prepareRename
    - [ ] textDocument/foldingRange

# TODO
- Re-thinking `lamp#map#confirm` when user no use `lexima.vim`
- Improve documentation
- Built-in snippet support
- Create asyncomplete source
- Design canceling outdated request
- Design event handling (like vim-lsc's once)
- Should be abstracted location's feature?
- ! Performance
- ! Multibyte support

