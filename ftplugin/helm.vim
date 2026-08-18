" helm은 이 설정이 직접 만든 filetype(templates/ 아래 YAML과 .tpl)이라 런타임에
" 대응하는 ftplugin이 없다. commentstring이 비면 gc가 조용히 아무것도 안 한다.
"
" 파일별로 나눌 수는 없다. 내장 주석 기능은 treesitter가 붙은 버퍼에서
" vim.filetype.get_option("helm", "commentstring")으로 값을 구하는데, 이때
" 이름 없는 임시 버퍼에서 이 파일을 읽으므로 `expand("%:e")` 같은 분기가 통하지
" 않는다. 그래서 다수인 차트 템플릿(YAML) 기준으로 #을 쓴다.
" _helpers.tpl에서도 #이 붙는다 — Go 템플릿 주석 {{/* */}}이 필요하면 직접 쓴다.
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

setlocal commentstring=#\ %s

let b:undo_ftplugin = "setlocal commentstring<"
