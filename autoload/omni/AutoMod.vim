" Description:  omni completion for AutoMod
" Maintainer:   Gregor Uhlenheuer
" Last Change:  Di 02 Mär 2010 22:48:17 CET

if v:version < 700
    echohl WarningMsg
    echomsg "omni#AutoMod.vim: Please install vim 7.0 or higher"
    echohl None
    finish
endif

function! omni#AutoMod#Init()
    set omnifunc=omni#AutoMod#Main
    call omni#AutoMod#Settings()
    call omni#AutoMod#Cache()
    inoremap <buffer> <expr> . omni#AutoMod#DoComplete('.')
    inoremap <buffer> <expr> : omni#AutoMod#DoComplete(':')
endfunction

function! omni#AutoMod#Settings()

    if !exists('s:cache')
        let s:cache = {}
    endif

    if !exists('g:AutoMod_omni_max_systems')
        let g:AutoMod_omni_max_systems = 10
    endif

    if !exists('s:entity_types')
        let s:entity_types = {}
        let s:entity_types['PROC'] = 'Procedure'
        let s:entity_types['LDTYPE'] = 'LoadType'
        let s:entity_types['QUEUE'] = 'Queue'
        let s:entity_types['ORDER'] = 'Orderlist'
        let s:entity_types['ATT'] = 'Attribute'
        let s:entity_types['VAR'] = 'Variable'
        let s:entity_types['SUBRTN'] = 'Subroutine'
        let s:entity_types['RSRC'] = 'Resource'
        let s:entity_types['CONVSTATION'] = 'Control Point'
        let s:entity_types['CPOINT'] = 'Control Point'
        let s:entity_types['FUNC'] = 'Function'
        let s:entity_types['PDSTAND'] = 'Control Point'
    endif

endfunction

function! omni#AutoMod#Cache()

    let asys = s:GetModel()

    if asys == []
        let s:no_complete = 1
        return
    endif

    " read files
    for fp in asys
        let entities = []
        let name = matchstr(fp, '\w\+\ze\~\=.asy$')
        let lines = readfile(fp)
        let mod = getftime(fp)

        if has_key(s:cache, name) && s:cache[name].mod == mod
            continue
        endif

        for type in keys(s:entity_types)
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

        if exists('g:AutoMod_omni_debug') && g:AutoMod_omni_debug
            for key in keys(s:cache)
                echom '*** ' . s:cache[key].name . ' ***'
                echom '*** ' . s:cache[key].mod . ' ***'
                for entity in s:cache[key].entities
                    echom entity.word
                endfor
            endfor
        endif
    endfor

endfunction

function! omni#AutoMod#Main(findstart, base)

    if a:findstart
        let s:scope = omni#AutoMod#GetScope()
        let s:type = omni#AutoMod#GetType()
        return s:FindStartPosition()
    endif

    if s:scope != ''
        return omni#AutoMod#Complete(a:base, s:type, s:scope)
    endif

    return omni#AutoMod#Complete(a:base, s:type)

endfunction

function! omni#AutoMod#DoComplete(key)
    let word = s:GetPreceding()

    if word != '' && word !~ '^\d\+$'
        set completeopt-=menu
        set completeopt+=menuone
        return a:key . "\<C-X>\<C-O>\<C-P>"
    endif

    return a:key
endfunction

function! omni#AutoMod#GetScope()
    let scope = s:GetPreceding()

    if match(scope, '[\.:]') != -1
        let scope = matchstr(scope, '\w\+\ze[\.:]')
    else
        return ''
    endif

    return scope
endfunction

function! omni#AutoMod#GetType()
    let line = strpart(getline('.'), 0, col('.') - 1)

    if match(line, '\S\+\s\+\S*$')
        let type = matchstr(line, '\S\+\ze\s\+\S*$')

        " a = attribute
        " c = conveyor/pm station
        " f = function
        " l = load type
        " o = orderlist
        " p = procedure
        " q = queue
        " r = resource
        " s = subroutine
        " v = variable

        if type =~ 'set'
            return 'av'
        elseif type =~ 'to'
            return 'acflopqrv'
        elseif type =~ 'call'
            return 'afsv'
        elseif type =~ 'if'
            return 'afopqrv'
        elseif type =~ 'while'
            return 'afopqrv'
    endif

    return ''
endfunction

function! omni#AutoMod#Complete(base, type, ...)

    if exists('s:no_complete') && s:no_complete
        return []
    endif

    if !exists('s:main')
        let mainmodel = expand('%:p:h')
        let s:main = matchstr(mainmodel, '[^/\\]\+\ze\.\w\{3}[/\\]\=$')

        if exists('g:AutoMod_omni_debug') && g:AutoMod_omni_debug
            echom '*** Mainmodel: ' . s:main . ' ***'
        endif
    endif

    let system = s:main

    if a:0 && a:1 != ''
        let system = a:1
    endif

    let lines = []

    if has_key(s:cache, system)
        let words = []

        " add submodels if working in the main model
        if system == s:main
            for sys in keys(s:cache)
                if sys != s:main
                    call add(words, sys)
                endif
            endfor
        endif

        " filter types if given
        if a:type != ''
            let i = 0
            while i < strlen(a:type)
                for entity in s:cache[system].entities
                    if entity.kind == strpart(a:type, i, 1)
                        call add(words, entity.word)
                    endif
                endfor
                let i += 1
            endwhile
        else
            let words = map(copy(s:cache[system].entities), 'v:val.word')
        endif

        let lines = filter(words, 'v:val =~ "^'.a:base.'"')
    endif

    return lines

endfunction

function! s:GetModel()

    " get start directory
    let max = 4
    let depth = ':p:h'
    let base = expand('%'.depth)
    while match(base, '\.\%(arc\)\|\%(dir\)$') != -1
        let max -= 1
        let depth .= ':h'
        let base = expand('%'.depth)
        if !max || base == expand('$HOME') | break | endif
    endwhile

    " get asy file locations
    let models = []
    if base != expand('$HOME')
        let models = split(globpath(base, "**/model.amo"), "\n")
    endif

    if models == []
        call s:Warn('No model.amo found')
        return []
    endif

    " limit systems to 10 by default
    if g:AutoMod_omni_max_systems > 0
        if len(models) > g:AutoMod_omni_max_systems
            call s:Warn('More than '.g:AutoMod_omni_max_systems.
                        \ ' (sub)systems found')
            return []
        endif
    endif

    let asys = []

    for model in models
        let model = substitute(model, '.*\zsmodel.amo$', '', '')
        let asys += split(glob(model . "*.asy"), "\n")
    endfor

    return asys

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

function! s:GetPreceding()
    let line = getline('.')
    let start = col('.') - 1
    let pos = start
    let scope = ''

    while pos > 0
        if line[pos - 1] =~ '\S'
            let pos -= 1
        else
            break
        endif
    endwhile

    let scope = strpart(line, pos, start-pos)

    return scope

endfunction

function! s:FilterEntity(lines, prefix)
    let retlist = []
    let kind = tolower(matchstr(s:entity_types[a:prefix], '^\w'))
    let lines = filter(copy(a:lines), 'v:val =~ "^'.a:prefix.' name"')
    for line in lines
        let item = {}
        let item.word = matchstr(line, '^'.a:prefix.' name \zs\S\+\ze')
        let item.kind = kind
        let item.menu = s:entity_types[a:prefix]
        call add(retlist, item)
    endfor
    return retlist
endfunction

function! s:Warn(msg)
    echohl WarningMsg
    echom 'omni#AutoMod.vim: ' . a:msg
    echohl None
endfunction
