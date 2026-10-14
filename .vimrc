syntax on
colorscheme habamax
set foldmethod=syntax
set foldenable
set number relativenumber
"set showtabline=2
"set guitablabel=%N:\ %t%M
call plug#begin('~/.vim/plugged')
" Добавьте плагин
Plug 'Townk/vim-autoclose'
Plug 'preservim/nerdtree'
Plug 'prabirshrestha/vim-lsp'
Plug 'hrsh7th/vim-vsnip'
Plug 'rafamadriz/friendly-snippets'
Plug 'hrsh7th/vim-vsnip-integ'
Plug 'cdelledonne/vim-cmake'
Plug 'kmonad/kmonad-vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
call plug#end()
set tabstop=4      " Ширина таба по умолчанию (в пробелах)
set shiftwidth=4   " Размер отступа при командах форматирования (>> и <<)
set noexpandtab 
set tags=tags;
filetype plugin indent on
noremap j h
noremap k j
noremap l k
noremap ; l
let mapleader = " "   " пробел как лидер

nnoremap <Leader>j <C-W>h
nnoremap <Leader>k <C-W>j
nnoremap <Leader>l <C-W>k
nnoremap <Leader>; <C-W>l
filetype plugin on
highlight Normal ctermbg=none guibg=NONE
highlight NonText ctermbg=none guibg=NONE
let g:lsp_use_native_client = 1
let g:cmake_build_target_option = '-target'
let g:clipboard = {
\   'name': 'xclip',
\   'copy': {
\       '+': 'xclip -selection clipboard',
\       '*': 'xclip -selection primary',
\   },
\   'paste': {
\       '+': 'xclip -selection clipboard -o',
\       '*': 'xclip -selection primary -o',
\   },
\ }

set clipboard=unnamedplus
if executable('clangd')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'clangd',
        \ 'cmd': {server_info->[
        \   'clangd', 
        \   '--compile-commands-dir=build', '--background-index'
        \ ]},
        \ 'allowlist': ['c', 'cpp', 'objc', 'objcpp'],
        \ 'root_uri': {server_info->lsp#utils#path_to_uri(
        \   lsp#utils#find_nearest_parent_file_directory(
        \     lsp#utils#get_buffer_path(), 
        \     ['.git', 'compile_commands.json', 'build/compile_commands.json']
        \   ))},
        \ })
endif
augroup vsnip_fold_fix
    autocmd!
    autocmd User VsnipExpandPre  setlocal nofoldenable
    autocmd User VsnipExpandPost setlocal foldenable
augroup END

imap <expr> <C-j>   vsnip#expandable()  ? '<Plug>(vsnip-expand)<Esc>a' : '<C-j>'
smap <expr> <C-j>   vsnip#expandable()  ? '<Plug>(vsnip-expand)'         : '<C-j>'

" Раскрыть сниппет или перейти к следующему плейсхолдеру
imap <expr> <C-l>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>'
smap <expr> <C-l>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>'

" Перемещение по плейсхолдерам
imap <expr> <Tab>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
smap <expr> <Tab>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
imap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
smap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
" Навигация по меню дополнения
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Подтверждение выбора (Enter)
inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<CR>"

function! s:on_lsp_buffer_enabled() abort
    setlocal omnifunc=lsp#complete
    nmap <buffer> gd <plug>(lsp-definition)      " перейти к определению
    nmap <buffer> gr <plug>(lsp-references)      " найти все использования
    nmap <buffer> K  <plug>(lsp-hover)           " показать документацию
    nmap <buffer> gi <plug>(lsp-implementation)  " перейти к реализации
 "   nmap <buffer> gt <plug>(lsp-type-definition) " перейти к определению типа
    nmap <buffer> <F2> <plug>(lsp-rename)        " переименовать символ
    nmap <buffer> ga <plug>(lsp-code-action)     " показать доступные действия
    nmap <buffer> [g <plug>(lsp-previous-error)  " предыдущая ошибка
    nmap <buffer> ]g <plug>(lsp-next-error)      " следующая ошибка
endfunction

augroup lsp_install
    au!
	autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END
set ttimeoutlen=1

function! CMakeBuildAndRun()
    execute "wa"
    
    " Создание build директории
    if !isdirectory("build")
        echo "Creating build directory..."
        call mkdir("build")
    endif
    
    " Запуск CMake если нужно
    if !filereadable("build/CMakeCache.txt")
        echo "Running CMake configuration..."
        execute "terminal cmake -B build"
        sleep 1000m " Даем больше времени
    endif
    
    " Сборка
    echo "Building project..."
    execute "terminal cmake --build build"
    sleep 1000m
    
    " Поиск исполняемого файла
    let exe_files = split(glob("build/*"), '\n')
    let exe_file = ""
    
    " Сначала ищем main, затем любой исполняемый
    for file in exe_files
        if executable(file) && file =~ 'main\|test\|app\|run'
            let exe_file = file
            break
        endif
    endfor
    
    " Если не нашли, берем любой исполняемый
    if exe_file == ""
        for file in exe_files
            if executable(file)
                let exe_file = file
                break
            endif
        endfor
    endif
    
    " Запуск
    if exe_file != ""
        echo "Running: " . exe_file
        if executable(exe_file)
            " Запускаем с паузой
            execute "terminal " . exe_file . " ; echo '' ; echo 'Program finished. Press any key to close...' ; read -n 1"
        endif
    else
        echo "No executable found in build directory!"
        echo "Files in build: " . join(exe_files, ", ")
    endif

endfunction

nnoremap <F5> :call CMakeBuildAndRun()<CR>
