#!/bin/sh
# the next line restarts using wish \
exec wish8.0 "$0" -- ${1+"$@"}

# console.tcl --
#
# This code constructs the console window for an application.  It
# can be used by non-unix systems that do not have built-in support
# for shells.
#
# SCCS: @(#) console.tcl 1.44 97/06/20 14:10:12
#
# Copyright (c) 1995-1996 Sun Microsystems, Inc.
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

# TODO: history - remember partially written command

# MODIFIER PAR Maurice DIAMANTINI pour fonctionner sous UNIX
# (en cours de mise au point...)

# tkConsoleInitGlobals --
# 
proc tkConsoleInitGlobals {} {
    global console tcl_platform tcl_interactive
    
    set tcl_interactive 0
    set auto_noexec     0
    
    set console(exe) [info script]
    switch  $tcl_platform(platform) {
      macintosh {
        set console(Meta) "Cmd"
        set console(font) {Monaco 9 normal}
      }
      unix {
        set console(Meta) "Meta"
        set console(font) {courier 11 normal}
      }
      other {
        set console(Meta) "Ctrl"
        set console(font) {courier 9 normal}
      }
    } ;# endswitch
    
} ;# endproc tkConsoleInitGlobals

########################################################################
# Creer par diam :  a ameliorer !
# 
proc ConsoleInterp {cmd args} {
  switch -- $cmd {
    eval {
        uplevel #0 eval $args
    }
    record {
        return [uplevel #0 history add $args exec]
    }
    default {
       error "$cmd : commande inconnue (dans ConsoleInterp)"
    }
  }
  
} ;# endproc ConsoleInterp


# ConsolePutsCmd -- 
# 
# émulation de puts qui redirige les flux stdout et stderr vers 
# le widget text passé en paramètre
proc ConsolePutsCmd {args} {
    global console
    set t console(text)
    
    if {[llength $args] > 3} {
        error "invalid arguments"
    }
    set newline "\n"
    if {[string match "-nonewline" [lindex $args 0]]} {
        set newline ""
        set args [lreplace $args 0 0]
    }
    if {[llength $args] == 1} {
        set chan stdout
        set string [lindex $args 0]$newline
    } else {
        set chan [lindex $args 0]
        set string [lindex $args 1]$newline
    }
    if [regexp (stdout|stderr) $chan] {

        tkConsoleOutput $chan $string
        
    } else {
        tcl_puts -nonewline $chan $string
    }
}
# tkConsoleBuildUI --
# 
proc tkConsoleBuildUI {{interp {}}} {
    global console tcl_platform
    
    set console(interp) $interp
    upvar #0 console(toplevel) t
    
    menu $t.menubar
    if {[string match "" $t]} {
        . conf -menu $t.menubar
    } else {
        $t conf -menu $t.menubar
    }

    $t.menubar add cascade -label File -menu $t.menubar.file -underline 0
    $t.menubar add cascade -label Edit -menu $t.menubar.edit -underline 0

    menu $t.menubar.file -tearoff 0
    $t.menubar.file add command -label "Source..." -underline 0 \
        -command tkConsoleSource
    $t.menubar.file add command -label "Hide Console" -underline 0 \
        -command {wm withdraw .}
    $t.menubar.file add command -label "Quit" \
               -command tkConsoleExit -accel $console(Meta)-Q

    menu $t.menubar.edit -tearoff 0
    $t.menubar.edit add command -label "Cut" -underline 2 \
        -command { event generate $t.text <<Cut>> } \
        -accel "$console(Meta)+X"
    $t.menubar.edit add command -label "Copy" -underline 0 \
        -command { event generate $t.text <<Copy>> } \
        -accel "$console(Meta)+C"
    $t.menubar.edit add command -label "Paste" -underline 1 \
        -command { event generate $t.text <<Paste>> } \
        -accel "$console(Meta)+V"

    if {"$tcl_platform(platform)" == "windows"} {
        $t.menubar.edit add command -label "Delete" -underline 0 \
            -command { event generate $t.text <<Clear>> } \
            -accel "Del"

        $t.menubar add cascade -label Help -menu $t.menubar.help \
            -underline 0
            
        menu $t.menubar.help -tearoff 0
        $t.menubar.help add command -label "About..." \
            -underline 0 \
            -command tkConsoleAbout
    } else {
        $t.menubar.edit add command -label "Clear" -underline 2 \
            -command { event generate $t.text <<Clear>> }
    }

    ####################################################################
    # Création du widget text
    
    text $t.text  \
           -yscrollcommand "$t.sb set" \
           -setgrid true \
           -font $console(font)
                 
    scrollbar $t.sb \
           -command "$t.text yview"
    
    set console(text) $t.text
    set console(scrollbar) $t.sb
    
    pack $console(scrollbar) -side right -fill both
    pack $console(text) -fill both -expand 1 -side left
    
    if {$tcl_platform(platform) == "macintosh"} {
        $t.text configure  -highlightthickness 0
    }

} ;# endproc tkConsoleBuildUI

# tkConsoleMain --
# This procedure constructs and configures the console windows.
#
# Arguments:
#         None.
# 
proc tkConsoleMain {{toplevel ""}} {
    global tcl_platform console
    
    if {[string match . $toplevel] } {
        set console(toplevel) ""
    } else {
        set console(toplevel) $toplevel
        catch {destroy $toplevel}
        toplevel $console(toplevel)
    }
    

# #     if {! [ConsoleInterp eval {set tcl_interactive}]} {
# #         wm withdraw .
# #     }

    tkConsoleInitGlobals
    
    tkConsoleBuildUI
    
    


    tkConsoleBind $console(text)

    ## tiré de BWelch-shell.tcl
    # # Text tags give script output, command errors, command
    # # results, and the prompt a different appearance
    # # $t tag configure prompt -underline true
    # # $t tag configure result -foreground purple
    # # $t tag configure error -foreground red
    # # $t tag configure output -foreground blue

    $console(text) tag configure stderr -foreground red
    $console(text) tag configure stdin -foreground blue

    focus $console(text)
    
    wm protocol . WM_DELETE_WINDOW { wm withdraw . }
    wm title . "Console"
    flush stdout
    $console(text) mark set output [$console(text) index "end - 1 char"]
    tkTextSetCursor $console(text) end
    $console(text) mark set promptEnd insert
    $console(text) mark gravity promptEnd left
    
    tkConsolePrompt
    tkConsoleHistory reset
    
    # Ce qui suit ne doit être exécuté qu'une seule fois
    if {![string length [info command tcl_puts]]} {
        rename puts tcl_puts
        interp alias $console(interp) puts {} ConsolePutsCmd 
    }
}

# tkConsoleSource --
#
# Prompts the user for a file to source in the main interpreter.
#
# Arguments:
# None.

proc tkConsoleSource {} {
    set filename [tk_getOpenFile -defaultextension .tcl -parent . \
                      -title "Select a file to source" \
                      -filetypes {{"Tcl Scripts" .tcl} {"All Files" *}}]
    if {"$filename" != ""} {
            set cmd [list source $filename]
        if [catch {ConsoleInterp eval $cmd} result] {
            tkConsoleOutput stderr "$result\n"
        }
    }
}

# tkConsoleInvoke --
# Processes the command line input.  If the command is complete it
# is evaled in the main interpreter.  Otherwise, the continuation
# prompt is added and more input may be added.
#
# Arguments:
# None.

proc tkConsoleInvoke {args} {
    global console
    set ranges [$console(text) tag ranges input]
    set cmd ""
    if {$ranges != ""} {
        set pos 0
        while {[lindex $ranges $pos] != ""} {
            set start [lindex $ranges $pos]
            set end [lindex $ranges [incr pos]]
            append cmd [$console(text) get $start $end]
            incr pos
        }
    }
    if {$cmd == ""} {
        tkConsolePrompt
    } elseif [info complete $cmd] {
        $console(text) mark set output end
        $console(text) tag delete input
        # set result [ConsoleInterp record $cmd]
        # if {$result != ""} {
        #     $console(text) insert insert "$result\n"
        # }
        if [catch {ConsoleInterp record $cmd} result] {
            tkConsoleOutput stderr "$result\n"
        } else {
            if {$result != ""} {
                $console(text) insert insert "$result\n"
            }
        }
        tkConsoleHistory reset
        tkConsolePrompt
    } else {
        tkConsolePrompt partial
    }
    $console(text) yview -pickplace insert
}

# tkConsoleHistory --
# This procedure implements command line history for the
# console.  In general is evals the history command in the
# main interpreter to obtain the history.  The global variable
# histNum is used to store the current location in the history.
#
# Arguments:
# cmd -        Which action to take: prev, next, reset.

# set histNum 1
proc tkConsoleHistory {cmd} {
    global console
    global histNum
    
    switch $cmd {
        prev {
            incr histNum -1
            if {$histNum == 0} {
                set cmd {history event [expr [history nextid] -1]}
            } else {
                set cmd "history event $histNum"
            }
            if {[catch {ConsoleInterp eval $cmd} cmd]} {
                incr histNum
                return
            }
            $console(text) delete promptEnd end
            $console(text) insert promptEnd $cmd {input stdin}
        }
        next {
            incr histNum
            if {$histNum == 0} {
                set cmd {history event [expr [history nextid] -1]}
            } elseif {$histNum > 0} {
                set cmd ""
                set histNum 1
            } else {
                set cmd "history event $histNum"
            }
            if {$cmd != ""} {
                catch {ConsoleInterp eval $cmd} cmd
            }
            $console(text) delete promptEnd end
            $console(text) insert promptEnd $cmd {input stdin}
        }
        reset {
            set histNum 1
        }
    }
}

# tkConsolePrompt --
# This procedure draws the prompt.  If tcl_prompt1 or tcl_prompt2
# exists in the main interpreter it will be called to generate the 
# prompt.  Otherwise, a hard coded default prompt is printed.
#
# Arguments:
# partial -        Flag to specify which prompt to print.

proc tkConsolePrompt {{partial normal}} {
    global console
    if {$partial == "normal"} {
        set temp [$console(text) index "end - 1 char"]
        $console(text) mark set output end
            if [ConsoleInterp eval "info exists tcl_prompt1"] {
                ConsoleInterp eval "eval \[set tcl_prompt1\]"
            } else {
                tkConsoleOutput -nonewline  "% "
            }
    } else {
        set temp [$console(text) index output]
        $console(text) mark set output end
            if [ConsoleInterp eval "info exists tcl_prompt2"] {
                ConsoleInterp eval "eval \[set tcl_prompt2\]"
            } else {
            tkConsoleOutput -nonewline   "> "
            }
    }
    flush stdout
    $console(text) mark set output $temp
    tkTextSetCursor $console(text) end
    $console(text) mark set promptEnd insert
    $console(text) mark gravity promptEnd left
}

# tkConsoleBind --
# This procedure first ensures that the default bindings for the Text
# class have been defined.  Then certain bindings are overridden for
# the class.
#
# Arguments:
# None.

proc tkConsoleBind {win} {
    global console
    bindtags $win "$win Text . all"

    # Ignore all Alt, Meta, and Control keypresses unless explicitly bound.
    # Otherwise, if a widget binding for one of these is defined, the
    # <KeyPress> class binding will also fire and insert the character,
    # which is wrong.  Ditto for <Escape>.

    bind $win <Alt-KeyPress> {# nothing }
    bind $win <Meta-KeyPress> {# nothing}
    bind $win <Control-KeyPress> {# nothing}
    bind $win <Escape> {# nothing}
    bind $win <KP_Enter> {# nothing}

    bind $win <Tab> {
        tkConsoleInsert %W \t
        focus %W
        break
    }
    bind $win <Meta-q> {
        tkConsoleExit
    }
    bind $win <Meta-L> {
        eval [selection get]
    }
    bind $win <Meta-O> {
        exec $console(exe) &
        # tkConsoleExit
    }
    bind $win <Return> {
        %W mark set insert {end - 1c}
        tkConsoleInsert %W "\n"
        tkConsoleInvoke
        break
    }
    bind $win <Delete> {
        if {[%W tag nextrange sel 1.0 end] != ""} {
            %W tag remove sel sel.first promptEnd
        } else {
            if [%W compare insert < promptEnd] {
                break
            }
        }
    }
    bind $win <BackSpace> {
        if {[%W tag nextrange sel 1.0 end] != ""} {
            %W tag remove sel sel.first promptEnd
        } else {
            if [%W compare insert <= promptEnd] {
                break
            }
        }
    }
    foreach left {Control-a Home} {
        bind $win <$left> {
            if [%W compare insert < promptEnd] {
                tkTextSetCursor %W {insert linestart}
            } else {
                tkTextSetCursor %W promptEnd
            }
            break
        }
    }
    foreach right {Control-e End} {
        bind $win <$right> {
            tkTextSetCursor %W {insert lineend}
            break
        }
    }
    bind $win <Control-d> {
        if [%W compare insert < promptEnd] {
            break
        }
    }
    bind $win <Control-k> {
        if [%W compare insert < promptEnd] {
            %W mark set insert promptEnd
        }
    }
    bind $win <Control-t> {
        if [%W compare insert < promptEnd] {
            break
        }
    }
    bind $win <Meta-d> {
        if [%W compare insert < promptEnd] {
            break
        }
    }
    bind $win <Meta-BackSpace> {
        if [%W compare insert <= promptEnd] {
            break
        }
    }
    bind $win <Control-h> {
        if [%W compare insert <= promptEnd] {
            break
        }
    }
    foreach prev {Control-p Up} {
        bind $win <$prev> {
            tkConsoleHistory prev
            break
        }
    }
    foreach prev {Control-n Down} {
        bind $win <$prev> {
            tkConsoleHistory next
            break
        }
    }
    bind $win <Insert> {
        catch {tkConsoleInsert %W [selection get -displayof %W]}
        break
    }
    bind $win <KeyPress> {
        tkConsoleInsert %W %A
        break
    }
    foreach left {Control-b Left} {
        bind $win <$left> {
            if [%W compare insert == promptEnd] {
                break
            }
            tkTextSetCursor %W insert-1c
            break
        }
    }
    foreach right {Control-f Right} {
        bind $win <$right> {
            tkTextSetCursor %W insert+1c
            break
        }
    }
    bind $win <F9> {
        eval destroy [winfo child .]
        if {$tcl_platform(platform) == "macintosh"} {
            source -rsrc Console
        } else {
            source [file join $tk_library console.tcl]
        }
    }
    bind $win <<Cut>> {
        continue
    }
    bind $win <<Copy>> {
        if {[selection own -displayof %W] == "%W"} {
            clipboard clear -displayof %W
            catch {
                clipboard append -displayof %W [selection get -displayof %W]
            }
        }
        break
    }
    bind $win <<Paste>> {
        catch {
            
            set clip [selection get -displayof %W -selection CLIPBOARD]
            set list [split $clip \n\r]
            tkConsoleInsert %W [lindex $list 0]
            foreach x [lrange $list 1 end] {
                %W mark set insert {end - 1c}
                tkConsoleInsert %W "\n"
                tkConsoleInvoke
                tkConsoleInsert %W $x
            }
        }
        break
    }
    bind $win <ButtonRelease-2> {
        if {!$tkPriv(mouseMoved) || $tk_strictMotif} {
            if {[%W compare insert < promptEnd]} {
                tkTextSetCursor %W end
            }
            event generate %W <<Copy>>
            event generate %W <<Paste>>
        }
        break
    }
}

# tkConsoleInsert --
# Insert a string into a text at the point of the insertion cursor.
# If there is a selection in the text, and it covers the point of the
# insertion cursor, then delete the selection before inserting.  Insertion
# is restricted to the prompt area.
#
# Arguments:
# w -                The text window in which to insert the string
# s -                The string to insert (usually just a single character)

proc tkConsoleInsert {w s} {
    if {$s == ""} {
        return
    }
    catch {
        if {[$w compare sel.first <= insert]
                && [$w compare sel.last >= insert]} {
            $w tag remove sel sel.first promptEnd
            $w delete sel.first sel.last
        }
    }
    if {[$w compare insert < promptEnd]} {
        $w mark set insert end        
    }
    $w insert insert $s {input stdin}
    $w see insert
}

# tkConsoleOutput --
#
# This routine is called directly by ConsolePutsCmd to cause a string
# to be displayed in the console.
#
# Arguments:
# dest -        The output tag to be used: either "stderr" or "stdout".
# string -        The string to be displayed.

proc tkConsoleOutput {dest string} {
    global console
    $console(text) insert output $string $dest
    $console(text) see insert
}

# tkConsoleExit --
#
# This routine is called by ConsoleEventProc when the main window of
# the application is destroyed.  Don't call exit - that probably already
# happened.  Just delete our window.
#
# Arguments:
# None.

proc tkConsoleExit {} {
    destroy .
}

# tkConsoleAbout --
#
# This routine displays an About box to show Tcl/Tk version info.
#
# Arguments:
# None.

proc tkConsoleAbout {} {
    global tk_patchLevel
    tk_messageBox -type ok -message "Tcl for Windows
Copyright \251 1996 Sun Microsystems, Inc.

Tcl [info patchlevel]
Tk $tk_patchLevel"
}


########################################################################
# commande shell utiles :
proc ls {args} {
    eval exec ls $args
} ;# endproc ls

# now initialize the console
# tkConsoleMain .console
tkConsoleMain .
