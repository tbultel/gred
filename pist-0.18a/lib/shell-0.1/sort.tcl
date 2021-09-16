package provide shell 0.1

## s -- 
# 
# From wikit
# 
# Example usage: 
# 

## sort -- 
# 
# From wikit
# 
# sort -integer -decreasing -- numberfile1.txt numberfile2.txt
# 
# 
# Yet again, we have a little program that really does an awful lot.
# Mapping the whole of the functionality is tricky, but we can build
# the core of it and still get something useful. 
# 
proc sort {args} {

    ### Parse the arguments
    set idx [lsearch -exact $args --]
    if {$idx >= 0} {
        set files [lrange $args [expr {$idx+1}] end]
        set opts  [lrange $args 0 [expr {$idx-1}]
    } else {
        # We need to guess which are files and which are options
        set files [list]
        set opts [list]
        foreach arg $args {
            incr idx
            if {[file exists $arg]} {
                set files [lrange $args $idx end]
                break
            } else {
                lappend opts $arg
            }
        }
    }

    ### Read the files
    set lines [list]
    if {[llength $files] == 0} {
        # Read from stdin
        while {[gets stdin line] >= 0} {lappend lines $line}
    } else {
        foreach file $files {
            if {[string equal $file "-"]} {
                set f stdin
                set close 0
            } else {
                set f [open $file r]
                set close 1
            }
            while {[gets $f line] >= 0} {lappend lines $line}
            if {$close} {close $f}
        }
    }

    ### Sort the lines in-place (need 8.3.0 or later for efficiency)
    set lines [eval [list lsort] $opts \
            [lrange [list $lines [set lines {}]] 0 0]]

    ### Write the sorted lines out to stdout
    foreach line $lines {
        puts stdout $line
    }
}
 
 