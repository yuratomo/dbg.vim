
let s:engine = dbg#initEngine('shell')

function! dbg#engines#shell#init()
  return {
    \ 'prompt'  : g:dbg#shell_prompt,
    \ 'engine'  : s:engine,
    \ 'gdbMode' : 0,
    \ 'split'   : 0,
    \ }
endfunction

function! s:engine.open(params)
  call dbg#popen(g:dbg#command_shell, a:params, [
  \ '-----------------------------------------------',
  \ '         Welcome to dbg.vim (SHELL MODE)',
  \ '-----------------------------------------------',
  \ '',
  \ ])
  call dbg#insert()
endfunction

function! s:engine.run()
endfunction
function! s:engine.next()
endfunction
function! s:engine.step()
endfunction
function! s:engine.continue()
endfunction
function! s:engine.stepout()
endfunction
function! s:engine.print(...)
endfunction
function! s:engine.breakpoint(...)
endfunction
function! s:engine.locals()
endfunction
function! s:engine.threads()
endfunction
function! s:engine.callstack()
endfunction
function! s:engine.sync()
endfunction
function! s:engine.close()
endfunction

function! s:engine.pre_write(cmd)
  " vi or vim
  if a:cmd =~ '^\s*vim\s*' || a:cmd =~ '^\s*vi\s*'
    let line = getline('$')
    let last = matchend(line, t:dbg.prompt)
    if last != -1
      call dbg#output(line[ 0 : last - 1 ])
      call cursor('$',0)
      exe 'sp ' . substitute(a:cmd, '^\s*\(vim\|vi\)\s\+', '', '')
      return 1
    endif
  endif
  return 0
endfunction

function! s:engine.post_write(cmd)
  " cd
  if a:cmd =~ '^\s*cd\s*'
    call dbg#read(1)
    let line = getline('$')
    if has('win32')
      call dbg#write(2, 'echo %CD%')
    else
      call dbg#write(2, 'pwd')
    endif
    let res = dbg#read(0)
    if len(res) > 3
      exe 'cd ' . res[-3]
    endif
    call dbg#insert()
    return 1
  endif
  return 0
endfunction

