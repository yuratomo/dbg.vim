
let s:engine = dbg#initEngine('mdbg')

function! dbg#engines#mdbg#init()
  return {
    \ 'prompt'      : 'mdbg> ',
    \ 'needArgs'      : 0,
    \ 'engine'      : s:engine
    \ }
endfunction

function! s:engine.open(params)
  call dbg#popen(g:dbg#command_mdbg, a:params, [
  \ '-----------------------------------------------',
  \ '         Welcome to dbg.vim (MDBG MODE)',
  \ '!! You will need to run the target program.',
  \ 'for example:',
  \ '',
  \ '> run',
  \ '-----------------------------------------------',
  \ 'mdbg> '
  \ ])
  "call s:engine.sync()
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
  call dbg#write(0, 'go')
  call dbg#read(0)
  call s:engine.sync()
endfunction

function! s:engine.stepout()
  call dbg#write(0, 'out')
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
  call dbg#write(1, printf('print %s', word))
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
  call dbg#write(1, printf('break %s:%d',
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
  call dbg#write(1, 'print')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

function! s:engine.threads()
  call dbg#focusIn()
  call dbg#write(1, 'thread')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

function! s:engine.callstack()
  call dbg#focusIn()
  call dbg#write(1, 'where')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

function! s:engine.sync()
  let path = ''
  call dbg#write(0, 'where')
  let lines = dbg#read(0)
  for line in lines
    if line[0] == '*'
      let s = stridx(line, '(')
      let e = strridx(line, ':')
      if s != -1 && e != -1
        let path = line[ s+1 : e-1 ]
        let num = line[ e+1 : -2 ]
        break
      endif
    endif
  endfor
  if path != ''
    call dbg#openSource(path, num)
  endif
endfunction

"function! s:engine.post_write(cmd)
"endfunction

function! s:engine.close()
  call dbg#focusIn()
  call dbg#write(1, 'exit')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

