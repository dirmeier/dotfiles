set nocompatible              " be iMproved, required
filetype off                  " required

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
"call vundle#begin('~/some/path/here')
" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
"
Plugin 'tpope/vim-sensible'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-fugitive'
"Plugin 'tpope/vim-rails'
"Plugin 'tpope/vim-rake'
"Plugin 'scrooloose/syntastic'
Plugin 'scrooloose/nerdtree'
Plugin 'slim-template/vim-slim'

Plugin 'flazz/vim-colorschemes'
call vundle#end()            " required
filetype plugin indent on    " required
let g:ycm_server_log_level = 'debug'
let NERDTreeIgnore = ['\.o$']

colorscheme elflord
set list
set listchars=eol:¬,tab:>·,trail:~,extends:>,precedes:<
set wrap!
set colorcolumn=79

highlight ColorColumn ctermbg=black guibg=black
highlight ColorColumnSingle ctermbg=red guibg=red
call matchadd('ColorColumnSingle', '\%80v', 1)

let fortran_free_source=0
let fortran_do_enddo=1
filetype plugin indent on
syntax on
set syntax=whitespace
set nu
set ruler

set showcmd

set smartindent
set autoindent
set tabstop=2
set shiftwidth=2
set bs=2

set incsearch
set ignorecase
set smartcase

let g:indent_guides_start_level=2
