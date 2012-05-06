
let s:engine = dbg#initEngine('cdb')

function! dbg#engines#cdb#init()
  call s:engine.prepare()
endfunction

function! s:engine.prepare()
  let t:dbg = {
    \ 'prompt'      : '\d:\d\{3}> ',
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

  let start = strridx(a:target, '\')
  let end = strridx(a:target, '.')
  let t:dbg.target_name = strpart(a:target, start+1, end-start-1)

  let t:dbg.pipe = vimproc#popen3([g:dbg#command_cdb, a:target])
  call dbg#read(1)
  if t:dbg.pipe.stdout.eof
    let lines = split(t:dbg.line, "\n")
    call setline(t:dbg.lnum, lines)
    let t:dbg.line = ''
    call cursor('$',0)
    return
  endif

  call dbg#write(t:dbg.verbose, '.lines -e')
  call dbg#read(t:dbg.verbose)
  call dbg#write(t:dbg.verbose, 'l+s')
  call dbg#read(t:dbg.verbose)
  call dbg#write(t:dbg.verbose, 'l+t')
  call dbg#read(t:dbg.verbose)
  call s:comment('-----------------------------------------------')
  call s:comment('         Welcom to dbg.vim (CDB MODE)')
  call s:comment('!! You will need to set the first breakpoint')
  call s:comment('and run the target program.')
  call s:comment('')
  call s:comment('for example:')
  call s:comment('> bp WinMain')
  call s:comment('> g')
  call s:comment('-----------------------------------------------')
  call dbg#insert()
endfunction

function! s:engine.next()
  call dbg#focusIn()
  call dbg#write(0, 'p')
  call dbg#read(0)
  call s:engine.sync()
endfunction

function! s:engine.step()
  call dbg#focusIn()
  call dbg#write(0, 't')
  call dbg#read(0)
  call s:engine.sync()
endfunction

function! s:engine.continue()
  call dbg#focusIn()
  call dbg#write(0, 'g')
  call dbg#read(0)
  call s:engine.sync()
endfunction

function! s:engine.stepout()
  call dbg#focusIn()
  call dbg#write(0, 'k')
  let lines = dbg#read(0)
  for line in lines
    if match(line, '\x\{8} \x\{8}') == 0 || match(line, '\x\{16} \x\{16}') == 0
      let parts = split(line, ' ')
      if len(parts) > 1
        call dbg#write(0, 'g '. parts[1])
        call dbg#read(0)
        call s:engine.sync()
        break
      endif
    endif
  endfor
endfunction

function! s:engine.print()
  let word = expand("<cword>")
  call dbg#focusIn()
  call dbg#write(1, printf('dt %s', word))
  call dbg#read(1)
endfunction

function! s:engine.breakpoint()
  let path = expand('%:p')
  let line = line('.')
  call dbg#focusIn()
  call dbg#write(1, printf('bp `%s!%s:%d`',
    \ t:dbg.target_name,
    \ path,
    \ line
    \ ))
  call dbg#read(1)
endfunction

function! s:engine.locals()
  call dbg#focusIn()
  call dbg#write(1, 'dv')
  call dbg#read(1)
endfunction

function! s:engine.threads()
  call dbg#focusIn()
  call dbg#write(1, '~')
  call dbg#read(1)
endfunction

function! s:engine.callstack()
  call dbg#focusIn()
  call dbg#write(1, 'kb')
  call dbg#read(1)
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

  if exists == 0
    call setline(t:dbg.lnum, lines)
    let t:dbg.lnum = t:dbg.lnum + len(lines)
  endif
endfunction

function! s:engine.close()
  call dbg#focusIn()
  call dbg#write(1, 'q')
  call dbg#read(1)
endfunction

" internal functions

function! s:comment(msg)
  call dbg#write(1, '*' . a:msg)
  call dbg#read(1)
endfunction

