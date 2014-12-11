
let s:engine = dbg#initEngine('jdb')

function! dbg#engines#jdb#init()
  return {
    \ 'prompt'      : '> ',
    \ 'engine'      : s:engine,
    \ '_base_dir'   : expand('%:p:h')
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

  if len(a:params) > 0
    let stop_comment = '> stop in ' . a:params[0] . '.main'
  else
    let stop_comment = '> stop in XXX.main'
  endif

  call dbg#popen(g:dbg#command_jdb, a:params, [
  \ '-----------------------------------------------',
  \ '         Welcome to dbg.vim (JDB MODE)',
  \ '!! You will need to set the first breakpoint',
  \ 'and run the target program.',
  \ '',
  \ 'for example:',
  \ stop_comment,
  \ '> run',
  \ '-----------------------------------------------',
  \ '> '
  \ ])

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
  call dbg#write(0, 'cont')
  call dbg#read(0)
  call s:engine.sync()
endfunction

function! s:engine.stepout()
  call dbg#write(0, 'step up')
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
  let start = len(t:dbg._base_dir)
  if len(path) <= start
    echoerr "illegal source code???"
    return
  endif
  let class = substitute(path[ start+1 : ], '\', '/', 'g')
  call dbg#focusIn()
  call dbg#write(1, printf('stop at %s:%d', class, line))
  call dbg#read(1)
  call cursor('$',0)
  redraw
  call dbg#focusBack()
endfunction

function! s:engine.locals()
  call dbg#focusIn()
  call dbg#write(1, 'locals')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

function! s:engine.threads()
  call dbg#focusIn()
  call dbg#write(1, 'threads')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

function! s:engine.callstack()
  call dbg#focusIn()
  call dbg#write(1, 'wherei')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

function! s:engine.sync()
  call dbg#write(0, 'where')
  let lines = dbg#read(0)
  if len(lines) >= 1
    " line to parse
    " [1] test.HelloWorld.main (HelloWorld.java:6)
    let line = lines[0]
    if match(line, '\[\d\+\].*\(.*:\d\+\)') != -1
      let startPackage = stridx(line, ']') + 2
      let endPackage = stridx(line, '(') - 2
      let startClass = stridx(line, '(') + 1
      let midClass   = stridx(line, ':')
      let endClass   = stridx(line, ')') - 1
      let nameExtension  = line[startClass : midClass-1]
      let name = nameExtension[0:stridx(nameExtension, '.')-1]
      let packageClassMethod = line[startPackage : endPackage]
      let package = packageClassMethod[0:stridx(packageClassMethod, name)-2]
      let num   = line[midClass+1 : endClass ]
      let path  = t:dbg._base_dir . '/' . substitute(package, "\\.", "/", "g") . '/' . nameExtension
      if filereadable(path)
        call dbg#openSource(path, num)
      else
        echoerr path . ' is not readable.'
      endif
    endif
  endif
endfunction

function! s:engine.post_write(cmd)
  if a:cmd == 'run'
    let t:dbg.prompt = '\a\+\[\d\+\] '
  endif
  return 0
endfunction

function! s:engine.close()
  call dbg#focusIn()
  call dbg#write(1, 'quit')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

