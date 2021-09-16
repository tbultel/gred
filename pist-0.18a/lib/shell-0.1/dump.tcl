package provide shell 0.1

# sortie de tkCon.tcl version 0.5 par diam@ensta.fr
# 
## Copyright 1995,1996 Jeffrey Hobbs.  All rights reserved.
## Initiated: Thu Aug 17 15:36:47 PDT 1995
##
## jhobbs@cs.uoregon.edu, http://www.cs.uoregon.edu/~jhobbs/

## dumpvar - outputs variables value(s), whether array or simple.
## Accepts glob style pattern matching for the var names
# OPTS: -nocomplain	don't complain if no vars match something
# Returns:	the values of the variables in a 'source'able form
## 
proc dumpvar args {
  set whine 1
  if [string match \-n* [lindex $args 0]] {
    set whine 0
    set args [lreplace $args 0 0]
  }
  if {$whine && [string match {} $args]} {
    error "wrong \# args: [lindex [info level 0] 0]\
            ?-nocomplain? pattern ?pattern ...?"
  }
  set res {}
  foreach arg $args {
    if {[string comp {} [set vars [uplevel info vars [list $arg]]]]} {
      foreach var [lsort $vars] {
	upvar $var v
	if {[string comp {} [set ix [array names v]]]} {
	  append res "array set $var \{\n"
	  foreach i [lsort $ix] {
	    append res "    [list $i $v($i)]\n"
	  }
	  append res "\}\n"
	} else {
	  append res [list set $var $v]\n
	}
      }
    } elseif $whine {
      append res "\#\# No known variable $arg\n"
    }
  }
  return [string trimr $res \n]
}

## dumpproc - just like dumpvar, but for procs
# Returns:	the value of the procs in 'source'able form
## 
proc dumpproc args {
  set whine 1
  if [string match \-n* [lindex $args 0]] {
    set whine 0
    set args [lreplace $args 0 0]
  }
  if {$whine && [string match {} $args]} {
    error "wrong \# args: [lindex [info level 0] 0]\
             ?-nocomplain? pattern ?pattern ...?"
  }
  set res {}
  foreach arg $args {
    if {[string comp {} [set ps [info proc $arg]]]} {
      foreach p [lsort $ps] {
	set as {}
	foreach a [info args $p] {
	  if {[info default $p $a tmp]} {
	    lappend as [list $a $tmp]
	  } else {
	    lappend as $a
	  }
	}
	append res [list proc $p $as [info body $p]]\n
      }
    } elseif $whine {
      append res "\#\# No known proc $arg\n"
    }
  }
  return [string trimr $res \n]
}

