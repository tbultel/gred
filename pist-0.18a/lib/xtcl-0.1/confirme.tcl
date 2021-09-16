package provide xtcl 0.1

########################################################################
# fichier confirme.tcl ; maj le 06/09/95 (de bin2hex)
########################################################################

########################################################################
proc confirm {msg} {
  puts -nonewline stderr "\n$msg (y/n) "
  while {1} {
    set answer [gets stdin]
    switch -glob -- $answer {
      {[yYoOtT]*} { puts stderr Yes ; return 1 }
      {1}       { puts stderr Yes ; return 1 }
      {[nNfF]*}   { puts stderr No ; return 0 }
      {0}       { puts stderr No ; return 0 }
      {default} { puts stderr (y/n)?}
    }
  }
}

