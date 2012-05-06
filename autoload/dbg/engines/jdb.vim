
let s:engine = dbg#initEngine('jdb')

function! dbg#engines#jdb#init()
  call s:engine.prepare()
endfunction

function! s:engine.prepare()
  let t:dbg = {
    \ 'prompt'      : '> ',
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

  "resolve base directory
  let base_dir = input('base directory:', expand('%:p:h'), 'dir')
  let t:dbg._base_dir = base_dir
  if !isdirectory(base_dir)
    exe 'echoerr "' . base_dir . ' is not a directory"'
    return
  endif
  exe 'cd ' . base_dir

  call dbg#focusIn()

  let t:dbg.target_name = a:target

  let t:dbg.pipe = vimproc#popen3([g:dbg#command_jdb, a:target])
  call dbg#read(1)
  if t:dbg.pipe.stdout.eof
    let lines = split(t:dbg.line, "\n")
    call setline(t:dbg.lnum, lines)
    let t:dbg.line = ''
    call cursor('$',0)
    return
  endif

  call s:comment('-----------------------------------------------')
  call s:comment('         Welcom to dbg.vim (JDB MODE)')
  call s:comment('!! You will need to set the first breakpoint')
  call s:comment('and run the target program.')
  call s:comment('')
  call s:comment('for example:')
  call s:comment('> stop in ' . a:target . '.main')
  call s:comment('> run')
  call s:comment('-----------------------------------------------')
  call dbg#insert()
endfunction

function! s:engine.next()
  call dbg#focusIn()
  call dbg#write(0, 'next')
  call dbg#read(0)
  call s:engine.sync()
endfunction

function! s:engine.step()
  call dbg#focusIn()
  call dbg#write(0, 'step')
  call dbg#read(0)
  call s:engine.sync()
endfunction

function! s:engine.continue()
  call dbg#focusIn()
  call dbg#write(0, 'cont')
  call dbg#read(0)
  call s:engine.sync()
endfunction

function! s:engine.stepout()
  call dbg#focusIn()
  call dbg#write(0, 'step up')
  call dbg#read(0)
  call s:engine.sync()
endfunction

function! s:engine.print()
  let word = expand("<cword>")
  call dbg#focusIn()
  call dbg#write(1, printf('print %s', word))
  call dbg#read(1)
endfunction

function! s:engine.breakpoint()
  let path = expand('%:p:r')
  let start = len(t:dbg._base_dir)
  if len(path) <= start
    echoerr "illegal source code???"
    return
  endif
  let class = substitute(path[ start+1 : ], '\', '/', 'g')
  let line = line('.')
  call dbg#focusIn()
  call dbg#write(1, printf('stop at %s:%d',
    \ class,
    \ line
    \ ))
  call dbg#read(1)
endfunction

function! s:engine.locals()
  call dbg#focusIn()
  call dbg#write(1, 'locals')
  call dbg#read(1)
endfunction

function! s:engine.threads()
  call dbg#focusIn()
  call dbg#write(1, 'threads')
  call dbg#read(1)
endfunction

function! s:engine.callstack()
  call dbg#focusIn()
  call dbg#write(1, 'wherei')
  call dbg#read(1)
endfunction

function! s:engine.sync()
  call dbg#write(0, 'where')
  let lines = dbg#read(0)
  if len(lines) >= 1
    if match(lines[0], '\[\d\+\].*\(.*:\d\+\)') != -1
      let start = stridx(lines[0], '(') + 1
      let mid   = stridx(lines[0], ':')
      let end   = stridx(lines[0], ')') - 1
      let name  = lines[0][start : mid-1]
      let num   = lines[0][mid+1 : end  ]
      let path  = t:dbg._base_dir . '/' . name
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
endfunction

function! s:engine.close()
  call dbg#focusIn()
  call dbg#write(1, 'quit')
  call dbg#read(1)
endfunction

" internal functions

function! s:comment(msg)
  call dbg#write(1, '*' . a:msg)
  call dbg#read(0)
  call dbg#write(0, '')
  call dbg#read(1)
endfunction

