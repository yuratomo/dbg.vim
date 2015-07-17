
let s:engine = dbg#initEngine('perl')

function! dbg#engines#perl#init()
  return {
    \ 'prompt'      : '  DB<\d\+> ',
    \ 'filter'      : ["\e\[[0-9;]*[mK]",["^  ", ">>"]],
    \ 'engine'      : s:engine,
    \ 'cmdOptions'  : '-d'
    \ }
endfunction

function! s:engine.open(params)
  "resolve base directory
  let base_dir = input('base directory:', expand('%:p:h'), 'dir')
  let t:dbg._base_dir = base_dir
  if !isdirectory(base_dir)
    exe 'echoerr "' . base_dir . ' is not a directory"'
    return
  endif
  exe 'cd ' . base_dir

  call dbg#popen(g:dbg#command_perl, a:params, [
  \ '-----------------------------------------------',
  \ '         Welcome to dbg.vim (PERL MODE)',
  \ '-----------------------------------------------',
  \ ])
  call s:engine.sync()
  call dbg#insert()
endfunction

function! s:engine.run()
  call dbg#write(0, 'run')
  call dbg#read(0)
  call s:engine.sync()
endfunction

function! s:engine.next()
  call dbg#write(0, 'next')
  call dbg#read(0)
  call s:engine.sync()
endfunction

function! s:engine.step()
  call dbg#write(0, 'step')
  call dbg#read(0)
  call s:engine.sync()
endfunction

function! s:engine.continue()
  call dbg#write(0, 'continue')
  call dbg#read(0)
  call s:engine.sync()
endfunction

function! s:engine.stepout()
  call dbg#write(0, 'finish')
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
  call dbg#write(0, printf('print %s', word))
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
  call dbg#write(0, printf('break %s:%d', path, line))
  call dbg#read(1)
  call cursor('$',0)
  redraw
  call dbg#focusBack()
endfunction

function! s:engine.locals()
  call dbg#focusIn()
  call dbg#write(0, 'info locals')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

function! s:engine.threads()
  call dbg#focusIn()
  call dbg#write(0, 'info threads')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

function! s:engine.callstack()
  call dbg#focusIn()
  call dbg#write(0, 'backtrace')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

function! s:engine.sync()
  let path = ''
  call dbg#write(0, '.')
  let lines = dbg#read(0)
  for line in lines
    if line =~ '\(.*\)::(\(.*\):\(\d\+\)):'
      exec substitute(line,
          \ '\(.*\)::(\(.*\):\(\d\+\)):',
          \ 'let func = "\1" | let path = "\2" | let line = "\3"', '')
      break
    endif
  endfor
  if path == '' || !filereadable(path)
    return
  endif

  call dbg#openSource(path, line)
endfunction

function! s:engine.close()
  call dbg#focusIn()
  call dbg#write(0, 'quit')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

