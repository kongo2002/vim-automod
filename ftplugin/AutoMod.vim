" Vim filetype file
" Filename:     AutoMod.vim
" Author:       Gregor Uhlenheuer
" Last Change:  So 28 Feb 2010 15:57:05 CET

" omni completion
call omni#AutoMod#Init()

" enable syntax based folding
setlocal foldmethod=syntax

" use literal tabs
setlocal noexpandtab

" do not show non printable characters
setlocal nolist

" add some AutoMod specific words for matchit.vim
let b:match_words = '\<begin\>:\<end\>,'
                \ . '\%(else\s\+\)\@<!if\>:'
                \ . '\%(\<else\s\+\)\@<=if\>:'
                \ . '\<else\%(\s\+if\)\@!'
