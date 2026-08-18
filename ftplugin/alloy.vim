" alloy를 hcl에서 분리하면서(d29b6ab) 내장 gc/gcc가 쓰는 commentstring도
" 같이 끊겼다. hcl ftplugin이 더는 로드되지 않으므로 여기서 다시 채운다.
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

setlocal commentstring=//\ %s

let b:undo_ftplugin = "setlocal commentstring<"
