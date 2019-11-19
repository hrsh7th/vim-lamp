if has('vim_starting')
  set encoding=utf-8
endif
scriptencoding utf-8

if &compatible
  " vint: -ProhibitSetNoCompatible
  set nocompatible
endif

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
set completeopt=menu,menuone,noselect

"
" vim-vsnip mapping.
"
imap <expr><Tab> vsnip#expandable_or_jumpable() ? '<Plug>(vsnip-expand-or-jump)' : '<Tab>'
smap <expr><Tab> vsnip#expandable_or_jumpable() ? '<Plug>(vsnip-expand-or-jump)' : '<Tab>'

augroup vimrc
  autocmd!
augroup END

"
" initialize servers.
"
autocmd! vimrc User lamp#initialized call s:on_initialized()
function! s:on_initialized()
  call lamp#config('debug.log', '/tmp/lamp.log')
  call lamp#config('feature.completion.snippet.expand', { option -> vsnip#anonymous(option.body) })

  call lamp#register('vim-language-server', {
        \   'command': ['vim-language-server', '--stdio'],
        \   'filetypes': ['vim'],
        \ })

  call lamp#register('html-languageserver', {
        \   'command': ['html-languageserver', '--stdio'],
        \   'filetypes': ['html', 'css'],
        \   'initialization_options': { -> {
        \     'embeddedLanguages': []
        \   } },
        \   'capabilities': {
        \     'completionProvider': {
        \       'triggerCharacters': ['>'],
        \     }
        \   }
        \ })

  call lamp#register('intelephense', {
        \   'command': ['intelephense', '--stdio'],
        \   'filetypes': ['php'],
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

  imap <expr><Tab> vsnip#expandable_or_jumpable() ? '<Plug>(vsnip-expand-or-jump)' : lamp#map#confirm('<Tab>')
  smap <expr><Tab> vsnip#expandable_or_jumpable() ? '<Plug>(vsnip-expand-or-jump)' : lamp#map#confirm('<Tab>')
endfunction

nnoremap H 20h
nnoremap J 10j
nnoremap K 10k
nnoremap L 20l
vnoremap H 20h
vnoremap J 10j
vnoremap K 10k
vnoremap L 20l

nnoremap <Leader>h <C-w>h
nnoremap <Leader>j <C-w>j
nnoremap <Leader>k <C-w>k
nnoremap <Leader>l <C-w>l

nnoremap <C-h> <C-o>
nnoremap <C-l> <C-i>

nmap <Tab> %
vmap <Tab> %

nnoremap q :<C-u>q<CR>
nnoremap Q :<C-u>qa!<CR>
nnoremap <Leader>t :<C-u>tabclose<CR>
nnoremap <Leader>w :<C-u>w<CR>
nmap ; :
vmap ; :
xmap ; :
nnoremap = ^
vnoremap = ^
nnoremap + =
vnoremap + =
nnoremap @ q
nnoremap j gj
nnoremap k gk
nnoremap < <<<Esc>
nnoremap > >><Esc>
vnoremap < <<<Esc>
vnoremap > >><Esc>

