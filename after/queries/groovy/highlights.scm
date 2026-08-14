; extends

; Declarative Pipeline root. The Groovy parser gives `pipeline` its own node,
; while nested Jenkins directives are ordinary Groovy function calls.
(pipeline
  "pipeline" @keyword)

; Pipeline structure. These are visually distinct from executable steps, which
; retain Groovy's normal @function highlight.
((function_call
  function: (identifier) @keyword.directive)
  (#any-of? @keyword.directive
    "agent"
    "axes"
    "axis"
    "environment"
    "exclude"
    "excludes"
    "libraries"
    "matrix"
    "options"
    "parameters"
    "post"
    "stages"
    "steps"
    "tools"
    "triggers"))

((juxt_function_call
  function: (identifier) @keyword.directive)
  (#any-of? @keyword.directive
    "agent"
    "axes"
    "axis"
    "environment"
    "exclude"
    "excludes"
    "libraries"
    "matrix"
    "options"
    "parameters"
    "post"
    "stages"
    "steps"
    "tools"
    "triggers"))

; Stage declarations stand out from both structural blocks and ordinary steps.
((function_call
  function: (identifier) @function.macro)
  (#any-of? @function.macro "stage" "parallel"))

((juxt_function_call
  function: (identifier) @function.macro)
  (#any-of? @function.macro "stage" "parallel"))

; Declarative conditions and post-build conditions use the conditional color.
((function_call
  function: (identifier) @keyword.conditional)
  (#any-of? @keyword.conditional
    "allOf"
    "always"
    "anyOf"
    "beforeAgent"
    "beforeInput"
    "beforeOptions"
    "changed"
    "cleanup"
    "failure"
    "fixed"
    "input"
    "not"
    "regression"
    "success"
    "unstable"
    "unsuccessful"
    "when"))

((juxt_function_call
  function: (identifier) @keyword.conditional)
  (#any-of? @keyword.conditional
    "allOf"
    "always"
    "anyOf"
    "beforeAgent"
    "beforeInput"
    "beforeOptions"
    "changed"
    "cleanup"
    "failure"
    "fixed"
    "input"
    "not"
    "regression"
    "success"
    "unstable"
    "unsuccessful"
    "when"))

; `agent any` and `agent none` are Jenkins constants, not user variables.
((juxt_function_call
  function: (identifier) @_jenkins_agent
  args: (argument_list
    (identifier) @constant.builtin))
  (#eq? @_jenkins_agent "agent")
  (#any-of? @constant.builtin "any" "none"))
