package provide tclx 0.1


######################################################################
# MaJ par diam@ensta.fr 27/05/96

# on peut ne d»finir ces proc que si elle ne sont pas d»ja pr»d»finies
# dans tclx (tcl »tendu)
# MAIS ATTENTION : VERIFIER L"AUTOCHARGEMENT 
# if {"[info proc infox]" == ""} {return}

# lassign {1 2 3 4}   t(v1) t(v2) : set t(v1) 1; set t(v2) 2; return {3 4}
# lassign {1 2}   v1 v2 v3        : set v1 1; set v2 2; set v3 {}; return {}
if {"[info proc infox]" == ""} {
proc lassign {list args} {
  set i 0
  foreach varName $args {
    upvar $varName var
    set var [lindex $list $i]
    incr i
  }
  return [lrange $list $i end]
}
}
# lvarpop <list> ?indexExpr? ?substituteValue?
# <indexExpr> may contain "end" (index of the last elem) and len (length 
# of the list)
# (but tclx allow only end and len to be in first pos of <indexExpr>)
# 
# Examples:
# set List {A B C D E}
# lvarpop List  => return "A" and List is set to {B C D E}
# lvarpop List 2 "deux" => return "D" and List is set to {B C deux E}
# set List {e0 e1 e2 e3 e4 e5 e6 e7 e8 e9}
# lvarpop List "end - (len/3)"  => return "e6" 
# and List is set to {e0 e1 e2 e3 e4 e5 e7 e8 e9}
if {"[info proc infox]" == ""} {
proc lvarpop {listName args} {
  upvar $listName list
  if {[llength $args] == 0} {
    set idx 0
  } else {
    set idx [lindex $args 0]
    set len [llength $list]
    set end [expr $len-1]
    regsub -all -- "len" $idx $len idx
    regsub -all -- "end" $idx $end idx
    set idx [eval expr $idx]
  }
  set res [lindex $list $idx]
  if {[llength $args] == 2} {
    set list [lreplace $list $idx $idx [lindex $args 1]]
  } else {
    set list [lreplace $list $idx $idx]
  }
  return $res
}
}

# lvarpush <list> <string> ?indexExpr?
# <string> is pushed (inserted) as an element of <list> BEFORE position 
# specified by <indexExpr>
# if the var <list> doesn't exist, it is created.
# <indexExpr> may contain "end" (index of the last elem) and len (length 
# of the list)
# lvarpush <list> <string> end : in tclx insert BEFORE the last elem
# lvarpush <list> <string> len : in tclx insert AFTER the last elem
# (but tclx allow only end and len to be in first pos of <indexExpr>)
# 
# Examples:
# set List {A B C D E}
# lvarpush List "NEW"  => set List to {NEW A B C D E}
# lvarpush List "NEW2" len => set List to {NEW A B C D E NEW2}
# set List {e0 e1 e2 e3 e4 e5 e6 e7 e8}
# lvarpush List NEW3 len/2   ;# 9/2 -> 4
# => set List to {e0 e1 e2 e3 NEW3 e4 e5 e7 e8 e9}
if {"[info proc infox]" == ""} {
proc lvarpush {listName str args} {
  upvar $listName list
  if {![info exists list]} {set list {}}
  if {[llength $args] == 0} {
    set idx 0
  } else {
    set idx [lindex $args 0]
    set idx [lindex $args 0]
    set len [llength $list]
    set end [expr $len-1]
    regsub -all -- "len" $idx $len idx
    regsub -all -- "end" $idx $end idx
    set idx [eval expr $idx]
  }
  set list [linsert $list $idx $str]
  return
}
}

if {"[info proc infox]" == ""} {
# lempty <list>  => return 1 if <list> is empty, 0 otherwise
# one can use insteed : if ![llength $my_list]   {...}
# insteed of :          if [lempty $my_list]     {...}
proc lempty {  l  } {
    return [string match 0 [llength $l]]
}
# tclx : 
# lvarcat <listName> <list1> <list2> <list3> ...
# modify the list <listName> by concataining all <listi> after listName.
# if <listName> doesn't exist, it is created.
# return the modified list value.
proc lvarcat {listName args} {
    upvar $listName list
    if {![info exist list]} {set list {}}
    foreach lst $args {
        append list " $lst"
    }
    return $list
}
# min  -10 2 5 4   => -10
# set List {-10 2 5 4}
# eval min $List    => -10
proc min {x args} {
    foreach i $args {if {$i<$x} {set x $i}}
    return $x
}
proc max {x args} {
    foreach i $args {if {$i>$x} {set x $i}}
    return $x
}
proc avg {args} {
    set sum 0.0
    foreach x $args {set sum [expr $sum+$x]}
    return [expr ($sum+0.0)/[llength $args]]
}
# abs " 1.0 / 10 - 2"      => 1.9
# abs 1.0 / 10 - 2         => 1.9 also
proc abs {args} {
    set res [eval expr $args]
    if {$res<0} {return [expr -$res]} {return $res}
}
} ;# end if ... infox
# VOIR AUSSI lmatch... dans list.tcl
# voir aussi keylget et keylset dans xtcl_keygetset.tcl