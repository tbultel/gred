package provide pist_smtp 0.1
########################################################################
# smtp.tcl
# 
# 
# Historique :
# 
#  26/03/97 (carqueij@ensta.fr) : refonte !
#  09/03/97 (diam) : extrait et modifier de surfit 0.6



########################################################################
# SMTP_Box -- demande les champs pour emettre un email
# 
# 
# 
proc SMTP_Box {uid To From} {
    
    # Normal URL parsing does not apply to mail addresses
    regexp {^([^@]+)@(.*)} $To all user host

    # Construct the composition window

    set p [toplevel .mailto$uid]
    wm title $p "Send Mail to User $user at $host"

    label $p.subjLabel -text "Subject: "
    entry $p.subject -width 40
    grid $p.subjLabel -row 0 -column 0
    grid $p.subject -sticky ew -row 0 -column 1

    label $p.toLabel -text "To: "
    entry $p.to -width 40
    grid $p.toLabel -row 1 -column 0
    grid $p.to -sticky ew -row 1 -column 1
    $p.to insert 0 "$user@$host"

    label $p.ccLabel -text "Cc: "
    entry $p.cc -width 40
    grid $p.ccLabel -row 2 -column 0
    grid $p.cc -sticky ew -row 2 -column 1

    label $p.bodyLabel -text "Message to send:"
    text $p.body
    grid $p.bodyLabel -row 3 -column 0 -columnspan 2 -sticky ew
    grid $p.body -row 4 -column 0 -columnspan 2 -sticky news

    set q [frame $p.ctl]
    grid $q -row 5 -column 0 -columnspan 2 -sticky w
    button $q.send -text "Send Message" \
           -command "SMTP_send $p $user $host $From"
    button $q.cancel -text "Cancel Message" \
           -command "SMTP_cancel $p $user $host"
    grid $q.send $q.cancel -sticky w

    return
}

proc SMTP_send {win user host from} {
    SMTP_sendmail  [$win.to get]  $from  \
         [$win.subject get]  [$win.body get 1.0 end] 0

    destroy $win
}

proc SMTP_cancel {win user host} {
    if {![tk_dialog $win.confirm {Cancel Message?} \
        "Are you sure that you want to cancel sending this message\
        to $user at $host?" {} 1 Yes No]} {
	destroy $win
    }
}

# SMTP_sendmail -- emission d'un email
# 
# 
proc SMTP_sendmail {toList from subject body {trace 0}} {
	set sockid [socket mailhost smtp]
	puts $sockid "HELO mailhost\nMAIL From:<$from>"
	flush $sockid
	set result [gets $sockid]
	if $trace then {
		puts stdout "MAIL From:<$from>\n\t$result"
	}
	
	foreach to $toList {
	    puts $sockid "RCPT To:<$to>"
	    flush $sockid
	}
	set result [gets $sockid]
	if $trace then {
		puts stdout "RCPT To:<$to>\n\t$result"
	}
	puts  $sockid "DATA"
	flush $sockid
	set result [gets  $sockid]
	if $trace then {
		puts stdout "DATA \n\t$result"
	}
	puts  $sockid "From: <$from>"
	puts  $sockid "To: <$to>"
	puts  $sockid "Subject: $subject"
	puts  $sockid "\n"
	foreach line [split $body  "\n"] {
		puts  $sockid "[join $line]"
	}
	puts  $sockid "."
	puts  $sockid "QUIT"
	flush $sockid
	set result [gets  $sockid]
	if $trace then {
		puts stdout "QUIT\n\t$result"
	}
	close $sockid 
	return
}

