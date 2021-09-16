package provide tclx 0.1


# de Paul RAINES (tkmail4.0-beta-x)

if {"[info proc infox]" == ""} {
proc keylget { lvar key {rvar 0} } {
  upvar $lvar klist
  set check 0
  if {$rvar != 0} {
    set check 1
    if {[string length $rvar]} {upvar $rvar ret}
  }
  foreach pair $klist {
    if {[lindex $pair 0] == $key} {
      if [catch {lindex $pair 1} ret] {
        set ret [string trim [string range $pair [string length $key] end]]
        if {[string index $ret 0] == "\{"} {
          set ret [string trim $ret "{}"]
        }
      }
      if {$check} { return 1 } else {return $ret}
    }
  }
  if {$check} { 
    return 0 
  } else { error "No key named $key in $lvar" }
}
proc keylset { lvar key val } {
  upvar $lvar klist
  set ndx 0
  if {[info exists klist]} {
    foreach pair $klist {
      if {[lindex $pair 0] == $key} {
        set klist [lreplace $klist $ndx $ndx "$key {$val}"]
        return {}
      }
      incr ndx
    }
  }
  lappend klist "$key {$val}"
  return {}
}
} ;# end if ... infox
