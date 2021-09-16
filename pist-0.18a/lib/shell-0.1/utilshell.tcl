package provide shell 0.1

# Certaine de ces procédures sont de Jeffrey Hobbs soit telle quelle, 
# soit plus ou moins profondement refondues :
## Copyright 1995,1996 Jeffrey Hobbs.  All rights reserved.
## jhobbs@cs.uoregon.edu, http://www.cs.uoregon.edu/~jhobbs/


## alias - akin to the csh alias command
## If called with no args, then it prints out all current aliases
## If called with one arg, returns the alias of that arg (or {} if none)
# ARGS:	newcmd	- (optional) command to bind alias to
# 	args	- command and args being aliased
## 
proc alias {{newcmd {}} args} {
  if [string match {} $newcmd] {
    set res {}
    foreach a [interp aliases] {
      lappend res [list $a: [interp alias {} $a]]
    }
    return [join $res \n]
  } elseif {[string match {} $args]} {
    interp alias {} $newcmd
  } else {
    eval interp alias {{}} $newcmd {{}} $args
  }
}

## unalias - unaliases an alias'ed command
# ARGS:	cmd	- command to unbind as an alias
## 
proc unalias {cmd} {
  interp alias {} $cmd {}
}

## which - tells you where a command is found
# ARGS:	cmd	- command name
# Returns:	where command is found (internal / external / unknown)
## 
proc which cmd {
  if [string comp {} [info commands $cmd]] {
    if {[lsearch -exact [interp aliases] $cmd] > -1} {
      return "$cmd:\taliased to [alias $cmd]"
    } elseif [string comp {} [info procs $cmd]] {
      return "$cmd:\tinternal proc"
    } else {
      return "$cmd:\tinternal command"
    }
  } elseif [auto_execok $cmd] {
    return [auto_execpath $cmd]
  } else {
    return "$cmd:\tunknown command"
  }
}

# dir --
# 
# Auteur : Jeffrey Hobbs (de console v1.51 de Mega widget 1.0)
## dir - directory list
# ARGS:	args	- names/glob patterns of directories to list
# OPTS:	-all	- list hidden files as well (Unix dot files)
#	-long	- list in full format "permissions size date filename"
#	-full	- displays / after directories and link paths for links
# Returns:	a directory listing
## 
proc dir {args} {
    array set s {
	all 0 full 0 long 0
	0 --- 1 --x 2 -w- 3 -wx 4 r-- 5 r-x 6 rw- 7 rwx
    }
    while {[string match \-* [lindex $args 0]]} {
	set str [lindex $args 0]
	set args [lreplace $args 0 0]
	switch -glob -- $str {
	    -a* {set s(all) 1} -f* {set s(full) 1}
	    -l* {set s(long) 1} -- break
	    default {
		return -code error "unknown option \"$str\",\
			should be one of: -all, -full, -long"
	    }
	}
    }
    set sep [string trim [file join . .] .]
    if {[string match {} $args]} { set args . }
    foreach arg $args {
	if {[file isdir $arg]} {
	    set arg [string trimr $arg $sep]$sep
	    if {$s(all)} {
		lappend out [list $arg [lsort [glob -nocomplain -- $arg.* $arg*]]]
	    } else {
		lappend out [list $arg [lsort [glob -nocomplain -- $arg*]]]
	    }
	} else {
	    lappend out [list [file dirname $arg]$sep \
		    [lsort [glob -nocomplain -- $arg]]]
	}
    }
    if {$s(long)} {
	set old [clock scan {1 year ago}]
	set fmt "%s%9d %s %s\n"
	foreach o $out {
	    set d [lindex $o 0]
	    append res $d:\n
	    foreach f [lindex $o 1] {
		file lstat $f st
		set f [file tail $f]
		if {$s(full)} {
		    switch -glob $st(type) {
			d* { append f $sep }
			l* { append f "@ -> [file readlink $d$sep$f]" }
			default { if {[file exec $d$sep$f]} { append f * } }
		    }
		}
		if {[string match file $st(type)]} {
		    set mode -
		} else {
		    set mode [string index $st(type) 0]
		}
		foreach j [split [format %o [expr $st(mode)&0777]] {}] {
		    append mode $s($j)
		}
		if {$st(mtime)>$old} {
		    set cfmt {%b %d %H:%M}
		} else {
		    set cfmt {%b %d  %Y}
		}
		append res [format $fmt $mode $st(size) \
			[clock format $st(mtime) -format $cfmt] $f]
	    }
	    append res \n
	}
    } else {
	foreach o $out {
	    set d [lindex $o 0]
	    append res $d:\n
	    set i 0
	    foreach f [lindex $o 1] {
		if {[string len [file tail $f]] > $i} {
		    set i [string len [file tail $f]]
		}
	    }
	    set i [expr {$i+2+$s(full)}]
	    ## This gets the number of cols in the Console console widget
	    set j [expr {66/$i}]
	    set k 0
	    foreach f [lindex $o 1] {
		set f [file tail $f]
		if {$s(full)} {
		    switch -glob [file type $d$sep$f] {
			d* { append f $sep }
			l* { append f @ }
			default { if {[file exec $d$sep$f]} { append f * } }
		    }
		}
		append res [format "%-${i}s" $f]
		if {[incr k]%$j == 0} {set res [string trimr $res]\n}
	    }
	    append res \n\n
	}
    }
    return [string trimr $res]
}
# interp alias {} ls {} dir -full
