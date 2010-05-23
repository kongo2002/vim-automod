" Vim filetype file
" Filename:     automod.vim
" Author:       Gregor Uhlenheuer
" Last Change:  Sun 23 May 2010 08:38:06 PM CEST

" omni completion
call omni#automod#Init()

" enable syntax based folding
setlocal foldmethod=syntax

" use literal tabs
setlocal noexpandtab

" correctly format comments
setlocal formatoptions=croql
setlocal comments=sO:*\ -,mO:*\ \ ,exO:*/,s1:/*,mb:*,ex:*/

" do not show non printable characters
setlocal nolist

" add some AutoMod specific words for matchit.vim
let b:match_words = '\<begin\>:\<end\>,'
                \ . '\%(else\s\+\)\@<!if\>:'
                \ . '\%(\<else\s\+\)\@<=if\>:'
                \ . '\<else\%(\s\+if\)\@!'

" make ftplugin undo-able
let b:undo_ftplugin = 'setl fdm< et< fo< com< list< | unlet b:match_words'
