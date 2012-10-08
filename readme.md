dbg.vim
=======

Description
-----------
dbg.vim is vim scipt for debug the program.
support mdbg, cdb, gdb, jdb and fdb. (not support pdb now)
!!cdb is a command-line debugger for windows.
!!mdbg is a command-line debugger for .Net Framework.

Requirements
------------
1) dbg.vim is requires vimproc and each debuggers.

2) Through the path to each debugger or define the vimrc as follows.

    let g:dbg#command_shell = 'cmd.exe'
    let g:dbg#shell_prompt = '> '
    
    let g:dbg#command_cdb = 'cdb.exe'
    let g:dbg#command_mdbg= 'C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin\NETFX 4.0 Tools\mdbg.exe'
    let g:dbg#command_jdb = 'jdb'
    let g:dbg#command_gdb = 'gdb'
    let g:dbg#command_fdb = 'fdb'
    !! let g:dbg#command_python = 'python' !! now not support pdb.

Usage
-----

### shell ###

1) start shell as follow.

    :DbgShell
    or
    :Dbg shell


### cdb ###

1) start debugger as follow.

    :Dbg cdb exe-file-path

2) set first breakpoint.

    > bp main
      or
    
    > bp WinMain
      or
    
    > bp wWinMain
      or 

3) run the program.
    > g
      or
    Press <F5> in command mode.


### mdbg ###

1) start debugger as follow.

    :Dbg mdbg exe-file-path

2) run the program.
    > run

### gdb ###

1) start debugger as follow

    :Dbg gdb out-file-path

2) set first breakpoint.

    > break sorce:line
      or
    Press <F9> on the break line in command mode.

3) run the program.

    > run
      or
    Press <F5> in command mode.


### jdb ###

1) start debugger as follow

    :Dbg jdb Main-Class-Name
    And input source-code-base-directory.

2) set first breakpoint.

    > stop in Class.main
      or
    Press <F9> on the break line in command mode.

3) run the program.

    > run
      or
    Press <F5> in command mode.

### fdb ###

1) start debugger as follow

    :Dbg fdb swf-file-path
    And input source-code-base-directory.

2) set first breakpoint.

    > break method
      or
    > break file:line
      or
    Press <F9> on the break line in command mode.

3) continue the program.

    > continue
      or
    Press <F5> in command mode.


### gdb mode###
gdb mode is a input method like a gdb.

1) start debugger.

2) input gdb command with atmark.

    > @run

    > @next

    > @step

    > @continue

    > @finish

    > @print xxx

    > @info bt

    > @info locals

    > @info threads

    > @info where

    > @info backtrace

    > @info quit


It is also possible shorthand.

    > @n

    > @p

    ... etc

Default Keymaps
---------------
* &lt;F2&gt;    Print variable  under the cursor.
* &lt;F5&gt;    Continue the program.
* &lt;F6&gt;    Show locals variable.
* &lt;F7&gt;    Show threads variable.
* &lt;F8&gt;    Show callstack.
* &lt;F9&gt;    Set breakpoints under the cursor.
* &lt;F10&gt;   Next
* &lt;F11&gt;   Step
* &lt;S-F11&gt; stepout


ScreenShots
-----------
xxx


HISTORY
-------

### v0.3.0 by yuratomo ###
* support shell-mode (win -> cmd.exe, other -> bash)
* fix read-stdout

### v0.2.0 by yuratomo ###
* support mdbg (.Net Framework console debugger)

### v0.1.0 by yuratomo ###
* first release

