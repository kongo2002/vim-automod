" Description:  omni completion for AutoMod
" Maintainer:   Gregor Uhlenheuer
" Last Change:  Sun 31 Oct 2010 12:27:22 PM CET

if v:version < 700 || &cp
    echohl WarningMsg
    echomsg "omni#automod.vim: Please install vim 7.0 or higher"
    echohl None
    finish
endif

if exists('g:autoloaded_automod')
    finish
endif
let g:autoloaded_automod = 1

let s:cpo_save = &cpo
set cpo&vim

function! omni#automod#Init()
    if !exists('g:automod_omni_disable') || g:automod_omni_disable == 0
        set omnifunc=omni#automod#Main
        call omni#automod#Settings()
        call omni#automod#Cache()
        inoremap <buffer> <expr> . omni#automod#DoComplete('.')
        inoremap <buffer> <expr> : omni#automod#DoComplete(':')
    endif
endfunction

function! omni#automod#Settings()

    if !exists('s:cache')
        let s:cache = {}
    endif

    if !exists('g:automod_omni_max_systems')
        let g:automod_omni_max_systems = 20
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

function! s:FilterLine(line)
    for ent in keys(s:entity_types)
        if a:line =~# '^'.ent
            return 1
        endif
    endfor
    return 0
endfunction

function! omni#automod#Cache()

    let asys = s:GetModel()

    if asys == []
        let s:no_complete = 1
        return
    endif

    " read files
    for fp in asys
        let entities = []
        let name = matchstr(fp, '\w\+\ze\~\=.asy$')
        let lines = filter(readfile(fp), 's:FilterLine(v:val)')
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

        if exists('g:automod_omni_debug') && g:automod_omni_debug
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

function! omni#automod#Main(findstart, base)

    if a:findstart
        let s:scope = omni#automod#GetScope()
        let s:type = omni#automod#GetType()
        return s:FindStartPosition()
    endif

    if s:scope != ''
        return omni#automod#Complete(a:base, s:type, s:scope)
    endif

    return omni#automod#Complete(a:base, s:type)

endfunction

function! omni#automod#DoComplete(key)
    let word = s:GetPreceding()

    if word != '' && word !~ '^\d\+$'
        set completeopt-=menu
        set completeopt+=menuone
        return a:key . "\<C-X>\<C-O>\<C-P>"
    endif

    return a:key
endfunction

function! omni#automod#GetScope()
    let scope = s:GetPreceding()

    if match(scope, '[\.:]') != -1
        return matchstr(scope, '\w\+\ze[\.:]')
    endif
    return ''
endfunction

function! omni#automod#GetType()
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
    endif

    return ''
endfunction

function! omni#automod#Complete(base, type, ...)

    if exists('s:no_complete') && s:no_complete
        return []
    endif

    if !exists('s:main')
        let mainmodel = expand('%:p:h')
        let s:main = matchstr(mainmodel, '[^/\\]\+\ze\.\w\{3}[/\\]\=$')

        if exists('g:automod_omni_debug') && g:automod_omni_debug
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
                    call add(words, { "word": sys, "menu": "System" })
                endif
            endfor
        endif

        " filter types if given
        if a:type != ''
            for t in split(a:type, '\zs')
                for entity in s:cache[system].entities
                    if has_key(entity, 'kind')
                        if entity.kind == t
                            call add(words, entity)
                        endif
                    endif
                endfor
            endfor
        else
            let words = copy(s:cache[system].entities)
        endif

        let lines = filter(words, 'v:val.word =~ "^'.a:base.'"')
    endif

    return lines

endfunction

function! s:HasDuplicates(list)
    let tmplist = []
    for item in a:list
        if index(tmplist, item) == -1
            call add(tmplist, item)
        else
            return 1
        endif
    endfor
    return 0
endfunction

function! s:Uniquify(list)
    let retlist = []
    for item in a:list
        if index(retlist, item) == -1
            call add(retlist, item)
        endif
    endfor
    return retlist
endfunction

function! s:CheckMultipleVersions(dir)
    " get all directories in the current dir
    let dirs = split(globpath(a:dir, '*'), "\n")
    call filter(dirs, 'isdirectory(v:val) != 0')

    " strip '.dir' and '.arc' endings
    call map(dirs, 'substitute(v:val, "\\.\\%(dir\\|arc\\).\\=$", "", "")')

    " remove duplicates
    let dirs = s:Uniquify(dirs)

    " strip numeric directory endings
    call map(dirs, 'substitute(v:val, "\\d\\+$", "", "")')

    return s:HasDuplicates(dirs)
endfunction

function! s:GetModel()

    " get start directory
    let max = 4
    let depth = ':p:h'
    let base = expand('%'.depth)
    while match(base, '\.\%(arc\|dir\)$') != -1
        let max -= 1
        let depth .= ':h'
        let base = expand('%'.depth)
        if !max || base == expand('$HOME') | break | endif

        " step one directory backwards if inside a 'multiple version'
        " directory like 'model05, model06, model07 ...'
        if s:CheckMultipleVersions(base)
            let base = substitute(expand('%'.depth[:-2]),
                        \ '\%(arc\|dir\).\=$', '', '')
            let base = base . 'arc,' . base . 'dir'
            break
        endif
    endwhile

    if exists('g:automod_omni_debug') && g:automod_omni_debug
        echom '*** Base directory: ' . base
    endif

    " get asy file locations
    let models = []
    if base != expand('$HOME')
        let models = split(globpath(base, "**/model.amo"), "\n")
    endif

    if models == []
        call s:Warn('No model.amo found')
        return []
    endif

    " limit systems to be parsed
    if g:automod_omni_max_systems > 0
        if len(models) > g:automod_omni_max_systems
            call s:Warn('More than '.g:automod_omni_max_systems.
                        \ ' (sub)systems found')
            return []
        endif
    endif

    let asys = []

    for model in models
        let model = substitute(model, '.*\zsmodel.amo$', '', '')
        let asys += split(glob(model . "*.asy"), "\n")
    endfor

    let models = []

    " filter static systems
    for fp in asys
        let lines = readfile(fp, '', 1)
        if lines[0] !~? '^SYSTYPE Static'
            call add(models, fp)
        endif
    endfor

    return models

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
        let item['word'] = matchstr(line, '^'.a:prefix.' name \zs\S\+\ze')
        let item['kind'] = kind
        let item['menu'] = s:entity_types[a:prefix]
        call add(retlist, item)
    endfor
    return retlist
endfunction

function! s:Warn(msg)
    echohl WarningMsg
    echom 'omni#automod.vim: ' . a:msg
    echohl None
endfunction

let &cpo = s:cpo_save
