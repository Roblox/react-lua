# Scheduler
Porting the scheduler from React.

## Regexes:

|Description|From|To|
|-|-|-|
|"} else {" -> "else"|`\} else \{`|`else`|
|"}" -> "end"|`(^\t*)\}$`|`$1end`|
|"var" -> "local"|`(\s+)var `|`$1local `