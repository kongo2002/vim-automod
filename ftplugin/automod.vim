" Vim filetype file
" Filename:     automod.vim
" Author:       Gregor Uhlenheuer
" Last Change:  Fri 03 Jun 2011 10:47:32 PM CEST

" omni completion
call omni#automod#Init()

" enable syntax based folding
setlocal foldmethod=syntax

" use hard tabs
setlocal noexpandtab
setlocal shiftwidth=4
setlocal tabstop=4

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

function! s:ExtMethod(start, end)

    if a:start <= 0 || (a:end - a:start < 1)
        return
    endif

    let selection = inputlist(['Select method to extract:',
                \ '1. procedure',
                \ '2. subroutine'])

    if selection < 1 || selection > 2
        return
    endif

    let name = input('Enter method name: ')

    if name == '' | return | endif

    let content = []

    for line in range(a:start, a:end)
        call add(content, getline(line))
    endfor

    sil! exec a:start . ',' . a:end . 'd_'

    call append(a:start, selection == 1 ?
                \ ['send to ' . name, ''] :
                \ ['call ' . name, ''])

    let begin = line('$')

    call append(begin, selection == 1 ?
                \ ['', 'begin ' . name . ' arriving procedure', ''] :
                \ ['', 'begin ' . name . ' procedure', ''])

    call append(line('$'), content)

    call append(line('$'), ['', 'end'])

    call cursor(begin, 0)
    silent norm! =G

endfunction

com! -nargs=0 -range=% -buffer ExtractMethod call <SID>ExtMethod(<line1>,<line2>)
