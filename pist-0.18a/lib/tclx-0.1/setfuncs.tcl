
package provide tclx 0.1


#
# setfuncs --
#
# Perform set functions on lists.  Also has a procedure for removing duplicate
# list entries.
#------------------------------------------------------------------------------
# Copyright 1992-1994 Karl Lehenbauer and Mark Diekhans.
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose and without fee is hereby granted, provided
# that the above copyright notice appear in all copies.  Karl Lehenbauer and
# Mark Diekhans make no representations about the suitability of this
# software for any purpose.  It is provided "as is" without express or
# implied warranty.
#------------------------------------------------------------------------------
# $Id: setfuncs.tcl,v 1.1.1.1 1997/03/28 14:49:23 diam Exp $
#------------------------------------------------------------------------------
#
# Modif 12/06/96 (diam@ensta.fr) : suppression d�pendance de lvarpop
#    et de lempty pour intersect et intersect3, et refonte de lrmdups

#@package: TclX-set_functions union intersect intersect3 lrmdups
if {"[info proc infox]" == "infox"} {return}

#
# return the logical union of two lists, removing any duplicates
#
proc union {lista listb} {
    return [lrmdups [concat $lista $listb]]
}

#
# sort a list, returning the sorted version minus any duplicates
# A REFAIRE EN OPTIMISANT...
# proc lrmdups list {
#     if [lempty $list] {
#         return {}
#     }
#     set list [lsort $list]
#     set last [lvarpop list]
#     lappend result $last
#     foreach element $list {
# 	if {$last != $element} {
# 	    lappend result $element
# 	    set last $element
# 	}
#     }
#     return $result
# }
proc lrmdups list {
    set result {}
    foreach e $list {
        if [info exists ($e)] continue
        set ($e) ""
        lappend result $e
    }
    return [lsort $result]
}

#
# intersect3 - perform the intersecting of two lists, returning a list
# containing three lists.  The first list is everything in the first
# list that wasn't in the second, the second list contains the intersection
# of the two lists, the third list contains everything in the second list
# that wasn't in the first.
#

# proc intersect3 {list1 list2} {
#     set list1Result ""
#     set list2Result ""
#     set intersectList ""
# 
#     set list1 [lrmdups $list1]
#     set list2 [lrmdups $list2]
# 
#     while {1} {
#         if [lempty $list1] {
#             if ![lempty $list2] {
#                 set list2Result [concat $list2Result $list2]
#             }
#             break
#         }
#         if [lempty $list2] {
# 	    set list1Result [concat $list1Result $list1]
#             break
#         }
#         set compareResult [string compare [lindex $list1 0] [lindex $list2 0]]
# 
#         if {$compareResult < 0} {
#             lappend list1Result [lvarpop list1]
#             continue
#         }
#         if {$compareResult > 0} {
#             lappend list2Result [lvarpop list2]
#             continue
#         }
#         lappend intersectList [lvarpop list1]
#         lvarpop list2
#     }
#     return [list $list1Result $intersectList $list2Result]
# }
# 
# #
# # intersect - perform an intersection of two lists, returning a list
# # containing every element that was present in both lists
# #
# proc intersect {list1 list2} {
#     set intersectList ""
# 
#     set list1 [lsort $list1]
#     set list2 [lsort $list2]
# 
#     while {1} {
#         if {[lempty $list1] || [lempty $list2]} break
# 
#         set compareResult [string compare [lindex $list1 0] [lindex $list2 0]]
# 
#         if {$compareResult < 0} {
#             lvarpop list1
#             continue
#         }
# 
#         if {$compareResult > 0} {
#             lvarpop list2
#             continue
#         }
# 
#         lappend intersectList [lvarpop list1]
#         lvarpop list2
#     }
#     return $intersectList
# }
proc intersect3 {list1 list2} {
    set list1Result ""
    set list2Result ""
    set intersectList ""

    set list1 [lrmdups $list1]
    set list2 [lrmdups $list2]

    while {1} {
        if ![llength $list1] {
            if [llength $list2] {
                set list2Result [concat $list2Result $list2]
            }
            break
        }
        if ![llength $list2] {
	    set list1Result [concat $list1Result $list1]
            break
        }
        set compareResult [string compare [lindex $list1 0] [lindex $list2 0]]

        if {$compareResult < 0} {
            # # lappend list1Result [lvarpop list1] ;# VIRER lvarpop
            lappend list1Result [lindex $list1 0]
            set list1 [lrange $list1 1 end]
            continue
        }
        if {$compareResult > 0} {
            # # lappend list2Result [lvarpop list2] ;# VIRER lvarpop
            lappend list2Result [lindex $list2 0]
            set list2 [lrange $list2 1 end]
            continue
        }
        # # lappend intersectList [lvarpop list1]
        lappend intersectList [lindex $list1 0]
        set list1 [lrange $list1 1 end]
        # # lvarpop list2
        set list2 [lrange $list2 1 end]
    }
    return [list $list1Result $intersectList $list2Result]
}

#
# intersect - perform an intersection of two lists, returning a list
# containing every element that was present in both lists
#
proc intersect {list1 list2} {
    set intersectList ""

    set list1 [lsort $list1]
    set list2 [lsort $list2]

    while {1} {
        if {![llength $list1] || ![llength $list2]} break

        set compareResult [string compare [lindex $list1 0] [lindex $list2 0]]

        if {$compareResult < 0} {
            # # lvarpop list1
            set list1 [lrange $list1 1 end]
            continue
        }

        if {$compareResult > 0} {
            # # lvarpop list2
            set list2 [lrange $list2 1 end]
            continue
        }

        # # lappend intersectList [lvarpop list1]
        lappend intersectList [lindex $list1 0]
        set list1 [lrange $list1 1 end]
        # # lvarpop list2
        set list2 [lrange $list2 1 end]
    }
    return $intersectList
}


