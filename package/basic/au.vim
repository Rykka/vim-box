
autocmd BufEnter * silent! lcd %:p:h

aug au_GuiEnter "{{{
    au!
    au GuiEnter * set t_vb=
    " awesome don't need this
    " exe "au GuiEnter * winpos ".s:win_pos." 0"
    " exe "au GuiEnter * set columns=".s:win_col." lines=".s:win_row
aug END "}}}
aug au_VimEnter " {{{
    au!
    " if !has("gui_running")
    "     au InsertEnter * silent execute "!gconftool-2 --type string --set /apps/gnome-terminal/profiles/Default/cursor_shape ibeam"
    "     au InsertLeave * silent execute "!gconftool-2 --type string --set /apps/gnome-terminal/profiles/Default/cursor_shape block"
    "     au VimLeave * silent execute "!gconftool-2 --type string --set /apps/gnome-terminal/profiles/Default/cursor_shape block"
    " endif
aug END
"}}}
aug au_Vimrc "{{{
    au!
    autocmd! BufWritePost vimrc source %
    autocmd! BufWritePost *.vimrc source $VIM_BOXRC
    " au SourcePre ~/Dropbox/dotfiles/.vimrc redraw | echohl WarningMsg
    "             \|echom "Reloading .vimrc"|echohl Normal
    " au BufWritePre,FileWritePre ~/Dropbox/dotfiles/.vimrc  LastUpdate
    " au BufWritePost,FileWritePost ~/Dropbox/dotfiles/.vimrc redraw
    "             \|echohl WarningMsg
    "             \|echom "Writing .vimrc"|echohl Normal
    "             \|so $MYVIMRC|normal '.zv
    " load vimrc after load any session.
    " au SessionLoadPost * so ~/.vimrc
    " avoid using function while redefine it.
    " au BufRead */.vimrc map <buffer> <F5> :silent so %<CR>
aug END "}}}
aug au_Buffer "{{{
    au!
    au BufEnter,BufNew,BufReadPost * silent! lcd %:p:h:gs/ /\\ /
    au BufEnter,BufNew,BufReadPost * silent! exec 'setl sua+=.'.expand('<afile>:e')

    " to the line when file last opened
    au BufReadPost * if line("'\"") && line("'\"") <= line("$") | exe  "normal! g`\"" | endif
aug END "}}}

aug au_Filetypes "{{{
    au!
    au BufRead,BufNewFile *.j,*.wct setf jass
    au BufRead,BufNewFile *.mako    setf mako
    au BufRead,BufNewFile *.conf    setf conf
    au BufRead,BufNewFile tmux.conf setf tmux
    au BufRead,BufNewFile *.hbs setf mustache
    au FileType c,cpp    setl fdm=syntax
    au FileType jass     setl wrap fdm=syntax
    au FileType jass     nor <buffer> gD :call <SID>jass_goDef()<CR>
    au FileType javascript call <SID>js_fold()
    au FileType javascript setl sw=2
    au FileType python map <buffer> <F1> :Pydoc <C-R><C-W><CR>
    au FileType python map <buffer> K k
    au FileType python setl wrap foldtext=MyFoldText()
    au BufRead,BufNewFile *.edge setf html
    " au FileType python  call <SID>py_aug()
    au FileType python  setl fdm=indent
    " au FileType javascript setl fdm=syntax
    au Filetype php,html,xhtml,xml setl shiftwidth=4 softtabstop=4
    au Filetype php,html,xhtml,xml setl foldmethod=indent
    au Filetype php setl smartindent
    au Filetype php cal <SID>check_html()
    au BufRead,BufNewFile *template*.php    setf conf
    au FileType help setl isk+=-,:
    au FileType help call <SID>hlp_fold()
    au FileType vim setl isk+=:
    au FileType html cal <SID>check_ft()
    " au FileType rst syn spell toplevel
    "
    au FileType javascript cal <SID>set_path()
    au FileType cs setl fdm=syntax
aug END "}}}

aug au_Dev "{{{
    au!
    " au BufWritePre,FileWritePre momo_bridge{_dev,}\.*\.js  LastUpdate
aug END "}}}

fun! s:check_html() "{{{
    " The html template file place
    if expand('<afile>:p') =~ '\v[/\\]%(template|views)[/\\]'
        set ft=html
    endif
endfun "}}}
fun! s:check_ft() "{{{
    " The django file place
    if expand('<afile>:p') =~ '\v[/\\]%(templates|views)[/\\]'
        set ft=htmldjango
    endif
endfun "}}}

function! s:hlp_fold() "{{{
    setl foldmethod=syntax
    setl foldtext=MyHlpFoldText()
    syn region foldBraces start=/[-=]\{50,}/
                \ end=#\ze[-=]\{50,}# transparent fold keepend
endfunction "}}}
function! MyHlpFoldText() "{{{
    let dash = getline(v:foldstart)[0]
    let line = getline(v:foldstart+1)
    let num  = printf("%4s",(v:foldend-v:foldstart))
    let line = substitute(line, '\%>44c\%<53c', '['.dash.num.']', '')
    return line
endfunction "}}}

" JavaScript {{{2
function! s:js_fold() "{{{
    setl foldmethod=syntax
    syn region foldBraces start=/{/ skip=#/\%([^/]\|\/\)*/\|'[^']*'\|"[^"]*"#
                \ end=/}/ transparent fold keepend extend
endfunction "}}}
" }}}

" Resize the divisions if the Vim window size changes {{{

au VimResized * exe "normal! \<c-w>="



" Execution permissions by default to shebang (#!) files {{{

augroup shebang_chmod
  autocmd!
  autocmd BufNewFile  * let b:brand_new_file = 1
  autocmd BufWritePost * unlet! b:brand_new_file
  autocmd BufWritePre *
        \ if exists('b:brand_new_file') |
        \   if getline(1) =~ '^#!' |
        \     let b:chmod_post = '+x' |
        \   endif |
        \ endif
  autocmd BufWritePost,FileWritePost *
        \ if exists('b:chmod_post') && executable('chmod') |
        \   silent! execute '!chmod '.b:chmod_post.' "<afile>"' |
        \   unlet b:chmod_post |
        \ endif
augroup END
" }}}

fu! s:getparent(item)
	let parent = substitute(a:item, '[\/][^\/]\+[\/:]\?$', '', '')
	if parent == '' || parent !~ '[\/]'
		let parent .= '/'
	en
	retu parent
endf


fun! s:set_path()

    let markers = ['.git', '.hg', '.svn', '.bzr', '_darcs', 'package.json']
    " setl path =
    let root =  s:findroot(getcwd(), markers, 0)

    setl path+=/usr/local/lib/node_modules
    if !empty(root)
        exec "setl path+=".root[1]
        exec "setl path+=".root[1].'/node_modules'
    endif

    setl includeexpr=join([v:fname,'index.js'],'/')
    
endfun


fu! s:findroot(curr, mark, depth)
	let [depth, fnd] = [a:depth + 1, 0]
	if type(a:mark) == 1
		let fnd = s:glbpath(s:fnesc(a:curr, 'g', ','), a:mark, 1) != ''
	elsei type(a:mark) == 3
		for markr in a:mark
			if s:glbpath(s:fnesc(a:curr, 'g', ','), markr, 1) != ''
				let fnd = 1
				brea
			en
		endfo
	en
	if fnd
		retu [exists('markr') ? markr : a:mark, a:curr]
	elsei depth > 10
        echo '>10'
	el
		let parent = s:getparent(a:curr)
		if parent != a:curr
			retu s:findroot(parent, a:mark, depth)
		en
	en
	retu []
endf

fu! s:glbpath(...)
	retu call('ctrlp#utils#globpath', a:000)
endf

fu! s:fnesc(...)
	retu call('ctrlp#utils#fnesc', a:000)
endf

