" Vim filetype file
" Filename:     AutoMod.vim
" Author:       Gregor Uhlenheuer
" Last Change:  Sun 21 Mar 2010 07:18:47 PM CET

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
