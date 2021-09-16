# Fichier Shell.tcl 
# 
# modif $Id: shell.tcl,v 1.1 1997/10/14 06:52:28 diam Exp $
#
# Conçu à l'origine par SUN (en librairie tk8.0) pour utilisation
# sous MacOS et windoze par :
#     Copyright (c) 1995-1996 Sun Microsystems, Inc.
#     (dont B. WELCH)
# et modifier pour fonctionner sous unix par :
#    Maurice DIAMANTINI (diam@ensta.fr)
#    $Id: shell.tcl,v 1.1 1997/10/14 06:52:28 diam Exp $
# 
# Utilisation pour créer une toplevel séparée :
#    Shell .console
# Utilisation en temps que fenêtre principale :
#    Shell .
# 
# EFFETS DE BORD de ce package :
# 
# La commande tcl "puts" originale est renommée "tcl_puts"
# et une nouvelle procédure "puts" permet de rediriger les flux stdout 
# et stderr vers la console
# 
########################################################################

package provide shell 0.1

# Shell -- lance la console TCL
# 
proc Shell {{toplevel .console}} {
    console_Init $toplevel
} ;# endproc console


# console_InitGlobals --
# 
proc console_InitGlobals {} {
    global console tcl_platform tcl_interactive
    
    set tcl_interactive 1
    set auto_noexec     1
    
    # set console(exe) [info script]
    # if {[file pathtype $console(exe)] == "relative"} {
    #    set console(exe) [file join [pwd] $console(exe)]
    # }
    
    switch  $tcl_platform(platform) {
      macintosh {
        set console(Meta) "Cmd"
        set console(font) {Monaco 9 normal}
      }
      unix {
        set console(Meta) "Meta"
        set console(font) {courier 11 normal}
        set console(font) {lucidatypewriter 11 normal}
      }
      other {
        set console(Meta) "Ctrl"
        set console(font) {courier 9 normal}
      }
    } ;# endswitch
    
    set console(width)  90
    set console(height) 40
    
} ;# endproc console_InitGlobals


# console_PutsCmd -- 
# 
# émulation de puts qui redirige les flux stdout et stderr vers 
# le widget text passé en paramètre
# Suppose que la commande originale "puts" est renommée en "tcl_puts"
# 
proc console_PutsCmd {args} {
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
        set channel stdout
        set string [lindex $args 0]$newline
    } else {
        set channel [lindex $args 0]
        set string [lindex $args 1]$newline
    }
    if [regexp (stdout|stderr) $channel] {

        console_Output $channel $string
        
    } else {
        tcl_puts -nonewline $channel $string
    }
}
# console_BuildUI --
# 
proc console_BuildUI {{interp {}}} {
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
    $t.menubar.file add command -label "Source..."  \
        -command console_Source
    $t.menubar.file add command -label "Hide Console"  \
        -command {wm withdraw .}
    $t.menubar.file add command -label "Quit" \
               -command console_Exit -accel $console(Meta)-Q

    menu $t.menubar.edit -tearoff 0
    $t.menubar.edit add command -label "Cut"  \
        -command { event generate $console(text) <<Cut>> } \
        -accel "$console(Meta)+X"
    $t.menubar.edit add command -label "Copy"  \
        -command { event generate $console(text) <<Copy>> } \
        -accel "$console(Meta)+C"
    $t.menubar.edit add command -label "Paste"  \
        -command { event generate $console(text) <<Paste>> } \
        -accel "$console(Meta)+V"


    $t.menubar.edit add command -label "Clear"  \
        -command { event generate $console(text) <<Clear>> }

    $t.menubar add cascade -label Help -menu $t.menubar.help 
        
    menu $t.menubar.help -tearoff 0
    $t.menubar.help add command -label "About..." \
        -underline 0 \
        -command console_About
            

    ####################################################################
    # Création du widget text
    
    text $t.text  \
           -yscrollcommand "$t.sb set" \
           -setgrid true \
           -width $console(width) \
           -height $console(height) \
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

} ;# endproc console_BuildUI

# console_Init --
# This procedure constructs and configures the console windows.
#
# A FAIRE : gérer plus d'options (-interp, -title,...)
# Arguments:
#         None.
# 
proc console_Init {{toplevel ""}} {
    global tcl_platform console
    
    if {[string match . $toplevel] } {
        set console(toplevel) ""
    } else {
        set console(toplevel) $toplevel
        catch {destroy $toplevel}
        toplevel $console(toplevel)
    }
    
    console_InitGlobals
    
    console_BuildUI

    console_Bind $console(text)

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
    if [string match "" "$console(toplevel)"] {
        wm title . "Console"
    } else {
        wm title $console(toplevel) "Console"
    }

    $console(text) mark set output [$console(text) index "end - 1 char"]
    tkTextSetCursor $console(text) end
    $console(text) mark set promptEnd insert
    $console(text) mark gravity promptEnd left
    
    console_Prompt
    console_History reset
    
    flush stdout
    # Ce qui suit ne doit être exécuté qu'une seule fois
    if {![string length [info command tcl_puts]]} {
        rename puts tcl_puts
        interp alias $console(interp) puts {} console_PutsCmd 
    }
}

# console_Source --
#
# Prompts the user for a file to source in the main interpreter.
#
# Arguments:
# None.

proc console_Source {} {
    set filename [tk_getOpenFile -defaultextension .tcl -parent . \
                      -title "Select a file to source" \
                      -filetypes {{"Tcl Scripts" .tcl} {"All Files" *}}]
    if {"$filename" != ""} {
            set cmd [list source $filename]
        if [catch {console_Eval $cmd} result] {
            console_Output stderr "$result\n"
        }
    }
}

# console_GetInput --
# 
# Retourne le texte tapé par l'utilisateur dans la console 
# (i.e. ce qui a le tag input)
# 
proc console_GetInput {} {
   global console

    set ranges [$console(text) tag ranges input]
    set cmd ""
    # if {$ranges != ""} {}
    if {[llength $ranges]} {
        set pos 0
        while {[lindex $ranges $pos] != ""} {
            set start [lindex $ranges $pos]
            set end [lindex $ranges [incr pos]]
            append cmd [$console(text) get $start $end]
            incr pos
        }
    }
    return $cmd
} ;# endproc console_GetInput

# console_Return --
# 
# Insertion d'un <Return> en fin de console, puis invocation de l'éxécution 
# du texte tapé
# 
proc console_Return {} {
   global console
   $console(text) mark set insert {end - 1c}
   console_Insert $console(text) "\n"
   console_Invoke
} ;# endproc console_Return


########################################################################
# 
# console_Eval --
# 
# Traite la chaine passée  en paramètre comme une commande à exécuter
# Par défaut, cette procédure considère que c'est du TCL à exècuter,
# mais cette procédure peut être redéfinie pour faire n'ímporte quoi.
# 
# 
proc console_Eval {oneCmd} {
  global console
  # # Exemple de traitement possible de commande
  # set firstWord [lindex $oneCmd 0]
  # switch -exact -- $firstWord {
  #     exec  -
  #     pwd   -
  #     cd    -
  #     ls { # Commande TCL à évaluer
  #         report "COMMANDE TCL A EXECUTER"
  #         return [uplevel #0 $string]
  #     }
  #     default { # commande VME à envoyer 
  #         report "COMMANDE VME A EXECUTER"
  #         vme_send $string
  #     }
  # }
  
  # Pour exécuter une commande TCL dans l'interpréteur courant :
  return [uplevel #0  $oneCmd]
  
  # Pour un interpréteur du m^eme processus
  # return [interp eval $console(interp)  $oneCmd]
  
  # Pour un interpréteur d'un autre processus (gredw)
  # return [send $console(interp)  $oneCmd]
  
} ;# endproc console_Eval

# console_Invoke --
# 
# Processes the command line input.  If the command is complete it
# is evaled in the main interpreter.  Otherwise, the continuation
# prompt is added and more input may be added.
#
# Arguments:
# None.

proc console_Invoke {args} {
    global console
    
    set cmd [console_GetInput]
    if {$cmd == ""} {
        console_Prompt
    } elseif [info complete $cmd] {
        $console(text) mark set output end
        $console(text) tag delete input
        
        uplevel #0 [list history add $cmd]
        if [catch {console_Eval $cmd} result] {
            console_Output stderr "$result\n"
        } else {
            if {$result != ""} {
                $console(text) insert insert "$result\n"
            }
        }

        console_History reset
        console_Prompt
    } else {
        console_Prompt partial
    }
    $console(text) yview -pickplace insert
}

# console_History --
# This procedure implements command line history for the
# console.  In general is evals the history command in the
# main interpreter to obtain the history.  The global variable
# histNum is used to store the current location in the history.
#
# Arguments:
# cmd -        Which action to take: prev, next, reset.

# set histNum 1
proc console_History {cmd} {
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
            if {[catch {console_Eval $cmd} cmd]} {
                incr histNum
                return
            }
            $console(text) delete promptEnd end
            $console(text) insert promptEnd $cmd {input stdin}
            $console(text) mark set insert end-1c
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
                catch {console_Eval $cmd} cmd
            }
            $console(text) delete promptEnd end
            $console(text) insert promptEnd $cmd {input stdin}
            $console(text) mark set insert end-1c
        }
        reset {
            set histNum 1
        }
    }
}

# console_Prompt --
# This procedure draws the prompt.  If tcl_prompt1 or tcl_prompt2
# exists in the main interpreter it will be called to generate the 
# prompt.  Otherwise, a hard coded default prompt is printed.
#
# Arguments:
# partial -        Flag to specify which prompt to print.

proc console_Prompt {{partial normal}} {
    global console
    if {$partial == "normal"} {
        set temp [$console(text) index "end - 1 char"]
        $console(text) mark set output end
        if [console_Eval "info exists tcl_prompt1"] {
            console_Eval "eval \[set tcl_prompt1\]"
        } else {
            console_Output -nonewline  "% "
            # ERREUR ? IL FAUDRAIT :
            # console_Output stdout  "% "
        }
    } else {
        set temp [$console(text) index output]
        $console(text) mark set output end
        if [console_Eval "info exists tcl_prompt2"] {
            console_Eval "eval \[set tcl_prompt2\]"
        } else {
            console_Output -nonewline   "> "
            # ERREUR ? IL FAUDRAIT :
            # console_Output stdout  "> "
        }
    }
    flush stdout
    $console(text) mark set output $temp
    tkTextSetCursor $console(text) end
    $console(text) mark set promptEnd insert
    $console(text) mark gravity promptEnd left
}

# console_DeleteSel --
proc console_DeleteSel {w} {
    if {[$w tag nextrange sel 1.0 end] != ""} {
        $w tag remove sel sel.first promptEnd
        if {[$w tag nextrange sel 1.0 end] != ""} {
            $w delete sel.first sel.last
        }
    }
} ;# endproc console_DeleteSel


# console_Cut --
proc console_Cut {w} {
    event generate $w <<Copy>>
    event generate $w <<Clear>>
} ;# endproc console_Cut


# console_Copy --
proc console_Copy {w} {
    
    if {[catch {set selText [selection get -displayof $w]}]} {
       return
    }
    if {[selection own -displayof $w] == "$w"} {
        clipboard clear -displayof $w
        catch {
            clipboard append -displayof $w $selText
        }
    } else {
        clipboard clear -displayof $w
        catch {
            clipboard append -displayof $w $selText
        }
    }
} ;# endproc console_Copy

# console_Paste --
proc console_Paste {w} {
    
    catch {
        set clip [selection get -displayof $w -selection CLIPBOARD]
        set list [split $clip \n\r]
        console_Insert $w [lindex $list 0]
        foreach oneCmd [lrange $list 1 end] {
            console_Return 
            console_Insert $w $oneCmd
        }
    }
} ;# endproc console_Paste


# console_DuplicateSel --
proc console_DuplicateSel {w} {
    
    catch {console_Insert $w [selection get -displayof $w]}

} ;# endproc console_DuplicateSel



# console_Insert --
# Insert a string into a text at the point of the insertion cursor.
# The selected text IS NOT removed : one should use console_DeleteSel
# ih we one so
# Insertion is restricted to the prompt area.
#
# Arguments:
# w -                The text window in which to insert the string
# s -                The string to insert (usually just a single character)

proc console_Insert {w s} {
    if {$s == ""} {
        return
    }
    # debut ancien catch 
    if {[$w tag nextrange sel 1.0 end] != "" \
            && [$w compare sel.first <= insert]
            && [$w compare sel.last >= insert]} {
        $w tag remove sel sel.first promptEnd
        # $w delete sel.first sel.last
    }
    # fin ancien catch 
    
    if {[$w compare insert < promptEnd]} {
        $w mark set insert end        
    }
    $w insert insert $s {input stdin}
    $w see insert
}

# console_Output --
#
# This routine is called directly by console_PutsCmd to cause a string
# to be displayed in the console 9at the "output" mark).
#
# Arguments:
# channelTag -    The output tag to be used: either "stderr" or "stdout".
# string -        The string to be displayed.

proc console_Output {channelTag string} {
    global console
    $console(text) insert output $string $channelTag
    $console(text) see insert
}

# console_Exit --
#
# This routine is called by ConsoleEventProc when the main window of
# the application is destroyed.  Don't call exit - that probably already
# happened.  Just delete our window.
#
# Arguments:
# None.

proc console_Exit {} {
    global console
    
    if {[string match {} $console(toplevel)]} {
       exit
    } else {
       destroy $console(toplevel)
       unset console
    }
}

# console_About --
#
# This routine displays an About box to show Tcl/Tk version info.
#
# Arguments:
# None.

proc console_About {} {
    global tk_patchLevel
    set msg    "Shell TCL par Maurice DIAMANTINI (diam@ensta.fr)\n"
    append msg "    Tcl [info patchlevel]\n"
    append msg "    Tk $tk_patchLevel\n"
    tk_messageBox -type ok  -message $msg
}


########################################################################
# commande shell utiles :
proc ls {args} {
    eval exec ls $args
} ;# endproc ls

########################################################################
# console_Bind --
# This procedure first ensures that the default bindings for the Text
# class have been defined.  Then certain bindings are overridden for
# the class.
#
# Arguments:
# None.

proc console_Bind {win} {
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
        console_Insert %W \t
        focus %W
        break
    }
    bind $win <Meta-L> {
        uplevel #0 [selection get]
    }
    bind $win <Return> {
        console_Return
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
            console_History prev
            break
        }
    }
    foreach prev {Control-n Down} {
        bind $win <$prev> {
            console_History next
            break
        }
    }
    bind $win <Insert> {
        catch {console_Insert %W [selection get -displayof %W]}
        break
    }
    bind $win <$console(Meta)-d> {
        console_DuplicateSel %W
        break
    }
    bind $win <KeyPress> {
        console_Insert %W %A
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
    foreach Cut "<$console(Meta)-x> <<Cut>>" {
        bind $win $Cut {
            console_Cut %W
            break
        }
    }
    foreach Copy "<$console(Meta)-c> <<Copy>>" {
        bind $win $Copy {
            console_Copy %W
            break
        }
    }
    foreach Paste "<$console(Meta)-v> <<Paste>>" {
        bind $win $Paste {
            console_Paste %W
            break
        }
    }
    bind $win <<Clear>> {
        console_DeleteSel %W
        break
    }
    bind $win <ButtonRelease-2> {
        if {!$tkPriv(mouseMoved) || $tk_strictMotif} {
            event generate %W <<Copy>>
            if {[%W compare insert < promptEnd]} {
                tkTextSetCursor %W end
            }
            event generate %W <<Paste>>
        }
        break
    }
}


# now initialize the console
# console_Init .console
# console_Init .
