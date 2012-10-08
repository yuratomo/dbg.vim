
let s:engine = dbg#initEngine('pdb')

function! dbg#engines#pdb#init()
  return {
    \ 'prompt'      : '(Pdb) ',
    \ 'engine'      : s:engine
    \ }
endfunction

function! s:engine.open(target)
  let params = []
  call extend(params, ['-m', 'pdb'])
  call extend(params, a:params)
  call dbg#popen(g:dbg#command_python, params, [
  \ '-----------------------------------------------',
  \ '         Welcome to dbg.vim (PDB MODE)',
  \ '-----------------------------------------------',
  \ '',
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

function! s:engine.breakpoint(...)
  if len(a:000) >= 2
    let path = a:000[0]
    let line = a:000[1]
  else
    let path = expand('%:p')
    let line = line('.')
  endif
  call dbg#focusIn()
  call dbg#write(1, printf('break %s:%d', path, line))
  call dbg#read(1)
  call cursor('$',0)
  redraw
  call dbg#focusBack()
endfunction

function! s:engine.locals()
  call dbg#output('not support local variable info')
endfunction

function! s:engine.threads()
  call dbg#output('not support threads info')
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

function! s:engine.close()
  call dbg#focusIn()
  call dbg#write(1, 'quit')
  call dbg#read(1)
  call dbg#focusBack()
endfunction

