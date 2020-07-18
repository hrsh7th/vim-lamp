# vim-lamp
Language Server Protocol client for Vim.

# Concept
- Works on vim/nvim both
- High performance
- Well supported LSP spec
- Well visualize diagnostics

# Status
- APIs aren't stable yet.
    - Apply breaking change with no announcement.


# Setting

```vim
if has('vim_starting')
  set encoding=utf-8
endif
scriptencoding utf-8

if &compatible
  set nocompatible
endif

if !isdirectory(expand('~/.vim/plugged/vim-plug'))
  silent !curl -fLo ~/.vim/plugged/vim-plug/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
end
execute printf('source %s', expand('~/.vim/plugged/vim-plug/plug.vim'))

call plug#begin('~/.vim/plugged')
Plug 'hrsh7th/vim-lamp'
Plug 'hrsh7th/vim-compete'
Plug 'hrsh7th/vim-compete-lamp'
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'
call plug#end()

"
" required options
"
set hidden

augroup vimrc
  autocmd!
augroup END

"
" initialize servers
"
autocmd! vimrc User lamp#initialized call s:on_initialized()
function! s:on_initialized()
  " built-in setting
  call lamp#builtin#intelephense()
  call lamp#builtin#html_languageserver()
  call lamp#builtin#css_languagserver()
  call lamp#builtin#typescript_language_server()
  call lamp#builtin#vim_language_server()
  call lamp#builtin#gopls()
  call lamp#builtin#rls()
  call lamp#builtin#pyls()

  " custom setting
  call lamp#register('example-server', {
        \   'command': ['example-server', '--stdio'],
        \   'filetypes': ['example'],
        \   'root_uri': { -> lamp#findup(['.git', 'example.config.json']) },
        \   'initialization_options': { -> {
        \   } },
        \   'capabilitis': {
        \     'completionProvider': {
        \       'triggerCharacters': [',']
        \     }
        \   }
        \ })
endfunction

"
" initialize buffers
"
autocmd! vimrc User lamp#text_document_did_open call s:on_text_document_did_open()
function! s:on_text_document_did_open() abort
  " completion
  setlocal omnifunc=lamp#complete

  " commands
  nnoremap <buffer> gf<CR>       :<C-u>LampDefinition edit<CR>
  nnoremap <buffer> gfs          :<C-u>LampDefinition split<CR>
  nnoremap <buffer> gfv          :<C-u>LampDefinition vsplit<CR>
  nnoremap <buffer> tgf<CR>      :<C-u>LampTypeDefinition edit<CR>
  nnoremap <buffer> tgfs         :<C-u>LampTypeDefinition split<CR>
  nnoremap <buffer> tgfv         :<C-u>LampTypeDefinition vsplit<CR>
  nnoremap <buffer> dgf<CR>      :<C-u>LampDeclaration edit<CR>
  nnoremap <buffer> dgfs         :<C-u>LampDeclaration split<CR>
  nnoremap <buffer> dgfv         :<C-u>LampDeclaration vsplit<CR>
  nnoremap <buffer> <Leader>i    :<C-u>LampHover<CR>
  nnoremap <buffer> <Leader>r    :<C-u>LampRename<CR>
  nnoremap <buffer> <Leader>g    :<C-u>LampReferences<CR>
  nnoremap <buffer> @            :<C-u>LampDocumentHighlight<CR>
  nnoremap <buffer> <Leader>@    :<C-u>LampDocumentHighlightClear<CR>
  nnoremap <buffer> <Leader>f    :<C-u>LampFormatting<CR>
  vnoremap <buffer> <Leader>f    :LampRangeFormatting<CR>
  nnoremap <buffer> <Leader><CR> :<C-u>LampCodeAction<CR>
  vnoremap <buffer> <Leader><CR> :LampCodeAction<CR>
  nnoremap <buffer> <C-n>        :<C-u>LampSelectionRangeExpand<CR>
  nnoremap <buffer> <C-p>        :<C-u>LampSelectionRangeCollapse<CR>
  vnoremap <buffer> <C-n>        :<C-u>LampSelectionRangeExpand<CR>
  vnoremap <buffer> <C-p>        :<C-u>LampSelectionRangeCollapse<CR>
  nnoremap <buffer> <C-k>        :<C-u>LampDiagnosticsPrev<CR>
  nnoremap <buffer> <C-j>        :<C-u>LampDiagnosticsNext<CR>
endfunction
```

# [Spec compatibility](https://microsoft.github.io/language-server-protocol/specifications/specification-3-15/)
<details>

    - General
        - [x] initialize
        - [x] initialized
        - [x] shutdown
        - [x] exit
        - [x] $/cancelRequest
        - [ ] $/progress

    - Window
        - [x] window/showMessage
        - [x] window/showMessageRequest
        - [x] window/logMessage
        - [ ] window/workDoneProgress/create
        - [ ] window/workDoneProgress/cancel

    - Telemetry
        - [x] telemetry/event

    - Client
        - [ ] ~~client/registerCapability~~ (Maybe unneeded)
        - [ ] ~~client/unregisterCapability~~ (Maybe unneeded)

    - Workspace
        - [x] workspace/workspaceFolders
        - [x] workspace/didChangeWorkspaceFolders
        - [x] workspace/didChangeConfiguration
        - [x] workspace/configuration
        - [ ] workspace/didChangeWatchedFiles
        - [ ] workspace/symbol
        - [x] workspace/executeCommand
        - [x] workspace/applyEdit

    - Synchronization
        - [x] textDocument/didOpen
        - [x] textDocument/didChange
        - [x] textDocument/willSave
        - [x] textDocument/willSaveWaitUntil
        - [x] textDocument/didSave
        - [x] textDocument/didClose

    - Diagnostics
        - [x] textDocument/publishDiagnostics

    - Language Features
        - [x] textDocument/completion
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
        - [x] textDocument/onTypeFormatting
        - [x] textDocument/rename
        - [x] textDocument/prepareRename
        - [ ] textDocument/foldingRange
        - [x] textDocument/selectionRange

    - Proposed
        - [ ] textDocument/semanticTokens
        - [ ] textDocument/callHierarchy

</details>

# TODO
- Use VS.System.Job and VS.RPC.JSON
- Support `textDocument/codeLens`
- Support `textDocument/onTypeFormatting` with `<CR>`
- Support `$/progress`
- Support `textDocument/semanticTokens`
- Support `textDocument/foldingRange`
- Custom highlighting in fenced language (e.g. underlined)
- Improve documentation
