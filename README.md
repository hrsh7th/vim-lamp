# vim-lamp
Language Server Protocol Client for Vim.

# Requirement

- vim
    - 8.1 or later
- nvim
    - 0.4.0 or later

# Setting

```viml
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

  " NOTE: `capabilities` field to be merged to server's capabilities.
  " NOTE: you can omit the capability via `v:null`

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
  nmap <buffer> gf<CR>       <Plug>(lamp-definition)
  nmap <buffer> gfs          <Plug>(lamp-definition-split)
  nmap <buffer> gfv          <Plug>(lamp-definition-vsplit)
  nmap <buffer> <Leader>i    <Plug>(lamp-hover)
  nmap <buffer> <Leader>r    <Plug>(lamp-rename)
  nmap <buffer> <Leader>g    <Plug>(lamp-references)
  nmap <buffer> <Leader>f    <Plug>(lamp-formatting)
  vmap <buffer> <Leader>f    <Plug>(lamp-range-formatting)
  nmap <buffer> <Leader><CR> <Plug>(lamp-code-action)
  vmap <buffer> <Leader><CR> <Plug>(lamp-code-action)

  setlocal omnifunc=lamp#complete
endfunction
```

# [Status](https://microsoft.github.io/language-server-protocol/specifications/specification-3-14/)

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
    - [x] textDocument/codeAction
    - [ ] textDocument/codeLens
    - [ ] codeLens/resolve
    - [ ] textDocument/documentLink
    - [ ] documentLink/resolve
    - [ ] textDocument/documentColor
    - [ ] textDocument/colorPresentation
    - [x] textDocument/formatting
    - [x] textDocument/rangeFormatting
    - [ ] textDocument/onTypeFormatting
    - [x] textDocument/rename
    - [x] textDocument/prepareRename
    - [ ] textDocument/foldingRange

# TODO
- Write `signs/highlight` tests
- Improve diagnostics handling
- Create asyncomplete source
- Show message when has no server that supports specific capability
- Design canceling outdated request
- ! Keep cursor position after text edit
- ! Implement text_edit as vscode-languageserver-node
    - https://github.com/microsoft/vscode-languageserver-node/blob/master/textDocument/src/main.ts#L344

