package provide xtcl 0.1

# return a string containing N times the txt.
proc Str_Dup {txt {N 2}} {
   for {set i 1; set txtS ""} {$i<=$N} {incr i} {append txtS $txt}
   return $txtS
}
