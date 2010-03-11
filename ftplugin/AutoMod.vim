" Vim filetype file
" Filename:     AutoMod.vim
" Author:       Gregor Uhlenheuer
" Last Change:  Do 11 Mär 2010 20:07:28 CET

" omni completion
call omni#AutoMod#Init()

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
