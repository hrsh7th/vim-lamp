# vim-lamp
Language Server Protocol Client for Vim.

# Setting

```viml
set ambwidth=double

augroup vimrc
  autocmd!
augroup END

autocmd! vimrc User lamp#initialized * call s:on_initialized()
function! s:on_initialized()
  call lamp#register('typescript-language-server', {
      \   'command': ['typescript-language-server', '--stdio'],
      \   'filetypes': ['typescript', 'javascript', 'typescript.tsx', 'javascript.jsx'],
      \   'root_uri': { -> vimrc#get_project_root() },
      \   'initialization_options': { -> {} },
      \ })
endfunction

autocmd! vimrc User lamp#text_document_did_open call s:on_text_document_did_open()
function! s:on_text_document_did_open() abort
  nmap <buffer> gf<CR>    <Plug>(lamp-definition)
  nmap <buffer> gfs       <Plug>(lamp-definition-split)
  nmap <buffer> gfv       <Plug>(lamp-definition-vsplit)
  nmap <buffer> <Leader>i <Plug>(lamp-hover)
  nmap <buffer> <Leader>r <Plug>(lamp-rename)

  setlocal omnifunc=lamp#complete
endfunction
```

# [Status](https://microsoft.github.io/language-server-protocol/specifications/specification-3-14/)

- General
    - [x] initialize
    - [x] initialized
    - [ ] ~~shutdown~~
    - [ ] ~~exit~~
    - [ ] $/cancelRequest

- Window
    - [ ] window/showMessage
    - [ ] window/showMessageRequest
    - [ ] window/logMessage

- Telemetry
    - [ ] telemetry/event

- Client
    - [ ] client/registerCapability
    - [ ] client/unregisterCapability

- Workspace
    - [ ] workspace/workspaceFolders
    - [ ] workspace/didChangeWorkspaceFolders
    - [ ] workspace/didChangeConfiguration
    - [ ] workspace/configuration
    - [ ] workspace/didChangeWatchedFiles
    - [ ] workspace/symbol
    - [x] workspace/executeCommand
    - [ ] workspace/applyEdit

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
    - [x] textDocument/completion
    - [x] completionItem/resolve
    - [x] textDocument/hover
    - [ ] textDocument/signatureHelp
    - [ ] textDocument/declaration
    - [x] textDocument/definition
    - [ ] textDocument/typeDefinition
    - [ ] textDocument/implementation
    - [x] textDocument/references
    - [ ] textDocument/documentHighlight
    - [ ] textDocument/documentSymbol
    - [ ] textDocument/codeAction
    - [ ] textDocument/codeLens
    - [ ] codeLens/resolve
    - [ ] textDocument/documentLink
    - [ ] documentLink/resolve
    - [ ] textDocument/documentColor
    - [ ] textDocument/colorPresentation
    - [ ] textDocument/formatting
    - [ ] textDocument/rangeFormatting
    - [ ] textDocument/onTypeFormatting
    - [x] textDocument/rename
    - [x] textDocument/prepareRename
    - [ ] textDocument/foldingRange

# TODO
- Refactor floatwin
    - Remove duplicated codes in nvim/vim compat layer
- Write `signs/highlight` tests
- Improve diagnostics handling
- Create asyncomplete source
- Floatwin Markdown Syntax
- Improve error logging
    - Currently not supported logging the error at `s:Promise.all`.
    - Probably should patch the `Promise.vim` in the vital.vim.
- Show message when has no server that supports specific capability

