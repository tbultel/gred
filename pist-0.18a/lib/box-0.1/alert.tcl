# fichier alert.tcl

package provide box 0.1


## proc            tk_dialog {w     title   text bitmap default args} 

proc ask {title msg {OK OK} {Cancel Cancel} } {
    return [expr {[tk_dialog .ask $title $msg question 0 $OK $Cancel] == 0}]
}
#

proc alert {msg {Alert Alert}} { 
     tk_dialog .alert "$Alert" $msg warning   0    OK 
}
#

proc help {args} {
    alert {Sorry not yet implemented!}
}
proc confirmQuit {} {
    if [ask {No Save Quit} {Really quit without saving your lists?}] { exit }
}
# pour surveiller la valeur d'une variable :
proc watch name {
        catch {destroy .watch}
	toplevel .watch
	label .watch.label -text "Value of \"$name\": "
	label .watch.value -textvariable $name
	pack .watch.label .watch.value -side left
}
