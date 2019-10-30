if has('vim_starting')
  set encoding=utf-8
endif
scriptencoding utf-8

if &compatible
  set nocompatible
endif

if !filereadable('/tmp/plug.vim')
  silent !curl --insecure -fLo /tmp/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif

source /tmp/plug.vim

call plug#begin('/tmp/plugged')
Plug expand('<sfile>:p:h')
call plug#end()

let g:mapleader = ' '

autocmd! User lamp_initialized call s:on_lamp_initialized()
function! s:on_lamp_initialized() abort
  call lamp#config('logfile', '/tmp/lamp.log')
  call lamp#register('vim-language-server', {
        \   'command': ['vim-language-server', '--stdio'],
        \   'filetypes': ['vim'],
        \ })
endfunction

autocmd! User lamp_text_document_did_open call s:on_lamp_text_document_did_open()
function! s:on_lamp_text_document_did_open() abort
  nmap <buffer> gf<CR>    <Plug>(lamp-definition)
  nmap <buffer> gfs       <Plug>(lamp-definition-split)
  nmap <buffer> gfv       <Plug>(lamp-definition-vsplit)
  nmap <buffer> <Leader>i <Plug>(lamp-hover)
  nmap <buffer> <Leader>r <Plug>(lamp-rename)
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

