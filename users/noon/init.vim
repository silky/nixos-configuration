let g:ormolu_disable=1

let $FZF_DEFAULT_COMMAND = 'rg --files -M 1000'
let g:fzf_preview_window = ''

" Firstly define the leaders.
let mapleader=','
let maplocalleader=','

" Use par for prettier line formatting
set formatprg="PARINIT='rTbgqR B=.,?_A_a Q=_s>|' par\ -w72"

set nocompatible
syntax on
colorscheme noon-light


" Set 7 lines to the cursor - when moving vertically using j/k
set so=7
" Turn on the WiLd menu
set wildmenu
" Tab-complete files up to longest unambiguous prefix
set wildmode=list:longest,full

" Show trailing whitespace
set list
" But only interesting whitespace
if &listchars ==# 'eol:$'
  set listchars=tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+
endif

" Remove trailing whitespace on save
fun! <SID>StripTrailingWhitespaces()
    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
    call cursor(l, c)
endfun

autocmd BufWritePre * :call <SID>StripTrailingWhitespaces()

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" https://www.hillelwayne.com/post/intermediate-vim/
set inccommand=nosplit

set ai   " Auto indent
set si   " Smart indent
set wrap " Wrap lines


" Treat long lines as break lines
nnoremap j gj
nnoremap k gk


" Return to last edit position when opening files
augroup last_edit
  autocmd!
  autocmd BufReadPost *
       \ if line("'\"") > 0 && line("'\"") <= line("$") |
       \   exe "normal! g`\"" |
       \ endif
augroup END
" Remember info about open buffers on close
set viminfo^=%

" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)



" Enable some tabular presets for Haskell
let g:haskell_tabular = 1



set mouse=a
set shortmess=at  " Ensure we don't get hit-enter prompts
set grepprg=grep\ -nH\ $*
set t_Co=256
set wildignore+=*.pyc,*.pdf,.git,.svn,*.png,*.jpg,*.ps,*.log,*.aux,*.out,*.dvi,*.fdb_latexmk,*.pyo
set wildignore+=*.lib,*.exe,*.dll,*.pdb,*.exp
set winheight=30  " Autosize window to this height.
set encoding=utf-8
set modelines=1

set cpoptions+=I "do NOT revert tabbing I have specifically set.
set cindent
set smartcase     " Case insensitive searches become sensitive with capitals
set lazyredraw
set showmode
set showcmd
set ruler
set ttyfast
set laststatus=2
set history=10000
set undofile
set undoreload=10000
set nolist
set shell=zsh
set autoread
set display=uhex
set nofsync
set shiftround
set notimeout
set nottimeout
set autowrite


set guioptions=aegit
set completeopt=longest,menuone,preview " TODO: Review
set smarttab
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set wrap
set textwidth=78
set formatoptions=qrjtco


set noswapfile
set undodir=~/.tmp/vim/undo/      " undo files
set backupdir=~/.tmp/vim/backup/  " backups
set directory=~/.tmp/vim/swap/    " swap files
set nobackup                      " disabled
set nowb
set nocursorcolumn
set nocursorline
set rnu

let $NVIM_TUI_ENABLE_CURSOR_SHAPE = 0
set guicursor=

set clipboard+=unnamedplus

" let g:clipboard = {
"   \   'name': 'helic',
"   \   'copy': {
"   \      '+': 'hel yank --agent nvim',
"   \      '*': 'hel yank --agent nvim',
"   \    },
"   \   'paste': {
"   \      '+': 'xsel -bo',
"   \      '*': 'xsel -bo',
"   \   },
"   \ }

" Status line -----------------------------------------------------------------

set statusline=%f    " Path.
set statusline+=%m   " Modified flag.
set statusline+=%r   " Readonly flag.
set statusline+=%w   " Preview window flag.

set statusline+=\    " Space.

"set statusline+=%#redbar#                " Highlight the following as a warning.
"set statusline+=%{SyntasticStatuslineFlag()} " Syntastic errors.
"set statusline+=%*                           " Reset highlighting.

set statusline+=%=   " Right align.

" File format, encoding and type.  Ex: "(unix/utf-8/python)"
set statusline+=(
set statusline+=%{&ff}                        " Format (unix/DOS).
set statusline+=/
set statusline+=%{strlen(&fenc)?&fenc:&enc}   " Encoding (utf-8).
set statusline+=/
set statusline+=%{&ft}                        " Type (python).
set statusline+=)

" Line and column position and counts.
set statusline+=\ (line\ %l\/%L,\ col\ %03c)


" Use sane regexes.
nnoremap / /\v
vnoremap / /\v

set ignorecase
set smartcase
set incsearch
set hlsearch
set noshowmatch

set gdefault

set scrolloff=3
set sidescroll=1
set sidescrolloff=10

set virtualedit+=block


" Diable man lookup
nnoremap K <nop>
vnoremap K <nop>

vnoremap r "_dP

" r for repeat
nnoremap r .

noremap ' `
noremap ` <C-^>

" Faster way to get into command mode.
noremap ; :

noremap YY :%y+<cr>


" Shortcuts for saving
nnoremap <S-Space> :wa<cr>
nnoremap <Space> :w<cr>


" Keep search matches in the middle of the window.
nnoremap n nzzzv
nnoremap N Nzzzv

noremap <Home> <Esc>^



" Navigation keys
inoremap <Up>    <nop>
inoremap <Down>  <nop>
inoremap <Left>  <nop>
inoremap <Right> <nop>
noremap <Up>     <nop>
noremap <Down>   <nop>
noremap <Left>   <nop>
noremap <Right>  <nop>


" Paste from general clipboard.
noremap <leader>p "+p
" Yank to the general clipboard.
noremap <leader>y "+y

" set termguicolors
set clipboard+=unnamed

" Mapping selecting mappings
nmap <Tab>e :Files<cr>
nmap <Tab>s :GFiles?<cr>
" TODO: How to make this work with input()/<expr> ?
" nmap <Tab>l :Lines <cr>

" Window Navigation
noremap <Tab>h <C-w>h
noremap <Tab>j <C-w>j
noremap <Tab>k <C-w>k
noremap <Tab>l <C-w>l
noremap <Tab><Tab> <C-w>p

" Clear highlights from search, also sets the last search to be empty.
noremap <silent> <leader><space> :noh<cr>:call clearmatches()<cr>


function! SynStack()
  if !exists("*synstack")
    return
  endif
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc


let g:matchparen_timeout = 10
let g:matchparen_insert_timeout = 10


set timeoutlen=1000 ttimeoutlen=0



nmap \\  <Plug>CommentaryLine
vmap \\  <Plug>Commentary


" EasyMotion
let g:EasyMotion_leader_key = '.'


au BufRead,BufNewFile *.agda call AgdaFiletype()
au QuitPre *.agda :CornelisCloseInfoWindows
function! AgdaFiletype()
    nnoremap <buffer> <leader>l :CornelisLoad<CR>
    nnoremap <buffer> <leader>r :CornelisRefine<CR>
    nnoremap <buffer> <leader>d :CornelisMakeCase<CR>
    nnoremap <buffer> <leader>, :CornelisTypeContext<CR>
    nnoremap <buffer> <leader>. :CornelisTypeContextInfer<CR>
    nnoremap <buffer> <leader>m :CornelisQuestionToMeta<CR>
    nnoremap <buffer> <leader>n :CornelisSolve<CR>
    nnoremap <buffer> <leader>a :CornelisAuto<CR>
    nnoremap <buffer> <leader>g :CornelisGive<CR>
    nnoremap <buffer> gd        :CornelisGoToDefinition<CR>
    nnoremap <buffer> Ng        :CornelisPrevGoal<CR>
    nnoremap <buffer> ng        :CornelisNextGoal<CR>
    nnoremap <buffer> <C-A>     :CornelisInc<CR>
    nnoremap <buffer> <C-X>     :CornelisDec<CR>
    " call cornelis#bind_input("st", "≡⟨⟩")
    let g:cornelis_no_agda_input=1
endfunction


" Depends on 'vim-agda-input' plugin. Uncomment this to disable it:
" let g:agda_input_no_agda_input=1
let g:agda_input_prefix="<S-Tab>"
" call agda_input#bind_input("~", "~")
call agda_input#bind_input("st", "≡⟨⟩")


vmap <leader><space> <Plug>(EasyAlign)


let g:easy_align_delimiters = {
\ 'r': { 'pattern': '[≤≡≈∎]', 'left_margin': 2, 'right_margin': 0 },
\ }



" Pandoc
augroup ft_pandoc
    au!

    " Convert current file to pdf.
    au FileType pandoc noremap <buffer> <leader>ll :!pandoc -o "%.pdf" --template=a.latex "%"<cr>
    au FileType pandoc setlocal nocindent
    au FileType pandoc setlocal formatoptions=tcqron1
augroup END

let g:elm_format_autosave = 0

" https://ro-che.info/articles/2020-07-08-integrate-ghcid-vim
set errorformat=%C%*\\s•\ %m,
               \%-C\ %.%#,
               \%A%f:%l:%c:\ %t%.%#


" Vim quick-scope
" https://github.com/unblevable/quick-scope
" Trigger a highlight in the appropriate direction when pressing these keys:
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']
