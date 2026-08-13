" Grafana Alloy syntax. Alloy is HCL-inspired, but dotted component names and
" references make the generic HCL Treesitter parser lose the rest of a file.
if exists("b:current_syntax")
  finish
endif

syntax case match
syntax sync fromstart

syntax keyword AlloyBoolean true false
syntax keyword AlloyConstant null
syntax match AlloyNumber /\<\d\+\(\.\d\+\)\?\>/
syntax match AlloyOperator /\(&&\|||\|==\|!=\|>=\|<=\|[+*\/%<>!-]\)/
syntax match AlloyDelimiter /[{}\[\](),]/

syntax keyword AlloyTodo contained TODO FIXME XXX BUG
syntax match AlloyComment /\/\/.*$/ contains=AlloyTodo,@Spell
syntax match AlloyComment /#.*$/ contains=AlloyTodo,@Spell
syntax region AlloyComment start=/\/\*/ end=/\*\// contains=AlloyTodo,@Spell
syntax region AlloyString start=/"/ skip=/\\\\\|\\"/ end=/"/
syntax region AlloyHeredoc start=/<<-\?\z([A-Za-z][A-Za-z0-9_]*\)/ end=/^\s*\z1\s*$/ keepend

syntax match AlloyReference /\<[A-Za-z_][A-Za-z0-9_]*\(\.[A-Za-z_][A-Za-z0-9_]*\)\+\>/
syntax match AlloyFunction /\<[A-Za-z_][A-Za-z0-9_]*\(\.[A-Za-z_][A-Za-z0-9_]*\)*\ze\s*(/
syntax match AlloyAttribute /\<[A-Za-z_][A-Za-z0-9_]*\>\ze\s*=/
syntax match AlloyComponent /^\s*\zs[A-Za-z_][A-Za-z0-9_]*\(\.[A-Za-z_][A-Za-z0-9_]*\)*\ze\(\s\+"[^"]*"\)\?\s*{/

highlight default link AlloyBoolean Boolean
highlight default link AlloyConstant Constant
highlight default link AlloyNumber Number
highlight default link AlloyOperator Operator
highlight default link AlloyDelimiter Delimiter
highlight default link AlloyTodo Todo
highlight default link AlloyComment Comment
highlight default link AlloyString String
highlight default link AlloyHeredoc String
highlight default link AlloyReference Special
highlight default link AlloyFunction Function
highlight default link AlloyAttribute Identifier
highlight default link AlloyComponent Type

let b:current_syntax = "alloy"
