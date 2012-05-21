
let s:engine = dbg#initEngine('cdb')

function! dbg#engines#cdb#init()
  return {
    \ 'prompt'      : '\d:\d\{3}\(:\w\+\)\{0,1}> ',
    \ 'engine'      : s:engine
    \ }
endfunction

function! s:engine.open(params)
  call dbg#popen(g:dbg#command_cdb, a:params)

  call s:resolveModuleName()

  call dbg#write(t:dbg.verbose, '.lines -e')
  call dbg#read(t:dbg.verbose)
  call dbg#write(t:dbg.verbose, 'l+s')
  call dbg#read(t:dbg.verbose)
  call dbg#write(t:dbg.verbose, 'l+t')
  call dbg#read(t:dbg.verbose)

  " estimate main function
  call dbg#write(0, 'x ' . t:dbg.target_name . '!*main*')
  let lines = dbg#read(0)
  let estimate_main = ''
  for line in lines
    let start = match(line, '!.*ain (')
    if start != -1
      let end = stridx(line, ' (')
      let estimate_main = line[ start+1 : end-1 ]
    endif
  endfor

  call s:comment('-----------------------------------------------')
  call s:comment('         Welcom to dbg.vim (CDB MODE)')
  call s:comment('')
  if estimate_main == ''
    call s:comment('!! You will need to set the first breakpoint')
    call s:comment('and run the target program.')
    call s:comment('')
    call s:comment('for example:')
    call s:comment('> bp ' . estimate_main)
  else
    call dbg#write(0, 'bp ' . estimate_main)
    call dbg#read(0)
    call s:comment('!! dbg.vim set the break point at "' . t:dbg.target_name . '!' . estimate_main . '"')
    call s:comment('You will need to run the target program.')
    call s:comment('')
    call s:comment('for example:')
  endif
  call s:comment('> g')
  call s:comment('-----------------------------------------------')
  call dbg#insert()
endfunction

function! s:engine.run()
  call dbg#write(0, 'g')
  call dbg#read(0)
  call s:engine.sync()
endfunction

function! s:engine.next()
  call dbg#write(0, 'p')
  call dbg#read(0)
  call s:engine.sync()
endfunction

function! s:engine.step()
  call dbg#write(0, 't')
  call dbg#read(0)
  call s:engine.sync()
endfunction

function! s:engine.continue()
  call dbg#write(0, 'g')
  call dbg#read(0)
  call s:engine.sync()
endfunction

function! s:engine.stepout()
" call dbg#write(0, 'k')
" let lines = dbg#read(0)
" for line in lines
"   if match(line, '\x\{8} \x\{8}') == 0 || match(line, '\x\{16} \x\{16}') == 0
"     let parts = split(line, ' ')
"     if len(parts) > 1
"       call dbg#write(0, 'g '. parts[1])
"       call dbg#read(0)
"       call s:engine.sync()
"       break
"     endif
"   endif
" endfor
  call dbg#write(0, 'gu')
  call dbg#read(0)
  call s:engine.sync()
endfunction

function! s:engine.print(...)
  if len(a:000) > 0
    let word = a:1
  endif
  if word == ''
    let word = expand("<cword>")
  endif
  call dbg#focusIn()
  call dbg#write(1, printf('dt %s', word))
  call dbg#read(1)
  call cursor('$',0)
  redraw
  call dbg#focusBack()
endfunction

function! s:engine.breakpoint(...)
  if len(a:000) >= 2
    let path = a:000[0]
    let line = a:000[1]
  else
    let path = expand('%:p')
    let line = line('.')
  endif
  call dbg#focusIn()
  call dbg#write(1, printf('bp `%s!%s:%d`',
    \ t:dbg.target_name,
    \ path,
    \ line
    \ ))
  call dbg#read(1)
  call cursor('$',0)
  redraw
  call dbg#focusBack()
endfunction

function! s:engine.locals()
  call dbg#focusIn()
  call dbg#write(1, 'dv')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

function! s:engine.threads()
  call dbg#focusIn()
  call dbg#write(1, '~')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

function! s:engine.callstack()
  call dbg#focusIn()
  call dbg#write(1, 'kb')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

function! s:engine.sync()
  call dbg#write(0, 'ln')
  let lines = dbg#read(0)
  let exists = 0
  for line in lines
    if line =~ ".*([0-9]*)"
      let exists = 1
      break
    endif
  endfor

  if exists == 1
    let top = match(line, '\S')
    let sep = strridx(line, '(')
    let end = strridx(line, ')')
    if top != -1 && sep != -1 && end != -1
      let path = line[ top : sep-1 ]
      let num  = line[ sep+1 : end-1]
      if filereadable(path)
        call dbg#openSource(path, num)
      else
        call s:comment(path)
      endif
    endif
  endif
endfunction

function! s:engine.close()
  call dbg#focusIn()
  call dbg#write(1, 'q')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

function! s:engine.post_write(cmd)
  if exists('t:dbg_processing_now')
    return
  endif
  let t:dbg_processing_now = 0

  if a:cmd =~ '.restart'
    if exists('t:dbg.breakpoints')
      for bp in t:dbg.breakpoints
        call dbg#write(1, printf('bp `%s!%s:%d`',
          \ t:dbg.target_name,
          \ bp.path,
          \ bp.line
          \ ))
        call dbg#read(1)
        call cursor('$',0)
        redraw
      endfor
    endif
  endif

  unlet t:dbg_processing_now
endfunction

" internal functions

function! s:comment(msg)
  call dbg#write(1, '*' . a:msg)
  call dbg#read(1)
endfunction

function! s:resolveModuleName()
  call dbg#write(0, 'ld *')
  let lines = dbg#read(0)
  call dbg#write(0, 'lm')
  let lines = dbg#read(0)
  for line in lines
    let top = matchend(line, '\x\{8}\(`\x\{8}\)\{0,1} \x\{8}\(`\x\{8}\)\{0,1}\s\+')
    let end = match(line, '\s\+(.*)')
    if top != -1 && end != -1 && stridx(line, 'pdb symbols)') > 0
      let t:dbg.target_name = line[ top : end-1 ]
      break
    endif
  endfor
endfunction

