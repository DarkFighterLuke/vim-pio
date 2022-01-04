" vim-pio - helpers for the PlatformIO command line tool
" Author: Normen Hansen <normen667@gmail.com>
" Home: https://github.com/normen/vim-pio

if (exists("g:loaded_vim_pio") && g:loaded_vim_pio) || &cp
  finish
endif
let g:loaded_vim_pio = 1

command! -nargs=+ PIO  call s:OpenTermOnce('platformio ' . <q-args>, "Platform IO")
command! PIOCreateMakefile call <SID>PIOCreateMakefile()
command! PIORefresh !platformio project init --ide vim
command! -nargs=* PIONew call <SID>PIOBoardSelection(<q-args>)
command! -nargs=+ PIOLibrary call <SID>PIOLibrarySelection(<q-args>)
command! -nargs=1 -complete=custom,<SID>PIOBoardList PIOInit !platformio project init --ide vim --board <args>
command! -nargs=1 -complete=custom,<SID>PIOLibraryList PIOInstall !platformio lib install '<args>'

" get a list of PlatformIO boards
function s:PIOBoardList(args,L,P)
  let raw_boards=systemlist("pio boards ".a:args)
  let boards=[]
  for boardline in raw_boards
    let board_info=matchlist(boardline,'^\([^\s\t ]*\) .*Hz.*')
    if !empty(board_info)
      let name = get(board_info,1)
      let boards = boards + [name]
    endif
  endfor
  return join(boards,"\n")
endfunction

" get a list of PlatformIO boards
function s:PIOLibraryList(args,L,P)
  let all_libs = system("pio lib search ".a:args)
  let idx=0
  let hit=["jdf"]
  let libnames=[]
  while !empty(hit)
    " match 3 lib info lines:
    " Library Name
    " ============
    " #ID: 999
    let hit=matchlist(all_libs,'\n\([^\n]*\)\n=*\n#ID: \([0-9]*\)\n',0,idx)
    if !empty(hit)
      let libnames=libnames + [get(hit,1)]
      let idx=idx+1
    endif
  endwhile
  return join(libnames,"\n")
endfunction

function s:PIOCreateMakefile()
  let data=[
    \ "# CREATED BY VIM-PIO",
    \ "all:",
    \ "	platformio -f -c vim run",
    \ "",
    \ "upload:",
    \ "	platformio -f -c vim run --target upload",
    \ "",
    \ "clean:",
    \ "	platformio -f -c vim run --target clean",
    \ "",
    \ "program:",
    \ "	platformio -f -c vim run --target program",
    \ "",
    \ "uploadfs:",
    \ "	platformio -f -c vim run --target uploadfs"]
  if writefile(data, 'Makefile')
    echomsg 'write error'
  endif
endfunction

" show a list of libraries for selection
function! s:PIOLibrarySelection(args)
  let winnr = bufwinnr('PIO Libraries')
  if(winnr>0)
    execute winnr.'wincmd w'
    setlocal noro modifiable
    execute '%d'
  else
    bo new
    file 'PIO Libraries'
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile wrap
    setlocal filetype=piolibraries
    nnoremap <buffer> <CR> :exec '!pio lib install "'.getline('.').'"'<CR>
  endif
  execute 'silent $read !pio lib search --noninteractive '.a:args
  setlocal ro nomodifiable
  1
endfunction

" show a list of boards for selection
function! s:PIOBoardSelection(args)
  let winnr = bufwinnr('PIO Boards')
  if(winnr>0)
    execute winnr.'wincmd w'
    setlocal noro modifiable
    execute '%d'
  else
    bo new
    file 'PIO Boards'
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
    setlocal filetype=pioboards
    nnoremap <buffer> <CR> :exec '!pio init --ide vim --board '.expand('<cWORD>')<CR>
  endif
  execute 'silent $read !pio boards '.a:args
  setlocal ro nomodifiable
  1
endfunction

" Open a named Term window only once (command tools)
function! s:OpenTermOnce(command, buffername)
  let winnr = bufwinnr(a:buffername)
  if(winnr>0)
    execute winnr.'wincmd c'
  endif
  call term_start(a:command,{'term_name':a:buffername})
endfunction

