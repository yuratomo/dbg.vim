" File: autoload/dbg.vim
" Last Modified: 2012.05.06
" Author: yuratomo (twitter @yusetomo)

let [ s:MODE_START, s:MODE_READING, s:MODE_PAUSE, s:MODE_COMPLETE ] = range(4)
let s:read_mode = s:MODE_START
let s:updatetime = 0

function! dbg#usage()
  echo '[usage]'
  echo 'Dbg [shell|mdbg]'
  echo 'or'
  echo 'Dbg [cdb|gdb|jdb|fdb|perl] [params]+'
  echo ''
  echo 'example 1) cdb'
  echo '  Dbg cdb c:\hoge\aaa.exe'
  echo 'example 2) gdb'
  echo '  Dbg gdb a.out'
  echo 'example 3) jdb'
  echo '  Dbg jdb test.Example'
  echo ''
endfunction

function! dbg#open(mode, ...)
  if exists('t:dbg')
    call dbg#close()
  endif

  if !exists('g:loaded_vimproc')
    echoerr "dbg.vim is depend on vimproc. Please install it."
    return
  endif

  try
    let dbg_per_engine = dbg#engines#{a:mode}#init()
  catch /.*/
    echo 'error in debugger "' . a:mode . '" ' . v:exception
    return
  endtry
  let t:dbg = {
    \ 'prompt'      : '> ',
    \ 'verbose'     : 0,
    \ 'needArgs'    : 1,
    \ 'line'        : '',
    \ 'lastCommand' : '',
    \ 'sign_id'     : 1,
    \ 'gdbMode'     : 1,
    \ 'split'       : 1,
    \ 'useKeyMap'   : 1,
    \ 'engine'      : {},
    \ 'pipe'        : {},
    \ }
  call extend(t:dbg, dbg_per_engine)

  if len(a:000) == 0 && t:dbg.needArgs == 1
    call dbg#usage()
    return
  endif

  call t:dbg.engine.open(a:000)

  if t:dbg.useKeyMap == 1
    call s:default_keymap()
  endif
endfunction

function! dbg#popen(cmd, params, welcome)
  if exists('t:dbg.pipe')
    unlet t:dbg.pipe
  endif

  if !executable(a:cmd)
    echoerr 'command not exists. (' . a:cmd . ')'
  endif

  let cmd_params = []
  call add(cmd_params, a:cmd)
  if has_key(t:dbg, 'cmdOptions')
    if t:dbg.cmdOptions =~ " "
      call extend(cmd_params, split(t:dbg.cmdOptions, " "))
    else
      call add(cmd_params, t:dbg.cmdOptions)
    endif
  endif
  call extend(cmd_params, a:params)

  try
    let t:dbg.pipe = vimproc#popen3(cmd_params)

    call dbg#focusIn()
    call dbg#output(a:welcome)

    call dbg#read(1)
    if t:dbg.pipe.stdout.eof
      let lines = split(t:dbg.line, "\n")
      call dbg#output(lines)
      let t:dbg.line = ''
      call cursor('$',0)
      return
    endif
  catch /.*/
  endtry
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

  if has_key(t:dbg, 'engine')
    unlet t:dbg.engine
  endif

  if has_key(t:dbg, 'pipe')
    unlet t:dbg.pipe
  endif

  unlet t:dbg
  sign unplace *
endfunction

function! dbg#command()
  if !exists('t:dbg') || !exists('t:dbg.engine')
    return
  endif
  if s:read_mode == s:MODE_PAUSE
    call dbg#control(10)
  else
    call s:command()
  endif
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
    call dbg#output(lastline[ 0 : last-1 ])
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
  let t:dbg.src_winnr = winnr()

  " if mode is shell-mode, then window don't split.
  if t:dbg.split == 1
    new
  endif

  silent edit `=bufname`
  setlocal bt=nofile noswf nowrap hidden nolist
  setlocal iskeyword+=46

  augroup dbg
    au!
    exe 'au BufDelete <buffer> call dbg#close()'
  augroup END

  sign define dbg_cur text=>>
  sign define dbg_bp  text=!!

  call s:map_ctrl_key(1)

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
  call dbg#markCurrentLine(a:line)
  normal zz
 exe curwinno . "wincmd w"
endfunction

function dbg#markCurrentLine(line)
  let old_sign_id = t:dbg.sign_id
  if t:dbg.sign_id == 1
    let t:dbg.sign_id = 2
  else
    let t:dbg.sign_id = 1
  endif
  let signs = 0

  if signs 
    exe ':sign place ' . t:dbg.sign_id . ' name=dbg_cur line=' . a:line . ' buffer=' . winbufnr(0)
    try
      exe ':sign unplace ' . old_sign_id . ' buffer=' . winbufnr(0)
    catch /.*/
    endtry
  else
    silent! syn clear DbgContext
    exec 'match DbgContext "\%'.a:line.'l.*"'
  endif
endfunction

highlight default DbgContext ctermfg=17 ctermbg=45 guifg=#00005f guibg=#00dfff

function! s:command()
  let line = getline('$')
  let last = matchend(line, t:dbg.prompt)
  if last != -1
    if dbg#write(2, line[ last : ]) == 0
      return
    endif

    if t:dbg.lastCommand[0] != '@' || t:dbg.gdbMode == 0
      if !empty(dbg#read(1))
        call t:dbg.engine.sync()
      endif
    endif
    if t:dbg.pipe.stdout.eof
      let lines = split(t:dbg.line, "\n")
      call dbg#output(lines)
      let t:dbg.line = ''
      return
    endif
  endif
  call dbg#insert()
  retur ''
endfunction

function! dbg#insert()
  inoremap <silent><buffer><CR> <ESC>:stopi<CR>:call dbg#command()<CR>
  call cursor('$',0)
  start!
endfunction

function! dbg#read(output)
  if !exists('t:dbg')
    return []
  endif

  let nop_cnt = 0
  if s:read_mode != s:MODE_PAUSE
    let s:read_mode = s:MODE_READING
  endif

  let t:dbg.last_readed_list = []
  while !t:dbg.pipe.stdout.eof

    " read stdout or stderr
    let err = 0
    let res = t:dbg.pipe.stdout.read()
    if res == ''
      let res = t:dbg.pipe.stderr.read()
      if res != ''
        let err = 1
      endif
    endif

    " analize
    if res == ''
      let last = matchend(t:dbg.line, t:dbg.prompt . '$')
      if last != -1
        let lines = split(t:dbg.line[ : last], "\n")
      else
        let lines = split(t:dbg.line, "\n")
      endif
      if a:output == 1
        if !empty(lines)
          call dbg#output(lines)
        endif
      endif
      call extend(t:dbg.last_readed_list, lines)
      if last != -1
        let t:dbg.line = t:dbg.line[ last : ]
        if t:dbg.line == ''
          call s:read_complete()
          break
        endif
      else
        if a:output != 0
          let t:dbg.line = ''
          if nop_cnt > 30
            call s:read_pause()
            return []
          endif
          let nop_cnt += 1
        endif
        sleep 10ms
      endif
      continue
    else
      if has_key(t:dbg, 'encoding')
        let res = iconv(res, t:dbg.encoding, &enc)
      endif
      if has_key(t:dbg, 'filter')
        let len = len(t:dbg.filter)
        let l = 0
        while l < len
          let filter = t:dbg.filter[l]
          let substitution = ""
          let regexp = filter
          if type(filter) == type([])
            unlet regexp
            let regexp = filter[0]
            let substitution = filter[1]
          endif
          let res = substitute(res, regexp, substitution, "g")
          let l += 1
          unlet filter
          unlet regexp
        endwhile
      endif
      let t:dbg.line = t:dbg.line . substitute(res, '\r', '', 'g')
      let nop_cnt = 0
    endif
  endwhile
  if has_key(t:dbg, 'encoding')
    let t:dbg.line = iconv(t:dbg.line, t:dbg.encoding, &enc)
  endif
  return t:dbg.last_readed_list
endfunction

function! s:read_pause()
  if s:read_mode != s:MODE_PAUSE
    let s:read_mode = s:MODE_PAUSE
    let s:updatetime  = &updatetime
    set updatetime=500
    augroup dbg
      au!
      au! CursorHoldI <buffer> call dbg#read_restart()
    augroup END

    call s:map_normal_key(1)
  endif
endfunction

function! dbg#direct_write(cmd)
  call t:dbg.pipe.stdin.write(nr2char(a:cmd))
  return nr2char(a:cmd)
endfunction

function! s:read_complete()
  let s:read_mode = s:MODE_COMPLETE
  if exists('s:updatetime')
    let &updatetime  = s:updatetime
    augroup dbg
      au!
    augroup END
    unlet s:updatetime
    call s:moveCursorLast()

    call s:map_normal_key(0)
  endif
endfunction

function! dbg#read_restart()
  if !empty(dbg#read(1))
    call t:dbg.engine.sync()
  endif
  call s:moveCursorLast()
endfunction

function! s:moveCursorLast()
  let vb  = &visualbell
  let tvb = &t_vb
  set visualbell
  set t_vb=
  call feedkeys("\<ESC>GA", 'n')
  let &visualbell  = vb
  let &t_vb        = tvb
endfunction

function! dbg#write(output, cmd)
  if t:dbg.gdbMode == 1 && (a:cmd == '' || a:cmd == '@')
    let cmd = t:dbg.lastCommand
  else
    let cmd = a:cmd
  endif

  " pre write
  if exists('t:dbg.engine.pre_write')
    if t:dbg.engine.pre_write(cmd) == 1
      return 0
    endif
  endif

  if t:dbg.gdbMode == 1 && cmd[0] == '@'
    " gdb mode
    call dbg#gdbCommand(cmd[ 1 : ])
    if !exists('t:dbg')
      return 0
    endif
    let line = getline('$')
    let last = matchend(line, t:dbg.prompt)
    call setline(line('$')+1, line[ 0 : last-1 ] . '@')
  else
    " normal mode
    call t:dbg.pipe.stdin.write(cmd . "\r\n")
    if a:output == 1
      call dbg#output(getline('$') . cmd)
      call cursor('$',0)
    endif
  endif
  if a:output == 2
    let t:dbg.lastCommand = cmd
  endif

  " post write
  if exists('t:dbg.engine.post_write')
    if t:dbg.engine.post_write(cmd) == 1
      return 0
    endif
  endif

  if !exists('t:dbg')
    return 0
  else
    return 1
  endif
endfunction

function! dbg#output(str)
  call setline(line('$')+1, a:str)
endfunction

function! dbg#control(n)
  call dbg#direct_write(a:n)
  call dbg#read(1)
  return ''
endfunction

function! dbg#tab()
  call feedkeys("\<c-n>", 'n')
  retur ''
endfunction

function! dbg#stab()
  call feedkeys("\<c-p>", 'n')
  retur ''
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

function s:map_ctrl_key(map)
  inoremap <expr> <buffer> <TAB> dbg#tab()
  inoremap <expr> <buffer> <S-TAB> dbg#stab()
  inoremap <buffer> <c-c> <ESC>:<c-u>call dbg#direct_write(3)<RETURN>a
endfunction

function s:map_normal_key(map)
  for [ _c, _e ] in [ ['a', 'z'], ['A', 'Z'], ['0', '9'], ['!', '/'], [':', '@']]
    let c = char2nr(_c)
    let e = char2nr(_e)
    while c <= e
      if a:map == 1
        exec 'inoremap <silent><buffer><expr> ' . nr2char(c) . ' dbg#direct_write(' . c . ')'
      else
        exec 'inoremap <silent><buffer> ' . nr2char(c) . ' ' . nr2char(c)
      endif
      let c += 1
    endwhile
  endfor
  if a:map == 1
    exec 'inoremap <silent><buffer> <SPACE> dbg#direct_write(" ")'
  else
    exec 'inoremap <silent><buffer> <SPACE> <SPACE>'
  endif
endfunction
