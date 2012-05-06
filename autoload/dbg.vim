" File: autoload/dbg.vim
" Last Modified: 2012.05.06
" Author: yuratomo (twitter @yusetomo)

function! dbg#open(mode, ...)
  if exists('t:dbg')
    call dbg#close()
  endif

  "if !exists('*vimproc#system()')
  if !exists('g:loaded_vimproc')
    echoerr "dbg.vim is depend on vimproc. Please install it."
    return
  endif

  call dbg#engines#{a:mode}#init()
  call t:dbg.engine.open(join(a:000, ' '))

  call s:default_keymap()
endfunction

function! dbg#close()
  if !exists('t:dbg')
    return
  endif
  try
    call t:dbg.engine.close()
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

function! dbg#print()
  if !exists('t:dbg.engine')
    return
  endif
  call t:dbg.engine.print()
endfunction

function! dbg#breakpoint()
  if !exists('t:dbg.engine')
    return
  endif
  call t:dbg.engine.breakpoint()
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

  sign define dbg_cur text=>
  sign define dbg_bp  text=!

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
           exe 'edit +' . a:line . ' ' . a:path
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
    call dbg#read(1)
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
  let ret_lines = []
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
        let t:dbg.lnum = t:dbg.lnum + len(lines)
      else
        call extend(ret_lines, lines)
      endif
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
  call cursor('$',0)
  return ret_lines
endfunction

function! dbg#write(output, cmd)
  if a:cmd == ''
    let cmd = t:dbg.lastCommand
  else
    let cmd = a:cmd
  endif
  call t:dbg.pipe.stdin.write(cmd . "\r\n")
  if a:output == 1
    call setline(t:dbg.lnum-1, getline('$') . cmd)
  endif
  if a:output == 2
    let t:dbg.lastCommand = cmd
  endif
  if exists('t:dbg.engine.post_write')
    call t:dbg.engine.post_write(cmd)
  endif
  call cursor('$',0)
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
    nmap <buffer><F5>    <Plug>(dbg-continue)
    nmap <buffer><F9>    <Plug>(dbg-breakpoint)
    nmap <buffer><F10>   <Plug>(dbg-next)
    nmap <buffer><F11>   <Plug>(dbg-step)
    nmap <buffer><S-F11> <Plug>(dbg-stepout)
    nmap <buffer><F2>    <Plug>(dbg-print)
    nmap <buffer><F6>    <Plug>(dbg-locals)
    nmap <buffer><F7>    <Plug>(dbg-threads)
    nmap <buffer><F8>    <Plug>(dbg-callstack)
  endif
endfunction

