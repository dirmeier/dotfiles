set nocompatible              " be iMproved, required
filetype off                  " required

set rtp+=~/.config/nvim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
Plugin 'flazz/vim-colorschemes'
Plugin 'majutsushi/tagbar'
Plugin 'tpope/vim-sensible'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-rails'
Plugin 'tpope/vim-rake'
Plugin 'scrooloose/syntastic'
Plugin 'scrooloose/nerdtree'
Plugin 'slim-template/vim-slim'
Plugin 'tyru/open-browser.vim'
Plugin 'vim-scripts/a.vim'
Plugin 'jalvesaq/Nvim-R'
Plugin 'Valloric/YouCompleteMe'
Plugin 'https://github.com/rhysd/vim-clang-format.git'
Plugin 'https://github.com/kana/vim-operator-user.git'

call vundle#end()            " required
filetype plugin indent on    " required
nnoremap <C-Left> :tabprevious<CR>
nnoremap <C-Right> :tabnext<CR>

set tags=./tags;

let mapleader="\<SPACE>"
let g:python3_host_prog = '/Users/simondi/anaconda3/envs/py35/bin/python3.5'
let g:ycm_server_log_level = 'debug'
let NERDTreeIgnore = ['\.o$']
let NERDTreeDirArrows = 1
let g:ycm_server_keep_logfiles = 1
let g:ycm_server_log_level = 'debug'

autocmd VimEnter * NERDTree
autocmd VimEnter * wincmd p

colorscheme Monokai
set list
set listchars=eol:¬,tab:>·,trail:~,extends:>,precedes:<,space:.
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

set splitright
set splitbelow
set showcmd
set autoindent
set tabstop=2
set shiftwidth=2
set bs=2
set incsearch
set ignorecase
set smartcase

map <F2> :NERDTreeToggle<CR>
let g:indent_guides_start_level=2
