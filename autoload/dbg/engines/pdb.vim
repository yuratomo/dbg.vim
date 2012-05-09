
let s:engine = dbg#initEngine('pdb')

function! dbg#engines#pdb#init()
  call s:engine.prepare()
endfunction

function! s:engine.prepare()
  let t:dbg = {
    \ 'prompt'      : '(Pdb) ',
    \ 'verbose'     : 0,
    \ 'lnum'        : 1,
    \ 'line'        : '',
    \ 'target_name' : '',
    \ 'lastCommand' : '',
    \ 'sign_id'     : 1,
    \ 'engine'      : s:engine,
    \ 'pipe'        : {},
    \ }
endfunction

function! s:engine.open(target)
  if exists('t:dbg.pipe')
    unlet t:dbg.pipe
  endif

  call dbg#focusIn()

  let t:dbg.target_name = a:target

  let t:dbg.pipe = vimproc#popen3([g:dbg#command_python, '-m', 'pdb', a:target])
  call dbg#read(1)
  if t:dbg.pipe.stdout.eof
    let lines = split(t:dbg.line, "\n")
    call setline(t:dbg.lnum, lines)
    let t:dbg.line = ''
    call cursor('$',0)
    return
  endif
  "call t:dbg.pipe.set_winsize(winwidth(0), winheight(0))

  call s:comment('-----------------------------------------------')
  call s:comment('         Welcom to dbg.vim (PDB MODE)')
  call s:comment('')
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
  call dbg#write(0, 'cont')
  call dbg#read(0)
  call s:engine.sync()
endfunction

function! s:engine.stepout()
  call dbg#write(0, 'return')
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
  call dbg#write(1, printf('p %s', word))
  call dbg#read(1)
  call cursor('$',0)
  redraw
  call dbg#focusBack()
endfunction

function! s:engine.breakpoint()
  let path = expand('%:p:r')
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
  call s:comment('not support local variable info')
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
  for item in t:dbg.last_readed_list
    if match(item, '^> .*(\d\+).*(\d\+)$') == 0
      break
      let mid   = match(item, '(\d\+).*(\d\+)$')
      let start = 2
      let end   = stridx(item, ')', mid) - 1
      let path  = item[start : mid-1]
      let num   = item[mid+1 : end  ]
      if filereadable(path)
        call dbg#openSource(path, num)
      else
        echoerr path . ' is not readable.'
      endif
    endif
  endfor
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

