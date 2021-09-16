#
# $Id: proc.tcl,v 1.1.1.1 1997/03/28 14:49:24 diam Exp $
# 
# Copyright (C) 1996 Open Software Foundation, Inc.   All Rights Reserved.
# (Please see the file "COPYRIGHT" from the source distribution,
#  or http://www.osf.org/www/dist_client/caubweb/COPYRIGHT.html)
#

# This is an alias to "proc" that makes no alterations to the body.
interp alias {} tcl_proc {} proc

# If you don't have Tcl7.5, use this:
#	tcl_proc proc {proc argv body} {proc $proc $argv $body}

#
# Version of "info args" that returns a result suitable for inclusion in
# a proc command, taking care to handle default args.
#
proc proc_info_args {proc} {
    set formals {}
    foreach arg [info args $proc] {
        if [info default $proc $arg def] {
            lappend formals [list $arg $def]
        } else {
            lappend formals $arg
        }
    }
    return $formals
}

#
# Clone/alias args and body of oldproc onto newproc
#
proc proc_clone {oldproc newproc} {
    tcl_proc $newproc [proc_info_args $oldproc] [info body $oldproc]
}
proc proc_alias {oldproc newproc} {
    interp alias {} $newproc {} $oldproc
}

#
# Replace the body of proc
#
proc proc_body_new {proc body} {
    tcl_proc $proc [proc_info_args $proc] $body
}

#
# Prepend additional code to the body of proc
#
proc proc_body_prepend {proc body} {
    tcl_proc $proc [proc_info_args $proc] [append body \n [info body $proc]]
}

#
# Append additional code to the body of proc
#
proc proc_body_append {proc body} {
    set nbody [info body $proc]
    tcl_proc $proc [proc_info_args $proc] [append nbody \n $body]
}

#
# Setup to count proc invocations
#
proc proc_counts {} {
    global procPriv
    # First, markup all existing procs
    foreach proc [info procs] {
        set procPriv($proc) 0
	proc_body_prepend $proc "global procPriv; incr procPriv($proc)"
    }
    # Next, unalias tcl_proc so that we can redefine proc
    interp alias {} tcl_proc {}
    rename proc tcl_proc
    # Next, redo "proc" to add counting to any new procs
    tcl_proc proc {proc argv body} {
        global procPriv
        set procPriv($proc) 0
        tcl_proc $proc $argv \
		[concat "global procPriv; incr procPriv($proc);" $body]
    }
    # Next, null ourselves out - we don't want to be called more than once
    tcl_proc proc_counts {} {}
}

#eof
