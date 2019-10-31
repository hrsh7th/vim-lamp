# vim-lamp
Language Server Protocol Client for Vim.

# Status
- General
    - [x] initialize
    - [x] initialized
    - [ ] shutdown
    - [ ] exit
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
    - [ ] workspace/executeCommand
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
    - [ ] textDocument/references
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
- Create omnifunc

