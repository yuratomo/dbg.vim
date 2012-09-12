
let s:engine = dbg#initEngine('gdb')

function! dbg#engines#gdb#init()
  return {
    \ 'prompt'      : '(gdb) ',
    \ 'engine'      : s:engine
    \ }
endfunction

function! s:engine.open(params)
  call dbg#popen(g:dbg#command_gdb, a:params)

  call s:comment('-----------------------------------------------')
  call s:comment('         Welcome to dbg.vim (GDB MODE)')
  call s:comment('!! You will need to set the first breakpoint')
  call s:comment('and run the target program.')
  call s:comment('')
  call s:comment('for example:')
  call s:comment('> break main')
  call s:comment('> run')
  call s:comment('-----------------------------------------------')
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
  call dbg#write(0, printf('break %s:%d',
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
  call dbg#write(0, 'info source')
  let lines = dbg#read(0)
  for line in lines
    let start = matchend(line, 'Located in ')
    if start != -1
      let path = line[ start : ]
      break
    endif
  endfor
  if path == '' || !filereadable(path)
    return
  endif

  call dbg#write(0, 'where')
  let lines = dbg#read(0)
  if len(lines) >= 1
    let start = match(lines[0], ' at .*:\d\+')
    if start != -1
      let mid   = strridx(lines[0], ':')
      let num   = lines[0][mid+1 :      ]
      call dbg#openSource(path, num)
    endif
  endif
endfunction

"function! s:engine.post_write(cmd)
"endfunction

function! s:engine.close()
  call dbg#focusIn()
  call dbg#write(0, 'quit')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

" internal functions

function! s:comment(msg)
  call dbg#write(1, '*' . a:msg)
  call dbg#read(0)
  call dbg#write(0, '')
  call dbg#read(1)
endfunction

