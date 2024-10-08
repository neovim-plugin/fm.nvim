if exists("b:current_syntax")
  finish
endif

syn match fmCreate /^CREATE /
syn match fmMove   /^  MOVE /
syn match fmDelete /^DELETE /
syn match fmCopy   /^  COPY /
syn match fmChange /^CHANGE /
" Trash operations
syn match fmRestore /^RESTORE /
syn match fmPurge /^ PURGE /
syn match fmTrash /^ TRASH /

let b:current_syntax = "fm_preview"
