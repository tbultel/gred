########################################################################
# fichier pref2.tcl
# Complément au package pref.tcl
# voir documentation et test dans le fichier preftest.
# 
########################################################################

package provide pref 0.2




# La procédure ci-dessous peut etre precharger pour personnaliser
# les textes en fonction de la langue, etc...
# Remarque : si une proc est indentée, elle n'est pas indexé pas auto_index 

# if {[info proc PrefDialogInit] == ""} then {}
if {1} then {
  proc PrefDialogInit {} {
      global pref tcl_platform
  
      # la ligne suivante ne marche pas pour l'instant sous unix
      # mais marche sous MacOS et devrait marcher en tk4.2 :
      # set pref(status,font) [list courier 12 normal]
      option add *font "-*-helvetica-*-r-normal-*-12-*-*-*-*-*-iso8859-*" \
           widgetDefault           
      set pref(status,font) "-*-courier-*-r-normal-*-12-*-*-*-*-*-iso8859-*"
      set pref(status,height) 4

      set pref(done) 0
      set pref(modified) 0
      switch -exact -- $tcl_platform(platform) {
         "macintosh"   {set pref(Meta) "Command"}
     
         default        {set pref(Meta) "Meta"}
      }
      
      set pref(msg,window_title)  "Preferences"
      set pref(msg,icon_title)    "Prefs"
      set pref(msg,button_cancel) "Cancel"
      set pref(msg,button_reset)  "Reset"
      set pref(msg,button_save)   "Save"
      set pref(msg,button_done)   "Done"
      
      set pref(msg,help_button_cancel) "This Cancel button destroy this\
          preference window and keep the last\012validate preferences value."
  
      set pref(msg,help_button_reset) "This button reset the preference\
          values to the default value by resoursing \012the application\
          default file and then the user preerence file."
         
      set pref(msg,help_button_save) "This button validate and save \
          the new preferences values \012in the user file:\
           $pref(userPrefsDefault)"
           
      set pref(msg,help_button_done) "This button validate the new preference\
          values \012but without saving them in the user file "
      set pref(msg,group_label)              "Select a Group Preference"
      set pref(msg,unable_creating_userfile) "Unable creating new user File:"
      set pref(msg,cannot_install)           "Cannot install "
      set pref(msg,user_file_saved_in)       "User file saved in "
  }
}
# Pref_Dialog ?-group groupName? 
# crée la fenètre de dialogue pour afficher les préfs des groupes
# spécifiés (premier groupe par défaut) 
proc Pref_Dialog {args} {
    global pref

    PrefDialogInit

    # init of the param.
    array set arga "
        -group      [list [lindex $pref(groupNames) 0]]
        -groupmode  auto
    "
    array set arga $args        ;# put arguments in array arga
    
    # record the group to display:
    if {[lsearch -exact $pref(groupNames) $arga(-group) ] != -1} {
        set pref(currentGroupName) $arga(-group)
    } else {
        error "Unknowed group name: $arga(-group)"
    } 

    if {[info exist $arga(-groupmode)]} {
        set pref(groupMode) $arga(-groupmode)
    }     

    set pref(toplevel) .pref
    set w $pref(toplevel)
    
    if [catch {toplevel $w -class Pref}] {
        raise $w
        wm deiconify $w
    } else {
        wm title     $w $pref(msg,window_title)
        wm iconname  $w $pref(msg,icon_title)
        wm minsize   $w 0 0
        wm protocol  $w WM_DELETE_WINDOW { }
        # don't work well on Macintosh :
        # wm transient $w [winfo toplevel [winfo parent $w]]
        # bind $w <FocusIn> {set pref(curtop) %w}  ;# from tkmail/options.tk
        wm withdraw  $w

        # create group selector only if there is several groups
        if {[llength $pref(groupNames)] > 1} {
            # Should test the type of group selector (Pref_init option)
            # value are 
            #    "buttons, popup, listbox, auto 
            # auto choose the type itself (based on number of groups ?)
            
            switch -exact -- $pref(groupMode) {
              list     PrefDialogMakeGroupListbox
              popup    PrefDialogMakeGroupPopup
              buttons  PrefDialogMakeGroupButtons
              auto     -
              default  {
                  # choose automaticaly a suitable groupmode based 
                  # on the number of groups:
                  set NbGr [llength $pref(groupNames)]
                  if {$NbGr < 5} {
                      PrefDialogMakeGroupListbox
                  } else {
                      PrefDialogMakeGroupListbox
                  }
              }
            }
        }
        
        PrefDialogMakeStatus      
        PrefDialogMakeButtons      

        # # # Label for current group name
        # # label $w.gname \
        # #         -textvariable pref(currentGroupName)
        # # pack $w.gname -side top -anchor e
        
        # le corps de la fenetre contenant les préférences :
        set body [frame $w.b  -borderwidth 7]
        pack $body -fill both -expand true
        
        foreach gn $pref(groupNames) {
        	
        	# Creating (but not packing) group frames
            set bodyg $body.g[incr pref(uid)]
            set pref(gn$gn,frame) $bodyg
            frame $bodyg -relief raised
            
            # recording max length for comment string :
            set maxWidth 0
            foreach vn $pref(gn$gn,varNames) {
                set len [string length $pref(vn$vn,comment)]
                if {$len > $maxWidth} {set maxWidth $len}
            }
            set pref(gn$gn,commentWidth) $maxWidth
                
        } ;# endforeach
                
        # Filling unpacked group frames 
        # Will be in a separate procedure with "gn" as parameter
        foreach gn $pref(groupNames) {
            set bodyg $pref(gn$gn,frame)
            
            label $bodyg.lbl  -anchor w \
                  -text "$gn :"
            pack $bodyg.lbl -fill both -expand true
            pack [PrefRule $bodyg]  -fill x  

            foreach vn $pref(gn$gn,varNames) {
                PrefDialogItem $bodyg $vn
            }
        }
        
        
        
    }
    # $w is "withdraw" ; we have to update to known the real size
    # of the window (from tk_dialog procedure).
    PrefGroupPack $pref(currentGroupName)
    update idletasks
    set x [expr [winfo screenwidth $w]/2 - [winfo reqwidth $w]/2 \
            - [winfo vrootx [winfo parent $w]]]
    set y [expr [winfo screenheight $w]/2 - [winfo reqheight $w]/2 \
            - [winfo vrooty [winfo parent $w]]]
    wm geom $w +$x+$y
    wm deiconify $w
    
    # Be sure to release any grabs that might be present on the
    # screen, since they could make it impossible for the user
    # to interact with the stack trace.

    if {[grab current .] != ""} {
	grab release [grab current .]
    }
}
# Give the max length of all elem of an array "arrayName" whose indice 
# satisfy "pattern" (PLUS UTILISER => A METTRE DANS array.tcl)
proc ArrayMaxLength {arrayName pattern} {
    upvar arrayName arr
    set MaxLen 0
    foreach idx [array names $arr $pattern] {
        set len [string length $arr($idx)] 
        if {$len > $MaxLen} {set MaxLen $len}
    }
    return $MaxLen
}
# a mettre dans list.tcl
proc ListStringLengthMax {list} {
    set MaxLen 0
    foreach elem $list {
        set len [string length $elem] 
        if {$len > $MaxLen} {set MaxLen $len}
    }
    return $MaxLen
}
proc PrefDialogMakeGroupPopup {} {

    global pref
    set w $pref(toplevel)
    
    # # The groups popmenu :
    # frame $w.groups -fill s -ipady 4m
    # set w 20  ;# A AMELIORER : [PrefMaxLength $list]
    # menubutton $w.groups.mb  -relief raise -width $w\
    #      -textvariable pref(currentGid) \
    #      -menu $w.groups.mb.menu  
    # menu $w.groups.mb.menu -tearoff 0
    # 
    # foreach gName $pref(groupNames) {
    #     $w.groups.mb.menu add radio -label $gName \
    #           -variable pref(currentGid) \
    #           -value $gName
    # }
    #       
    # pack $w.groups -side top -fill x -expand true
    # pack .groups.mb -side left


}
proc PrefDialogMakeGroupListbox {} {

    global pref
    set w $pref(toplevel)
    
    # max size length of group names
    set maxWidth 0
    set maxWidth [ListStringLengthMax $pref(groupNames)]
    
    # create scrolled listbox
    frame $w.groups  -bd 2m
    pack $w.groups  -side left -fill y 
    label $w.groups.lbl -text "$pref(msg,group_label)     "
    pack $w.groups.lbl -side top
    
    set lbx [listbox $w.groups.lbx -width $maxWidth \
                 -yscroll "$w.groups.scr set" \
                 -relief sunken -bd 2\
                 -exportselection false ]

    scrollbar $w.groups.scr -command "$w.groups.lbx yview" \
                  -relief sunken -bd 2
    pack $w.groups.lbx  -side left -fill both -expand true
    pack $w.groups.scr  -side left -fill y
    
    bind $lbx  <Button-1> {
        PrefGroupPack [%W get [%W curselection]]
    }
    bind $lbx  <B1-Motion> {
        PrefGroupPack [%W get [%W curselection]]
    }
    # to be sur that class bindind to executed first
    bindtags $lbx "Listbox $lbx [winfo class $lbx] [winfo toplevel $lbx] All"
    foreach gn $pref(groupNames) {
        $lbx insert end $gn   ;# VOIR MAN LISBOX : PLUS SIMPLE ?
    }
    #endforeach
    
    
    $lbx selection clear 0 end
    $lbx selection set 0

}
proc PrefGroupPack {gn} {
    global pref
    set pref(currentGroupName) $gn
    foreach frameIdx [array names pref "gn*,frame"] {
    	pack forget $pref($frameIdx)
    }
    pack  $pref(gn$gn,frame) -fill x -expand true -side left
}
#endproc PrefGroupPack
##############################################################################


# The buttons frame :
proc PrefDialogMakeButtons {} {

    global pref
    set w $pref(toplevel)
    
    set buttons [frame $w.but -relief sunken]
    pack $buttons -side bottom -fill x -ipadx 4m -ipady 4m

    button $buttons.reset -text $pref(msg,button_reset)\
        -padx 5m  -pady 2m \
        -command {Pref_Reset ; PrefUpdateWidgets}

    button $buttons.cancel -text $pref(msg,button_cancel) \
        -padx 5m  -pady 2m \
        -command {PrefCancel}

    frame $buttons.done -borderwidth 1m -relief sunken
    button $buttons.done.b -text $pref(msg,button_done) \
        -padx 5m  -pady 2m \
        -command {PrefUpdatePrefs ; PrefCancel}
    pack $buttons.done.b 
    button $buttons.save -text $pref(msg,button_save) \
        -padx 5m  -pady 2m \
        -command {PrefUpdatePrefs; Pref_Save}
    
    pack  \
         $buttons.done \
         $buttons.save \
         $buttons.reset \
         $buttons.cancel \
         -side right 
    
    # some bindings about the button
    foreach b {cancel reset save done} {
        PrefBindHelp  $buttons.$b  $pref(msg,help_button_$b)
    }

    bind $w    <Escape>        "PrefInvokeButton $buttons.cancel"
    bind $w    <Return>        "PrefInvokeButton $buttons.done.b"
    bind $w    <$pref(Meta)-s> "PrefInvokeButton $buttons.save"
    
}
# A mettre dans librairie "button.tcl" ou "wubutton.tcl"
proc PrefInvokeButton {but} {
    global pref
    $but configure -state active -relief sunken
    update idletasks
    after 100
    $but invoke
    # button $but could no more exist if invoke destroye its parent !
    catch {$but configure -state normal -relief raised}

}
# text avec scrollbar pour les messages
proc PrefDialogMakeStatus {} {

    global pref
    set w $pref(toplevel)
    
    frame $w.status  -relief raised
    set pref(status,text) [text $w.status.t] 
    $pref(status,text) configure  -height $pref(status,height) \
           -yscroll "$w.status.s set" \
           -setgrid true \
           -state disabled \
           -font $pref(status,font)

    scrollbar $w.status.s   -command {$pref(status,text) yview} \
                            -relief raised
    
    pack $w.status       -side bottom   -fill both -expand true
    pack $w.status.t     -side left  -fill both -expand true
    pack $w.status.s                 -fill y  -expand true
}
proc PrefBindHelp {w msg} {
    bind $w <Enter> [list PrefStatus $msg]
    bind $w <Leave> {PrefStatus "" }
}

######################################################################
# te:rule parent [args] - returns a rule suitable for parent
# used as argument to a pack command (from Jay SEKORA)
######################################################################
# A SORTIR dans "wuframe.tcl"
proc PrefRule { {parent {}} args} {
  global pref

  if {$parent == "."} {set parent ""} ;# so "." doesn't give "..rule0"

  incr pref(uid)

  set rule "$parent.rule$pref(uid)"
  frame $rule -height 2 -width 2 -borderwidth 1 -relief raised
  if {$args != ""} {eval $rule configure $args}
  return $rule
}

proc PrefDialogTypeSTRING {f vn} {
    global pref

    # default type is entry
    set width $pref(gn[set pref(vn$vn,group)],commentWidth)
    label $f.label -text $pref(vn$vn,comment) \
            -width $width -anchor w
    PrefBindHelp  $f.label  $pref(vn$vn,help)
    
    pack $f.label -side left
    
    entry $f.entry -width 10 -relief sunken  \
                   -textvariable pref(vn$vn,vartmp)
    pack $f.entry -side left -fill x -expand true
    
    PrefSetDefaultUpdate $vn
        
}
proc PrefDialogTypeBOOLEAN {f vn} {
    global pref

    # default type is entry
    set width $pref(gn[set pref(vn$vn,group)],commentWidth)
    label $f.label -text $pref(vn$vn,comment) \
            -width $width -anchor w
    PrefBindHelp  $f.label  $pref(vn$vn,help)
    
    pack $f.label -side left
    checkbutton $f.check \
          -text "On" \
          -variable pref(vn$vn,vartmp)
          
    pack $f.check -side left
    
    PrefSetDefaultUpdate $vn
}
proc PrefDialogTypeENUM {f vn} {
    global pref

    # default type is entry
    set width $pref(gn[set pref(vn$vn,group)],commentWidth)
    label $f.label -text $pref(vn$vn,comment) \
            -width $width -anchor w
    PrefBindHelp  $f.label  $pref(vn$vn,help)
    
    pack $f.label -side left
    
    set choices $pref(vn$vn,typearg)
    foreach choice $choices {
        incr pref(uid)
        radiobutton $f.c$pref(uid) \
            -text $choice \
            -variable pref(vn$vn,vartmp) \
            -value $choice
        pack $f.c$pref(uid) -side left
    }
    PrefSetDefaultUpdate $vn
        
}
proc PrefDialogItem { frame vn} {

    global pref
    
    set gn $pref(vn$vn,group)
    
    set TYPE $pref(vn$vn,type)
    
    if {[string match "pref(null*)" $vn]} {
        # A traiter plus tard (pas implemente)
        error "varName $vn groupe $gn de type $TYPE non implementé"
    }
    
    # create an unique frame identifier for the variable "vn":
    set f "$frame.v[incr pref(uid)]"
    set  pref(vn$vn,frame) $f
    frame $f -borderwidth 2
    pack $f  -side top -fill x

    set pref(vn$vn,vartmp)  [PrefValueGet $vn]
    
    # If such a proc exist: we use it
    if {"[info proc PrefDialogType$TYPE]" == "PrefDialogType$TYPE"} {
    
        PrefDialogType$TYPE $f $vn
        
    } else {
    
        # default type is "STRING"
        PrefDialogTypeSTRING $f $vn
        
    }

}
proc PrefUpdateWidgets {} {
    global pref
    set indexes [array names pref "vn*,updateWidget"]
    foreach idx $indexes {
        eval uplevel #0 $pref($idx)
    }
}
proc PrefUpdatePrefs {} {
    global pref
    set indexes [array names pref "vn*,updatePref"]
    foreach idx $indexes {
        eval uplevel #0 $pref($idx)
    }
    set indexes [array names pref "vn*,postcommand"]
    foreach idx $indexes {
        catch {eval uplevel #0 $pref($idx)}
    }
    set pref(modified) 1
}
# Example of what we want for the pref "grep(admin)" :
# updateWidget : set "pref(vngred(admin),vartmp)" [set gred(admin)]
#                (with gred(admin) contained in $vn)
# updatePref :   set "gred(admin)" "[set pref(vngred(admin),vartmp)]"
proc PrefSetDefaultUpdate {vn} {
    global pref
    # i.e set varName gred(admin)
    # # set varName     $vn
    # i.e set vartmpName pref(vngred(admin),vartmp)
    set vartmpName   pref(vn$vn,vartmp)
    
#     set pref(vn$vn,updateWidget) [list set $vartmpName \$$vn ]
#     set pref(vn$vn,updatePref)   [list set $vn \$$vartmpName ]
    set pref(vn$vn,updateWidget) [list set $vartmpName \[set $vn\] ]
    set pref(vn$vn,updatePref)   [list set $vn \[set $vartmpName\] ]
}
proc Pref_Save {} {
    global pref
    # for use with clock tcl command :
    set clockFormatString [clock format [clock seconds] \
               -format {Modified on %d/%m/%y at %T\n}]
    
    # patternes de reconnaissance du texte à modifier du .cshrc
    set prefPat "###!!! START of automatically added text"
    set suffPat "###!!! END of automatically added text"
    
    # Définition du texte à insérer pour mettre à jour le fichier
    # utilisateur (inutile de mettre un return final)
    set    updateText "$prefPat\n"
    append updateText "###!!! Do not edit between these two "
    append updateText "\"###!!!...\" lines\n"
    append updateText "###!!! $clockFormatString\n"
    foreach gn $pref(groupNames) {
    
        append updateText "#########################################\n"
        append updateText "# Group name : $gn\n\n"
        foreach vn $pref(gn$gn,varNames) {
            
            
            set varName $vn
            set xresName $pref(vn$vn,xres)
            set comment $pref(vn$vn,comment)
    
            set value [PrefValueGet $varName]
            append updateText "# $comment :\n"
            if {"x$xresName" != "x$pref(null)"} {
              append updateText \
                  "[list option add *${xresName} $value]\n\n"
            } else {
               append updateText \
                  "[list set  $vn $value]\n\n"
            }
        }
    }
    append updateText "$suffPat"

    # Si le fichier utilisateur n'existe pas : on en crée un vide.
    # on crée également les répertoires parents si nécessaire.
    if {![file exist $pref(userPrefsDefault)]} {
        file mkdir [file dirname $pref(userPrefsDefault)]
        # on crée un fichier vide :
        if {[catch {write_file $pref(userPrefsDefault) ""} msg]} {
            bell
            $pref(reportProc) "$pref(msg,unable_creating_userfile)\
                    \"$pref(userPrefsDefault)\""
            return 0
        }
        
    }
    
    set tmpFile [PrefTmpFileName $pref(userPrefsDefault)]
    # On génère une version à jour du fichier à modifier :
    set newTxt [PrefGetMaj \
          $pref(userPrefsDefault) $prefPat* $suffPat* $updateText]
    
    # on procède en deux temps pour la sauvegarde (sécurité) :
    if [catch {
        write_file $tmpFile $newTxt
# #         sys:rm $pref(userPrefsDefault)
        file delete $pref(userPrefsDefault)
# #         sys:mv $tmpFile $pref(userPrefsDefault)
        file rename $tmpFile $pref(userPrefsDefault)
    } err] {
        $pref(reportProc) "$pref(msg,cannot_install) $pref(userPrefsDefault):\
                          $err"
        return
    }
    $pref(reportProc) "$pref(msg,user_file_saved_in)\
             \"$pref(userPrefsDefault)\""
    $pref(reportProc) "User file saved in \"$pref(userPrefsDefault)\""
    set pref(modified) 0
}
proc Pref_Reset {} {
    global pref
    # Clear database and variables
    option clear
    foreach vn $pref(varNames) {
        uplevel #0 unset $vn
    }
    # Re-read app and user defaults
    PrefSourceFile $pref(appPrefsDefault)
    PrefSourceFile $pref(userPrefsDefault)
    # Restore undefined values
    foreach vn $pref(varNames) {
        PrefValueSetIfUndefined $vn
    }
    $pref(reportProc) "Preferences reset to default\
                      \012files \"$pref(userPrefsDefault)\" and\
                      \012\"$pref(appPrefsDefault)\" have been reread."
}
proc PrefTmpFileName {file} {
    global pref
    return ${file}_[incr pref(uid)]
}
proc PrefCancel {} {
    global pref
    destroy $pref(toplevel)
    set pref(done) 1
}
########################################################################
# PrefGetMaj <fileName> <prefPattern> <suffPattern> <updateText>
#     retourne une chaine dans laquelle le bloc de texte compris 
#     entre les patternes <prefPattern> et <suffPattern> est remplacé 
#     par la chaine <updateText>.
#     Si La première patterne n'est pas trouvée, la chaine est ajoutée
#     à la fin du résultat.
#     Tous les espaces et return finaux sont effacés.
proc PrefGetMaj {fileName prefPattern suffPattern updateText} {

    # on fera précéder la chaine de mise à jour par deux return 
    # ce qui donnera UNE SEULE ligne vide (sauf en debut de fichier)
    set updateText \n\n$updateText
    
    # initialisation du text correspondant au fichier mis à jour
    set txt ""
    
    # ou on est ? (where vaut before | inside | after)
    set where "before"

    foreach line [split [string trim [read_file $fileName]] \n] {

        # dans les lignes qui suivent, les cas les plus probables se 
        # produiront dans l'ordre
        switch -exact $where {

          before {
              if ![string match $prefPattern $line] {
                  # on se contente de recopier les premières lignes
                  append txt $line\n
                  continue
              } else {
                  # on entre dans la zone à mettre à jour
                  # on va donc rajouter le bloc de texte à mettre à jour
                  # (en controlant le nombre de return)
                  set where "inside"
                  set txt "[string trimright $txt]$updateText\n"
                  continue
              }
          }

          inside {
              if ![string match $suffPattern $line] {
                  # on ignore cette ligne puisqu'elle a déja été mise à jour
                  continue
              } else {
                  # on sort de la zone de mise à jour
                  set where "after"
                  continue
              }
          }

          after {
              # on contente de recopier les dernières lignes
              append txt $line\n
              continue
          }
          
          default {
              # impossible (:-)
              error "$were inconnu ; doit-être before | inside | after\
                     (procédure file:getMaj)"
          }
        } ;# endswitch

    } ;# endforeach

    # On supprime les espaces et return finaux :
    set txt [string trimright $txt]
    
    # Au cas ou on n'aurait pas trouver la ligne préfixe 
    # (cas d'un fichier n'ayant jamais été mis à jour),
    # on ajoute la mise à jour à la fin
    if {$where == "before"} {
        append txt $updateText
    }
    
    return $txt
    
} ;#endproc PrefGetMaj

########################################################################
# Les deux procédure suivante sont provisoirement incluse dans le 
# package : elle seront peut-etre incluse définitivemenet ou sortie ?
########################################################################
# retourne le contenu du fichier "filename"
# exemple : set txt [read_file ?-nonewline? toto.vhd]
#           set txt [read_file toto.vhd ?<nbr_chars>?]
proc read_file {fileName args} {
    if {$fileName == "-nonewline"} {
        set flag $fileName
        set fileName [lvarpop args]
    } else {
        set flag {}
    }
    set fp [open $fileName]
    set stat [catch {
        eval read $flag $fp $args
    } result]
    close $fp
    if {$stat != 0} {
        global errorInfo errorCode
        error $result $errorInfo $errorCode
    }
    return $result
} 

# crée (ou écrase) le fichier "filename" avec les chaines passer en parametre
# write_file <fileName> <string> ?<string> ...?
proc write_file {fileName args} {
    set fp [open $fileName w]
    
    set stat [catch {
        foreach string $args {
            puts $fp $string
        }
    } result]
    close $fp
    if {$stat != 0} {
        global errorInfo errorCode
        error $result $errorInfo $errorCode
    }
}


