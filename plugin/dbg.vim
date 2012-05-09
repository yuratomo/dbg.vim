" File: plugin/w3m.vim
" Last Modified: 2012.05.05
" Version: 0.1.0
" Author: yuratomo (twitter @yusetomo)

if !has('signs')
  finish
endif
if exists('g:loaded_dbg') && g:loaded_dbg == 1
  finish
endif

let g:dbg#command_cdb = 'cdb.exe'
let g:dbg#command_jdb = 'jdb'
let g:dbg#command_gdb = 'gdb'
let g:dbg#command_fdb = 'fdb'
let g:dbg#command_python = 'c:\Python27\python.exe'
let g:dbg#title_prefix = 'dbg-'

command! -nargs=* -complete=file Dbg :call dbg#open(<f-args>)

let g:loaded_dbg = 1

