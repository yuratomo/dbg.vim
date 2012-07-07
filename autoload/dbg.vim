" File: autoload/dbg.vim
" Last Modified: 2012.05.06
" Author: yuratomo (twitter @yusetomo)

function! dbg#usage()
  echo '[usage]'
  echo 'Dbg [cdb|mdbg|gdb|jdb|fdb] [params]+'
  echo ''
  echo 'ex1) cdb'
  echo 'Dbg cdb c:\hoge\aaa.exe'
  echo ''
endfunction

function! dbg#open(mode, ...)
  if exists('t:dbg')
    call dbg#close()
  endif
  if a:mode != 'mdbg' && len(a:000) == 0
    call dbg#usage()
    return
  endif

  if !exists('g:loaded_vimproc')
    echoerr "dbg.vim is depend on vimproc. Please install it."
    return
  endif

  let dbg_per_engine = dbg#engines#{a:mode}#init()
  let t:dbg = {
    \ 'prompt'      : '> ',
    \ 'verbose'     : 0,
    \ 'lnum'        : 1,
    \ 'line'        : '',
    \ 'lastCommand' : '',
    \ 'sign_id'     : 1,
    \ 'engine'      : {},
    \ 'pipe'        : {},
    \ }
  call extend(t:dbg, dbg_per_engine)

  call t:dbg.engine.open(a:000)
  call s:default_keymap()
endfunction

function! dbg#popen(cmd, params)
  if exists('t:dbg.pipe')
    unlet t:dbg.pipe
  endif

  if !executable(a:cmd)
    echoerr 'command not exists. (' . a:cmd . ')'
  endif

  call dbg#focusIn()

  let cmd_params = []
  call add(cmd_params, a:cmd)
  call extend(cmd_params, a:params)

  let t:dbg.pipe = vimproc#popen3(cmd_params)
  call dbg#read(1)
  if t:dbg.pipe.stdout.eof
    let lines = split(t:dbg.line, "\n")
    call setline(t:dbg.lnum, lines)
    let t:dbg.line = ''
    call cursor('$',0)
    return
  endif
endfunction

function! dbg#close()
  if !exists('t:dbg')
    return
  endif
  try
    call t:dbg.engine.close()
    call t:dbg.close()
  catch /.*/
  endtry
  unlet t:dbg.engine
  unlet t:dbg.pipe
  unlet t:dbg
  sign unplace *
endfunction

function! dbg#command()
  if !exists('t:dbg.engine')
    return
  endif
  call s:command()
endfunction

function! dbg#run()
  if !exists('t:dbg.engine')
    return
  endif
  call t:dbg.engine.run()
endfunction

function! dbg#next()
  if !exists('t:dbg.engine')
    return
  endif
  call t:dbg.engine.next()
endfunction

function! dbg#step()
  if !exists('t:dbg.engine')
    return
  endif
  call t:dbg.engine.step()
endfunction

function! dbg#continue()
  if !exists('t:dbg.engine')
    return
  endif
  call t:dbg.engine.continue()
endfunction

function! dbg#stepout()
  if !exists('t:dbg.engine')
    return
  endif
  call t:dbg.engine.stepout()
endfunction

function! dbg#print(...)
  if !exists('t:dbg.engine')
    return
  endif
  call t:dbg.engine.print(join(a:000, ' '))
endfunction

function! dbg#breakpoint(...)
  if !exists('t:dbg.engine')
    return
  endif

  if len(a:000) >= 1
    let colon = strridx(a:000[0], ':')
    if colon == -1
      return
    endif
    let path = a:000[0][0 : colon-1]
    let line = a:000[0][colon+1 :  ]
    let lastline = getline('$')
    let last = matchend(lastline, t:dbg.prompt)
    call setline(t:dbg.lnum, lastline[ 0 : last-1 ])
  else
    let path = expand('%:p')
    let line = line('.')
  endif
  if !exists('t:dbg.breakpoints')
    let t:dbg.breakpoints = []
  endif
  let idx = 0
  let exists = -1
  for bp in t:dbg.breakpoints
    if bp.path == path && bp.line == line
      let exists = idx
    endif
    let idx += 1
  endfor
  if exists != -1
    call remove(t:dbg.breakpoints, idx)
  else
    call add(t:dbg.breakpoints, {'path':path, 'line':line } )
  endif
  try
    exe ':sign unplace dbg_bp'
  catch /.*/
  endtry
  for bp in t:dbg.breakpoints
    try 
      exe ':sign place 3 name=dbg_bp line=' . bp.line . ' file=' . bp.path
    catch /.*/
    endtry
  endfor

  call t:dbg.engine.breakpoint(path, line)
endfunction

function! dbg#locals()
  if !exists('t:dbg.engine')
    return
  endif
  call t:dbg.engine.locals()
endfunction

function! dbg#threads()
  if !exists('t:dbg.engine')
    return
  endif
  call t:dbg.engine.threads()
endfunction

function! dbg#callstack()
  if !exists('t:dbg.engine')
    return
  endif
  call t:dbg.engine.callstack()
endfunction

"
" for each engines
"
function! dbg#initEngine(name)
  let engine = {}
  return engine
endfunction

function! dbg#focusIn()
  if !exists('t:dbg.engine')
    return
  endif

  let t:dbg.old_winnum = winnr()
  let winnum = winnr('$')
  for winno in range(1, winnum)
    let bufname = bufname(winbufnr(winno))
    if bufname =~ g:dbg#title_prefix
       exe winno . "wincmd w"
       return
    endif
  endfor

  " if not exist dbg window, then create new window.
  let id = 1
  while buflisted(g:dbg#title_prefix.id)
    let id += 1
  endwhile
  let bufname = g:dbg#title_prefix.id
  new
  silent edit `=bufname`
  setlocal bt=nofile noswf nowrap hidden nolist

  augroup dbg
    au!
    exe 'au BufDelete <buffer> call dbg#close()'
  augroup END

  sign define dbg_cur text=>>
  sign define dbg_bp  text=!!

  nnoremap <buffer><c-c> :<c-u>call dbg#control(3)<CR>
  "inoremap <expr><buffer><c-c> dbg#control(3)  ... error. but why?
  inoremap <buffer><c-c> <ESC>:call dbg#control(3)<CR>a

endfunction

function! dbg#focusBack()
  if exists('t:dbg.old_winnum')
    exe t:dbg.old_winnum . "wincmd w"
    unlet t:dbg.old_winnum
  endif
endfunction

function! dbg#openSource(path, line)
  let curwinno = winnr()
  let winnum = winnr('$')
  if winnum < 2
    exe 'new +' . a:line . ' ' . a:path
  else
    for winno in range(1, winnum)
      let bufname = bufname(winbufnr(winno))
      if bufname !~ g:dbg#title_prefix
         exe winno . "wincmd w"
         if expand('%:p') != a:path
           exe 'edit +' . a:line . ' ' . escape(a:path, ' ')
         else
           call cursor(a:line, 0)
         endif
         break
      endif
    endfor
  endif
  let old_sign_id = t:dbg.sign_id
  if t:dbg.sign_id == 1
    let t:dbg.sign_id = 2
  else
    let t:dbg.sign_id = 1
  endif
  exe ':sign place ' . t:dbg.sign_id . ' name=dbg_cur line=' . a:line . ' buffer=' . winbufnr(0)
  try
    exe ':sign unplace ' . old_sign_id . ' buffer=' . winbufnr(0)
  catch /.*/
  endtry
  normal zz
 exe curwinno . "wincmd w"
endfunction

function! s:command()
  let line = getline('$')
  let last = matchend(line, t:dbg.prompt)
  if last != -1
    call dbg#write(2, line[ last : ])
    if t:dbg.lastCommand[0] != '@'
      call dbg#read(1)
    endif
    if t:dbg.pipe.stdout.eof
      let lines = split(t:dbg.line, "\n")
      call setline(t:dbg.lnum, lines)
      let t:dbg.line = ''
      return
    endif
    call t:dbg.engine.sync()
  endif
  call dbg#insert()
  retur ''
endfunction

function! dbg#insert()
  inoremap <buffer><CR> <ESC>:stopi<CR>:call dbg#command()<CR>
  call cursor('$',0)
  start!
endfunction

function! dbg#read(output)
  let t:dbg.last_readed_list = []
  while !t:dbg.pipe.stdout.eof
    let res = t:dbg.pipe.stdout.read()
    if res == ''
      let midx = match(t:dbg.line, t:dbg.prompt)
      if midx != -1
        let last = matchend(t:dbg.line, t:dbg.prompt)
        let lines = split(t:dbg.line[ : last], "\n")
      else
        let lines = split(t:dbg.line, "\n")
      endif
      if a:output == 1
        call setline(t:dbg.lnum, lines)
        call cursor('$',0)
        let t:dbg.lnum = t:dbg.lnum + len(lines)
      endif
      call extend(t:dbg.last_readed_list, lines)
      redraw
      if midx != -1
        let t:dbg.line = t:dbg.line[ last : ]
        if t:dbg.line == ''
          break
        endif
      else
        let t:dbg.line = ''
        sleep 100ms
      endif
      continue
    else
      let t:dbg.line = t:dbg.line . res
    endif
  endwhile
  return t:dbg.last_readed_list
endfunction

function! dbg#write(output, cmd)
  if a:cmd == '' || a:cmd == '@'
    let cmd = t:dbg.lastCommand
  else
    let cmd = a:cmd
  endif
  if cmd[0] == '@'
    call dbg#gdbCommand(cmd[ 1 : ])
    let line = getline('$')
    let last = matchend(line, t:dbg.prompt)
    call setline(t:dbg.lnum, line[ 0 : last-1 ] . '@')
    let t:dbg.lnum += 1
  else
    call t:dbg.pipe.stdin.write(cmd . "\r\n")
    if a:output == 1
      call setline(t:dbg.lnum-1, getline('$') . cmd)
    endif
  endif
  if a:output == 2
    let t:dbg.lastCommand = cmd
  endif
  if exists('t:dbg.engine.post_write')
    call t:dbg.engine.post_write(cmd)
  endif
  if a:output == 1
    call cursor('$',0)
  endif
  return ''
endfunction

function! dbg#control(n)
  call dbg#write(2, nr2char(a:n))
  call dbg#read(1)
  return ''
endfunction

function! s:default_keymap()
  nnoremap <Plug>(dbg-next)        :<C-u>call dbg#next()<CR>
  nnoremap <Plug>(dbg-step)        :<C-u>call dbg#step()<CR>
  nnoremap <Plug>(dbg-continue)    :<C-u>call dbg#continue()<CR>
  nnoremap <Plug>(dbg-stepout)     :<C-u>call dbg#stepout()<CR>
  nnoremap <Plug>(dbg-print)       :<C-u>call dbg#print()<CR>
  nnoremap <Plug>(dbg-breakpoint)  :<C-u>call dbg#breakpoint()<CR>
  nnoremap <Plug>(dbg-locals)      :<C-u>call dbg#locals()<CR>
  nnoremap <Plug>(dbg-threads)     :<C-u>call dbg#threads()<CR>
  nnoremap <Plug>(dbg-callstack)   :<C-u>call dbg#callstack()<CR>

  if !exists('g:dbg#disable_default_keymap') || g:dbg#disable_default_keymap == 0
    nmap <F5>    <Plug>(dbg-continue)
    nmap <F9>    <Plug>(dbg-breakpoint)
    nmap <F10>   <Plug>(dbg-next)
    nmap <F11>   <Plug>(dbg-step)
    nmap <S-F11> <Plug>(dbg-stepout)
    nmap <F2>    <Plug>(dbg-print)
    nmap <F6>    <Plug>(dbg-locals)
    nmap <F7>    <Plug>(dbg-threads)
    nmap <F8>    <Plug>(dbg-callstack)
  endif
endfunction

"
" for gdb-mode
"
let s:gdbCommands = [
  \ {'name':'run',          'param':0, 'fn':'dbg#run'},
  \ {'name':'next',         'param':0, 'fn':'dbg#next'},
  \ {'name':'step',         'param':0, 'fn':'dbg#step'},
  \ {'name':'continue',     'param':0, 'fn':'dbg#continue'},
  \ {'name':'finish',       'param':0, 'fn':'dbg#stepout'},
  \ {'name':'print',        'param':1, 'fn':'dbg#print'},
  \ {'name':'break',        'param':1, 'fn':'dbg#breakpoint'},
  \ {'name':'info locals',  'param':0, 'fn':'dbg#locals'},
  \ {'name':'info threads', 'param':0, 'fn':'dbg#threads'},
  \ {'name':'info bt',      'param':0, 'fn':'dbg#callstack'},
  \ {'name':'where',        'param':0, 'fn':'dbg#callstack'},
  \ {'name':'backtrace',    'param':0, 'fn':'dbg#callstack'},
  \ {'name':'quit',         'param':0, 'fn':'dbg#close'}
  \ ]

function! dbg#gdbCommand(cmd)
  let params = split(a:cmd, '\s')
  let cmd = params[0]
  if cmd == 'info'
    let cmd = join(params[0 : 1], ' ')
    let param = join(params[2 : ], ' ')
  else
    let param = join(params[1 : ], ' ')
  endif

  for item in s:gdbCommands
    if item.name =~ '^' . cmd
      if item.param == 1
        call function(item.fn)(param)
      else
        call function(item.fn)()
      endif
      return
    endif
  endfor

  echoerr 'unknown command [' . cmd . ']'
endfunction

