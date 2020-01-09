# vim-lamp
Language Server Protocol client for Vim.

# Concept
- Works on vim/nvim both
- High performance
- Well supported LSP spec
- Well visualize diagnostics

# Status
Well works but not docummented and APIs aren't stable.

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
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'
Plug 'hrsh7th/asyncomplete-lamp'
Plug 'prabirshrestha/asyncomplete.vim'
call plug#end()

"
" required options
"
set hidden
set ambiwidth=double
set completeopt=menu,menuone,noselect

augroup vimrc
  autocmd!
augroup END

"
" initialize servers
"
autocmd! vimrc User lamp#initialized call s:on_initialized()
function! s:on_initialized()
  " built-in setting
  call lamp#language#php()
  call lamp#language#html()
  call lamp#language#css()
  call lamp#language#typescript()
  call lamp#language#vim()
  call lamp#language#go()
  call lamp#language#rust()
  call lamp#language#python()

  " custom setting
  call lamp#register('example-server', {
        \   'command': ['example-server', '--stdio'],
        \   'filetypes': ['example'],
        \   'root_uri': { -> lamp#findup('.git', 'example.config.json') },
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

  " mappings
  nmap <buffer> gf<CR>         <Plug>(lamp-definition)
  nmap <buffer> gfs            <Plug>(lamp-definition-split)
  nmap <buffer> gfv            <Plug>(lamp-definition-vsplit)
  nmap <buffer> tgf<CR>        <Plug>(lamp-type-definition)
  nmap <buffer> tgfs           <Plug>(lamp-type-definition-split)
  nmap <buffer> tgfv           <Plug>(lamp-type-definition-vsplit)
  nmap <buffer> dgf<CR>        <Plug>(lamp-declaration)
  nmap <buffer> dgfs           <Plug>(lamp-declaration-split)
  nmap <buffer> dgfv           <Plug>(lamp-declaration-vsplit)
  nmap <buffer> <Leader>i      <Plug>(lamp-hover)
  nmap <buffer> <Leader>r      <Plug>(lamp-rename)
  nmap <buffer> <Leader>g      <Plug>(lamp-references)
  nmap <buffer> <Leader>f      <Plug>(lamp-formatting)
  vmap <buffer> <Leader>f      <Plug>(lamp-range-formatting)
  nmap <buffer> @              <Plug>(lamp-document-highlight)
  nmap <buffer> <Esc>          <Plug>(lamp-document-highlight-clear)
  nmap <buffer> <Leader><CR>   <Plug>(lamp-code-action)
  vmap <buffer> <Leader><CR>   <Plug>(lamp-code-action)
endfunction
```

# [Spec compatibility](https://microsoft.github.io/language-server-protocol/specifications/specification-3-14/)
<details>

    - General
        - [x] initialize
        - [x] initialized
        - [x] shutdown
        - [x] exit
        - [ ] $/cancelRequest

    - Window
        - [x] window/showMessage
        - [x] window/showMessageRequest
        - [x] window/logMessage

    - Telemetry
        - [x] telemetry/event

    - Client
        - [ ] ~~client/registerCapability~~ (Maybe unneeded)
        - [ ] ~~client/unregisterCapability~~ (Maybe unneeded)

    - Workspace
        - [ ] workspace/workspaceFolders
        - [ ] workspace/didChangeWorkspaceFolders
        - [x] workspace/didChangeConfiguration
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

</details>

# TODO
- Custom highlighting in fenced language (e.g. underlined)
- Improve documentation
- Design canceling outdated request
- Trim floatwin sizes when completion
