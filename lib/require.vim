" require.vim
"
" Defining Require command (like expression) and Require() function.
"
" The Require Command will import a vim module/file/plugin
"
" The Require() Function will import the module, and return s:exports in
" that module
"
" NOTE:
" .vim or .vimrc
" This is defining, not funcion,
" so no need to source the whole vimrc
" so, just use '.vim'
"
" DONE:
" 'require' need throw an error when module not found
"
" NOTE: the '%:p' in require.vim script's function
" will be the require.vim's path. so we pass a <sfile> in.
"
" TODO
" source file of dirs with following sequence.
"   relative dir
"   relative dir and it's all parent's modules/ directory: if got one.
"   vim-box's dir
"   vim runtime
"
" DONE:
" Avoid recursive chain requiring
"
" DONE:
" merge s:require and Require
"
" NOTE: This file is in vim-box/lib
"
" XXX
"   We should not use cache, or cache for $VIMRUNTIME only,
"   as it will not load relative modules.
" SOLVED:
"   use full path not module name as key (s:modules)
"   and then removed chain name
"
" DONE:
" the file name include '..' is not normalized.
let s:box_dir = expand('<sfile>:p:h:h')

let g:require_module_index = 'index'

" Require for command
let s:_main = ''
let s:modules = {}

" contain all the exported values
let s:exports = {}
let g:_r = [s:_main,s:modules,s:exports]


function! s:require(module, sfile, ...)

    let slnum = a:0 ? a:1 : 0

    " normalize filename with '/', for mac
    let m = fnamemodify(a:module, ':gs?\\?/?')
    let p = fnamemodify(a:sfile, ':h:gs?\\?/?')
    let _sep = '/'
    let tail = fnamemodify(a:module, ':t:r:gs?\\?/?')

    " STEP1: generate possible paths
    let _files = [
            \ p ._sep. m .'.vim',
            \ p ._sep. m ._sep. tail.'.vim',
            \ p ._sep. m ._sep. 'index.vim',
            \ s:box_dir ._sep. m .'.vim',
            \ $VIMRUNTIME ._sep. m .'.vim',
            \ ]

    " get all modules of the parents dir
    let p_len = len(split(p, _sep))
    let parents = map(range(p_len), 'fnamemodify(p, repeat(":h" ,v:val))')
    call map(parents, 'v:val._sep."modules"'
            \ .'._sep.m._sep.g:require_module_index .".vim"')
    call extend(_files, parents, 1)
    call filter(_files, 'filereadable(v:val)')

    " STEP2: source the valid file.
    if !empty(_files)
        let f = resolve(_files[0])

        " NOTE: Avoid recursive chaining
        if !exists("s:modules[f]")
            let s:modules[f] = {}
        else
            Debug '!!!!Already required '.f
            if exists('s:exports[f]')
                return s:exports[f]
            else
                return 0
            endif
        endif

        if s:_main == ''
            let s:_main = f
            let s:modules[f].chain = {}
            let s:modules[f].chain[f] = 1
            Debug '>>>>  '.m
        else
            " AVOID recursive require chain
            let s:modules[s:_main].chain[f] = 1
        endif

        Debug 'so '.f
        exe g:debug ? 'so '.f :  'silent so '.f

        if s:_main == f
            let s:_main = ''
            Debug '<<<<  '.m
        endif

        if exists('s:exports[f]')
            return s:exports[f]
        else
            return 0
        endif

    else
        " NOTE: we can use setqflist or cex to set error list.
        throw  m . " MODULE NOT FOUND:  ".a:sfile. ":". slnum
    endif

endfun

function! Require(module, sfile)
    return s:require(a:module, a:sfile)
endfunction

function! Exports(val, sfile, bang) abort
    let bang = a:bang == '!' ? 1 : 0

    let f = resolve(fnamemodify(a:sfile, ':p:gs?\\?/?'))

    if !bang && exists('s:exports[f]')
        throw "ALREADY EXPORTED ".s:exports[f].' '.f
    else
        let s:exports[f] = a:val
    endif

endfunction
function! Path()
    return eval("expand('<cfile>:p')")
endfunction

com! -nargs=* Require call s:require(<q-args>, expand('<sfile>:p'), expand('<slnum>'))
com! -nargs=* -bang Exports call Exports(<args>, expand('<sfile>:p'), "<bang>")
