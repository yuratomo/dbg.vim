
let s:engine = dbg#initEngine('gdb')

function! dbg#engines#gdb#init()
  call s:engine.prepare()
endfunction

function! s:engine.prepare()
  let t:dbg = {
    \ 'prompt'      : '(gdb) ',
    \ 'verbose'     : 0,
    \ 'lnum'        : 1,
    \ 'line'        : '',
    \ 'target_name' : '',
    \ 'lastCommand' : '',
    \ 'sign_id'     : 1,
    \ 'engine'      : s:engine,
    \ 'pipe'        : {},
    \ '_base_dir'   : expand('%:p:h')
    \ }
endfunction

function! s:engine.open(target)
  if exists('t:dbg.pipe')
    unlet t:dbg.pipe
  endif

  call dbg#focusIn()

  let t:dbg.target_name = a:target

  let t:dbg.pipe = vimproc#popen3([g:dbg#command_gdb, a:target])
  call dbg#read(1)
  if t:dbg.pipe.stdout.eof
    let lines = split(t:dbg.line, "\n")
    call setline(t:dbg.lnum, lines)
    let t:dbg.line = ''
    call cursor('$',0)
    return
  endif

  "resolv base directory
  call dbg#write(0, 'info source')
  let lines = dbg#read(0)
  for line in lines
    let start = matchend(line, 'Compilation directory is ')
    if start != -1
      let t:dbg._base_dir = line[ start : ]
    endif
  endfor

  call s:comment('-----------------------------------------------')
  call s:comment('         Welcom to dbg.vim (GDB MODE)')
  call s:comment('base directory is ' .  t:dbg._base_dir)
  call s:comment('')
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
  call dbg#focusIn()
  call dbg#write(1, 'info threads')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

function! s:engine.callstack()
  call dbg#focusIn()
  call dbg#write(1, 'backtrace')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

function! s:engine.sync()
  call dbg#write(0, 'where')
  let lines = dbg#read(0)
  if len(lines) >= 1
    let start = match(lines[0], ' at .*:\d\+')
    if start != -1
      let start = start + 4
      let mid   = strridx(lines[0], ':')
      let name  = lines[0][start : mid-1]
      let num   = lines[0][mid+1 :      ]
      let path  = t:dbg._base_dir . '/' . name
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
  call dbg#write(0, 'echo ' . a:msg)
  call dbg#read(1)
endfunction

