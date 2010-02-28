" Description:  omni completion for AutoMod
" Maintainer:   Gregor Uhlenheuer
" Last Change:  So 28 Feb 2010 16:40:55 CET

if v:version < 700
    echohl WarningMsg
    echomsg "omni#AutoMod.vim: Please install vim 7.0 or higher"
    echohl None
    finish
endif

function! omni#AutoMod#Init()
    set omnifunc=omni#AutoMod#Main
    call omni#AutoMod#Cache()
endfunction

if !exists('s:cache')
    "unlet s:cache
    let s:cache = {}
endif

function! omni#AutoMod#Cache()
    " get start directory
    let depth = ':p:h'
    let base = expand('%'.depth)
    while match(base, '\.\%(arc\)\|\%(dir\)$') != -1
        let depth .= ':h'
        let base = expand('%'.depth)
    endwhile

    " get asy file locations
    let models = split(globpath(base, "**/model.amo"), "\n")
    let mainmodel = ''
    let len = 0
    let asys = []

    for model in models
        let model = substitute(model, '.*\zsmodel.amo$', '', '')

        " determine shortest model name -> main model
        if len == 0 || len(model) < len
            let mainmodel = model
            let len = len(model)
        endif

        let asys += split(glob(model . "*.asy"), "\n")
    endfor

    " determine main model name
    let s:main = matchstr(mainmodel, '[^/]\+\ze.arc\/\=$')

    " read files
    for fp in asys
        let entities = []
        let name = matchstr(fp, '\w\+\ze\~\=.asy$')
        let lines = readfile(fp)
        let mod = getftime(fp)

        if has_key(s:cache, name) && s:cache[name].mod == mod
            continue
        endif

        for type in ['PROC', 'LDTYPE', 'QUEUE', 'ORDER', 'ATT', 'VAR',
                    \ 'SUBRTN', 'RSRC']
            let entities = extend(entities, s:FilterEntity(lines, type))
        endfor

        if len(entities) > 0
            call sort(entities)
            let system = {}
            let system.mod = mod
            let system.name = name
            let system.entities = entities
            let s:cache[name] = system
        endif
    endfor

endfunction

function! omni#AutoMod#Main(findstart, base)

    if a:findstart
        return s:FindStartPosition()
    endif

    return omni#AutoMod#Complete(a:base)

endfunction

function! omni#AutoMod#Complete(base)

    if !has_key(s:cache, s:main)
        call omni#AutoMod#Cache()
    endif

    let lines = map(copy(s:cache[s:main].entities), 'v:val.word')
    let lines = filter(lines, 'v:val =~ "^'.a:base.'"')

    return lines

endfunction

function! s:FindStartPosition()
    let line = getline('.')
    let start = col('.') - 1

    let lastword = -1
    while start > 0
        if line[start - 1] =~ '\w'
            let start -= 1
        elseif line[start - 1] =~ '\.'
            if lastword == -1
                let lastword = start
            endif
            let start -= 1
        elseif line[start - 1] =~ ':'
            if lastword == -1
                let lastword = start
            endif
            let start -= 1
        else
            break
        endif
    endwhile

    if lastword == -1
        let lastword = start
    endif

    return lastword
endfunction

function! s:FilterEntity(lines, prefix)
    let retlist = []
    let kind = tolower(matchstr(a:prefix, '^\w'))
    let lines = filter(copy(a:lines), 'v:val =~ "^'.a:prefix.' name"')
    for line in lines
        let item = {}
        let item.word = matchstr(line, '^'.a:prefix.' name \zs\S\+\ze')
        let item.kind = kind
        call add(retlist, item)
    endfor
    return retlist
endfunction
