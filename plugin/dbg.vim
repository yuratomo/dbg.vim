" File: plugin/w3m.vim
" Last Modified: 2012.10.08
" Version: 0.3.0
" Author: yuratomo (twitter @yusetomo)

if !has('signs')
  finish
endif
if exists('g:loaded_dbg') && g:loaded_dbg == 1
  finish
endif

if !exists('g:dbg#command_shell')
  if has('win32')
    let g:dbg#command_shell = 'cmd'
  else
    let g:dbg#command_shell = 'bash'
  endif
endif

if !exists('g:dbg#command_encoding')
  if has('win32')
    let g:dbg#command_encoding = 'cp932'
  endif
endif

if !exists('g:dbg#shell_prompt')
  if has('win32')
    let g:dbg#shell_prompt  = '>'
  else
    let g:dbg#shell_prompt  = '$ '
  endif
endif

if !exists('g:dbg#title_prefix')
  let g:dbg#title_prefix   = 'dbg-'
endif

if !exists('g:dbg#command_cdb')
  let g:dbg#command_cdb    = 'cdb.exe'
endif
if !exists('g:dbg#command_mdbg')
  let g:dbg#command_mdbg   = 'mdbg.exe'
endif
if !exists('g:dbg#command_jdb')
  let g:dbg#command_jdb    = 'jdb'
endif
if !exists('g:dbg#command_gdb')
  let g:dbg#command_gdb    = 'gdb'
endif
if !exists('g:dbg#command_fdb')
  let g:dbg#command_fdb    = 'fdb'
endif
if !exists('g:dbg#command_python')
  let g:dbg#command_python = 'python'
endif

command! -nargs=* -complete=file Dbg      :call dbg#open(<f-args>)
command! -nargs=* -complete=file DbgShell :call dbg#open('shell')

let g:loaded_dbg = 1

