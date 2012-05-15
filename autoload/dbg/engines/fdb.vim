
let s:engine = dbg#initEngine('fdb')

function! dbg#engines#fdb#init()
  return {
    \ 'prompt'      : '(fdb) ',
    \ 'engine'      : s:engine,
    \ '_base_dir'   : expand('%:p:h')
    \ }
endfunction

function! s:engine.open(params)
  "resolv base directory
  let base_dir = input('base directory:', expand('%:p:h'), 'dir')
  let t:dbg._base_dir = base_dir
  if !isdirectory(base_dir)
    exe 'echoerr "' . base_dir . ' is not a directory"'
    return
  endif
  exe 'cd ' . base_dir

  call dbg#popen(g:dbg#command_fdb, a:params)

  call s:comment('-----------------------------------------------')
  call s:comment('         Welcom to dbg.vim (FDB MODE)')
  call s:comment('base directory is ' .  t:dbg._base_dir)
  call s:comment('')
  call s:comment('!! You will need to set the first breakpoint')
  call s:comment('and run the target program.')
  call s:comment('')
  call s:comment('for example:')
  call s:comment('> break main')
  call s:comment('> continue')
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
  call dbg#write(1, printf('print %s', word))
  call dbg#read(1)
  call cursor('$',0)
  redraw
  call dbg#focusBack()
endfunction

function! s:engine.breakpoint()
  let path = expand('%:p')
  let line = line('.')
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
  call dbg#write(1, 'info locals')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

function! s:engine.threads()
  call s:comment('not support threads info')
endfunction

function! s:engine.callstack()
  call dbg#focusIn()
  call dbg#write(1, 'bt')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

function! s:engine.sync()
  call dbg#write(0, 'cf')
  let lines = dbg#read(0)
  if len(lines) >= 1
    let start = match(lines[0], '^.*#\d\+:\d\+')
    if start != -1
      let part = split(lines[0], '[#:]')
      let path = t:dbg._base_dir . '/' . part[0]
      let num  = part[2]
      if filereadable(path)
        call dbg#openSource(path, num)
      else
        echoerr path . ' is not readable.'
      endif
    endif
  endif
endfunction

"function! s:engine.post_write(cmd)
"endfunction

function! s:engine.close()
  call dbg#focusIn()
  call dbg#write(1, 'quit')
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

