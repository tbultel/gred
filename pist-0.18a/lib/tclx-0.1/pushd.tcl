package provide tclx 0.1

#
# pushd.tcl --
#
# C-shell style directory stack procs.
#
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
# $Id: pushd.tcl,v 1.1.1.1 1997/03/28 14:49:22 diam Exp $
#------------------------------------------------------------------------------
#

#@package: TclX-directory_stack pushd popd dirs

global TCLXENV(dirPushList) ; set TCLXENV(dirPushList) ""

proc pushd {args} {
    global TCLXENV

    if {![info exist TCLXENV(dirPushList) ]} {
        set TCLXENV(dirPushList) ""
    }
    

    if {[llength $args] > 1} {
        error "bad # args: pushd [dir_to_cd_to]"
    }
    set TCLXENV(dirPushList) [linsert $TCLXENV(dirPushList) 0 [pwd]]

    if {[llength $args] != 0} {
        cd [glob $args]
    }
}

proc popd {} {
    global TCLXENV

    if {[info exist TCLXENV(dirPushList)] \
               && [llength $TCLXENV(dirPushList)]} {
        cd [lvarpop TCLXENV(dirPushList)]
        pwd
    } else {
        error "directory stack empty"
    }
}

proc dirs {} { 
    global TCLXENV
    echo [pwd] $TCLXENV(dirPushList)
}
