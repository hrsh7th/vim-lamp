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
Plug expand('<sfile>:p:h:h') . '/vim-lamp'
Plug expand('<sfile>:p:h:h') . '/vim-vsnip'
Plug expand('<sfile>:p:h:h') . '/vim-vsnip-integ'
Plug expand('<sfile>:p:h:h') . '/asyncomplete-lamp'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'https://github.com/gruvbox-community/gruvbox'
call plug#end()

colorscheme gruvbox

let g:mapleader = ' '

"
" required options.
"
set hidden
set ambiwidth=double
set completeopt=menu,menuone,noselect

"
" vim-vsnip mapping.
"
imap <expr><Tab> vsnip#available() ? '<Plug>(vsnip-expand-or-jump)' : '<Tab>'
smap <expr><Tab> vsnip#available() ? '<Plug>(vsnip-expand-or-jump)' : '<Tab>'

augroup vimrc
  autocmd!
augroup END

"
" initialize servers.
"
autocmd! vimrc User lamp#initialized call s:on_initialized()
function! s:on_initialized()
  call lamp#config('debug.log', '/tmp/lamp.log')
  call lamp#language#python()
  call lamp#language#rust()
  call lamp#language#go()
  call lamp#language#vim()
  call lamp#language#typescript()
  call lamp#language#yaml()
  call lamp#language#css()
  call lamp#language#html()
  call lamp#language#php()
endfunction

"
" initialize buffers.
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

  imap <expr><Tab> vsnip#available(1)    ? '<Plug>(vsnip-expand-or-jump)' : '<Tab>'
  smap <expr><Tab> vsnip#available(1)    ? '<Plug>(vsnip-expand-or-jump)' : '<Tab>'
  imap <expr><S-Tab> vsnip#available(-1) ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
  smap <expr><S-Tab> vsnip#available(-1) ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
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

