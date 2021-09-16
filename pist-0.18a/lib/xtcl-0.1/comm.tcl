#
# $Id: comm.tcl,v 1.1.1.1 1997/03/28 14:49:24 diam Exp $
#
# Copyright (C) 1996 Open Software Foundation, Inc.   All Rights Reserved.
# (Please see the file "COPYRIGHT" from the source distribution,
#  or http://www.osf.org/www/dist_client/caubweb/COPYRIGHT.html)
#

package provide Comm 2.3

#	comm works just like Tk's send, except that it uses sockets.
#	These commands work just like "send" and "winfo interps":
#
#		comm send ?-async? id cmd ?arg...?
#		comm interps
#
#	See the manual page comm.n for further details on this package.
#

###############################################################################
#
# Public methods
#

proc comm {cmd args} {
    global comm
    set chan comm
    switch -glob $cmd \
    send { return [eval commSend $args] } \
    conn* { return [eval commConnect $args] } \
    self { return $comm($chan,port) } \
    interp* {
	set res $comm($chan,port)
	foreach {i id} [array get comm $chan,fids,*] {lappend res $id}
	return $res
    } \
    chan* - ids { return $comm(chans) } \
    new { return [eval commNew $args] } \
    init { return [eval commInit $args] } \
    shut* { return [eval commShutdown $args] } \
    abort { return [eval commAbort $args] } \
    destroy { return [eval commDestroy $args] } \
    hook { return [eval commHook $args] } \
    remoteid {
	if [info exists comm($chan,remoteid)] {
	    return $comm($chan,remoteid)
	}
	error "No remote commands processed yet"
    } \
    error "bad option \"$cmd\": should be [join [lsort {send connect self interps channels new init shutdown abort destroy}] ", "]"
}

###############################################################################
#
# Use this to replace "send" and "winfo interps"
#

proc comm_send {} {
    proc send {args} {
	eval comm send $args
    }
    rename winfo tk_winfo
    proc winfo {cmd args} {
	if ![string match in* $cmd] {return [eval [list tk_winfo $cmd] $args]}
	return [comm interps]
    }
    proc comm_send {} {}
}

###############################################################################
#
# Private and internal methods
#
# Do not call or alter any procs or variables from here down
#

if ![info exists comm] {
    array set comm {
	debug 0 chans comm localhost 127.0.0.1
	hook,connecting 0
	hook,connected 0
	hook,incoming 0
	hook,eval 0
	hook,lost 1
    }
}

#
# Class variables:
#	lastport		saves last default listening port allocated 
#	debug			enable debug output
#	chans			list of allocated channels
#
# Instance variables:
# comm()
#	$ch,port		listening port (our id)
#	$ch,socket		listening socket
#	$ch,local		boolean to indicate if port is local
#	$ch,serial		next serial number for commands
#
#	$ch,buf,$fid		buffer to collect incoming data		
#	$ch,result,$serial	reply value set here to wake up sender
#	$ch,pending,$id		list of outstanding send serial numbers for id
#	$ch,peers,$id		open connections to peers; ch,id=>fid
#	$ch,fids,$fid		reverse mapping for peers; ch,fid=>id
#

proc commDebug arg {global comm; if $comm(debug) {uplevel 1 $arg}}

#
# See the Tk send(n) man page for details
#
# Usage: send ?-async? id cmd ?arg arg ...?
#
proc commSend {args} {
    upvar chan chan
    global comm

    if ![info exists comm($chan,port)] {
	return -code error "comm channel $chan not initialized"
    }

    set cmd send
    set i 0
    if [string match -async [lindex $args $i]] {
	set cmd async
	incr i
    }
    set id [lindex $args $i]
    incr i
    set args [lrange $args $i end]
    if ![info complete $args] {
	return -code error "Incomplete command"
    }
    if [string match "" $args] {
	return -code error "wrong # args: should be \"send ?-async? id arg ?arg ...?\""
    }

    set fid [commConnect $id]

    if {[incr comm($chan,serial)] == 0x7fffffff} {set comm($chan,serial) 0}
    set ser $comm($chan,serial)

    commDebug {puts stderr "send <[list [list $cmd $ser $args]]>"}

    # The double list assures that the command is a single list when read.
    puts $fid [list [list $cmd $ser $args]]
    flush $fid

    # wait for reply if so requested
    if [string match send $cmd] {
	upvar comm($chan,pending,$id) pending

	lappend pending $ser
	vwait comm($chan,result,$ser)
	set pos [lsearch -exact $pending $ser]
	set pending [lreplace $pending $pos $pos]

	commDebug {puts stderr "result <$comm($chan,result,$ser)>"}
	after idle unset comm($chan,result,$ser)
	eval [lindex $comm($chan,result,$ser) 0]
    }
}

###############################################################################
#
# Initialize by attaching to listening port
#
proc commNew {ch args} {
    global comm

    if {[lsearch -exact $comm(chans) $ch] >= 0} {
	error "Already existing channel: $ch"
    }
    if [string match comm $ch] {
	# allow comm to be recreated after destroy
    } elseif {![string compare $ch [info proc $ch]]} {
	error "Already existing command: $ch"
    } else {
	regsub "set chan \[^\n\]*\n" [info body comm] "set chan $ch\n" nbody
	proc $ch {cmd args} $nbody
    }
    lappend comm(chans) $ch
    set chan $ch
    eval commInit $args
}

proc commInit {args} {
    upvar chan chan
    global comm
    upvar comm($chan,port) port
    upvar comm($chan,socket) socket
    upvar comm($chan,local) local

    if ![info exists comm($chan,serial)] {set comm($chan,serial) 0}
    set local 1

    set opt 0
    foreach arg $args {
	incr opt
	if [info exists skip] {unset skip; continue}
	switch -exact -- $arg \
	-port	{
	    if {[regexp {[0-9]+} [lindex $args $opt]]} {
		set uport [lindex $args $opt]
	    }
	    set skip 1
	} \
	-local {
	    if {[string match 0 [lindex $args $opt]]} {
		set local 0
	    } else {
		set local 1
	    }
	    set skip 1
	}
    }

    # User is recycling object, possibly to change from insecure to secure
    if [info exists socket] {
	commAbort
	catch {close $socket}
    }

    if ![info exists uport] {
	if ![info exists comm(lastport)] {
	    set comm(lastport) [expr [pid] % 32768 + 10000]
	} else {
	    incr comm(lastport)
	}
	set port $comm(lastport)
    } else {
	set port $uport
    } 
    while 1 {
	set cmd [list socket -server [list commIncoming $chan]]
	if $local {
	    lappend cmd -myaddr $comm(localhost)
	}
	lappend cmd $port
	if ![catch $cmd ret] {
	    break
	}
	if {[info exists uport] || ![string match "*already in use" $ret]} {
	    # don't erradicate the class
	    if ![string match comm $chan] {
		proc $chan {}
	    }
	    error $ret
	}
	set port [incr comm(lastport)]
    }
    set socket $ret

    # If port was 0, system allocated it for us
    if !$port {
	set port [lindex [fconfigure $socket -sockname] 2]
    }
    return $port
}

#
# Destroy the comm instance.
#
proc commDestroy {} {
    upvar chan chan
    global comm
    catch {close $comm($chan,socket)}
    commAbort
    unset comm($chan,port)
    unset comm($chan,local)
    unset comm($chan,socket)
    unset comm($chan,serial)
    set pos [lsearch -exact $comm(chans) $chan]
    set comm(chans) [lreplace $comm(chans) $pos $pos]
    if [string compare comm $chan] {
	rename $chan {}
    }
}

###############################################################################
#
# Called to connect to a remote interp
#
proc commConnect {id} {
    upvar chan chan
    global comm

    commDebug {puts stderr "commConnect $id"}

    if [info exists comm($chan,peers,$id)] {
	return $comm($chan,peers,$id)
    }

    if {[llength $id] > 1} {
	set host [lindex $id 1]
    } else {
	set host $comm(localhost)
    }
    set port [lindex $id 0]
    set fid [socket $host $port]
    commNewConn $id $fid

    # send our id to identify ourselves to remote
    puts $fid $comm($chan,port)
    flush $fid
    return $fid
}

#
# Called for an incoming new connection
#
proc commIncoming {chan fid addr remport} {
    global comm

    commDebug {puts stderr "commIncoming $chan $fid $addr $remport"}

    # remote Id is the first word of first line; rest of line ignored
    set id [lindex [gets $fid] 0]

    if [string compare $comm(localhost) $addr] {
	set id "$id $addr"
    }

    if {[info exists comm($chan,peers,$id)] && $id != $comm($chan,port)} {
	# this can happen when talking to ourself (ok) and
	# when two comms are connecting to each other simaltaneously (bad)
	puts stderr "commIncoming race condition: $id"
    }

    commNewConn $id $fid
}

#
# Common new connection processing
#
proc commNewConn {id fid} {
    upvar chan chan
    global comm

    commDebug {puts stderr "commNewConn $id $fid"}

    if ![info exists comm($chan,peers,$id)] {
	# race condition
	set comm($chan,pending,$id) {}
    	set comm($chan,peers,$id) $fid
    }
    set comm($chan,fids,$fid) $id
    fconfigure $fid -trans binary -blocking 0
    fileevent $fid readable [list commCollect $chan $fid]
}

###############################################################################
#
#
# Close down a peer connection.
#
proc commShutdown {id} {
    upvar chan chan
    global comm

    if [info exists comm($chan,peers,$id)] {
	commLostConn $comm($chan,peers,$id) "Connection shutdown by request"
    }
}

#
# Close down all peer connections
#
proc commAbort {} {
    upvar chan chan
    global comm

    foreach pid [array names comm $chan,peers,*] {
	commLostConn $comm($pid) "Connection aborted by request"
    }
}

# Called to tidy up a lost connection, including aborting ongoing sends
# Each send should clean themselves up in pending/result.
#
proc commLostConn {fid {reason "target application died or connection lost"}} {
    upvar chan chan
    global comm

    commDebug {puts stderr "commLostConn $fid $reason"}

    catch {close $fid}

    set id $comm($chan,fids,$fid)

    foreach s $comm($chan,pending,$id) {
	set comm($chan,result,$s) [list [list return -code error $reason]]
    }
    unset comm($chan,pending,$id)
    unset comm($chan,fids,$fid)
    catch {unset comm($chan,peers,$id)}		;# race condition
    catch {unset comm($chan,buf,$fid)}

    # process lost hook now
    catch {catch $comm($chan,hook,lost)}

    return $reason
}

###############################################################################
#
# Hook support
#

proc commHook {hook {script +}} {
    upvar chan chan
    global comm
    if ![info exists comm(hook,$hook)] {
	error "Unknown hook invoked"
    }
    if !$comm(hook,$hook) {
	error "Unimplemented hook invoked"
    }
    if [string match + $script] {
	if [catch {set comm($chan,hook,$hook)} ret] {
	    return ""
	}
	return $ret
    }
    if [string match +* $script] {
	append comm($chan,hook,$hook) \n [string range $script 1 end]
    } else {
	set comm($chan,hook,$hook) $script
    }
}

# compat with 2.2
proc commLostHook script {
    set chan comm
    commHook lost $script
}

###############################################################################
#
# Called from the fileevent to read from fid and append to the buffer.
# This continues until we get a whole command, which we then invoke.
#
proc commCollect {chan fid} {
    global comm
    upvar #0 comm($chan,buf,$fid) data

    set nbuf [read $fid]
    if [eof $fid] {
	fileevent $fid readable {}		;# be safe
	commLostConn $fid
	return
    }
    append data $nbuf

    commDebug {puts stderr "collect <$data>"}

    # If data contains at least one complete command, we will
    # be able to take off the first element, which is a list holding
    # the command.  This is true even if data isn't a well-formed
    # list overall, with unmatched open braces.  This works because
    # each command in the protocol ends with a newline, this allowing
    # lindex and lreplace to work.
    while {![catch {set cmd [lindex $data 0]}]} {
	commDebug {puts stderr "cmd <$data>"}
	if [string match "" $cmd] break
	if [info complete $cmd] {
	    set data [lreplace $data 0 0]
	    after idle [list commExec $chan $fid $cmd]
	}
    }
}

#
# Recv and execute a remote command, returning the result and/or error
#
# buffer should contain:
#	send # {cmd}		execute cmd and send reply with serial #
#	async # {cmd}		execute cmd but send no reply
#	reply # {cmd}		execute cmd as reply to serial #
#
# Unknown commands are silently discarded
#
proc commExec {chan fid buf} {
    commDebug {puts stderr "exec <$buf>"}

    set cmd [lindex $buf 0]
    set ser [lindex $buf 1]
    set buf [lrange $buf 2 end]
    switch -- $cmd \
	reply {
	    global comm
	    set comm($chan,result,$ser) $buf
	    return
	} \
	send - async {} \
	default return

    commDebug {puts stderr "exec2 <$buf>"}

    # Only valid when immediately retrieved
    global comm
    set comm($chan,remoteid) $comm($chan,fids,$fid)

    # exec command
    set err [catch [concat uplevel #0 [lindex $buf 0]] ret]

    commDebug {puts stderr "res <$err,$ret>"}

    # The double list assures that the command is a single list when read.
    if [string match send $cmd] {
	# catch return in case we just lost target.  consider:
	#	comm send $other comm send [comm self] exit
	catch {
	    # send error or result
	    if {$err == 1} {
		global errorInfo
		puts $fid [list [list reply $ser [list return \
				    -code $err -errorinfo $errorInfo $ret]]]
	    } else {
		puts $fid [list [list reply $ser [list return $ret]]]
	    }
	    flush $fid
	}
    }
}

###############################################################################
#
# Finish creating "comm" using the default port for this interp.
#
comm init

if [string match macintosh $tcl_platform(platform)] {
    set comm(localhost) [lindex [fconfigure $comm(comm,socket) -sockname] 0]
}

#eof
