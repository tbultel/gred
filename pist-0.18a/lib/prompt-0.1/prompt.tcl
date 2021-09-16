

package provide prompt 0.1

# Prompt_Box --
#
# COMMENTAIRES A FAIRE !
# A FAIRE : (REFAIRE...) les Bindings(?) + Multifenetre ?

global Prompt 

proc PromptInit {} {
    global Prompt
    
    set Prompt(msg,button_reset) "Reset"
    set Prompt(msg,button_ok) "Ok"
    set Prompt(msg,button_cancel) "Cancel"
    set Prompt(msg,icon_title) "Prompt"
    set Prompt(Meta) "Meta"
}
 
########################################################################
# A mettre dans librairie "button.tcl" ou "wubutton.tcl"
proc PromptInvokeButton {but} {
    $but configure -state active -relief sunken
    update idletasks
    after 150
    $but invoke
    # button $but could no more exist if invoke destroye its parent !
    catch {$but configure -state normal -relief raised}

}

########################################################################
# tclParseSpec --
#
#	Parses a list of "-option value" pairs. If all options and
#	values are legal, the values are stored in
#	$data($option). Otherwise an error message is returned. When
#	an error happens, the data() array may have been partially
#	modified, but all the modified members of the data(0 array are
#	guaranteed to have valid values. This is different than
#	Tk_ConfigureWidget() which does not modify the value of a
#	widget record if any error occurs.
#
# Arguments:
#
# w = widget record to modify. Must be the pathname of a widget.
# Ex : set specs {
#                 {-title ""}
#                 {-parent .}
#                 {-entries ""}
#                }
# # specs = {
#    {-commandlineswitch resourceName ResourceClass defaultValue verifier}
#    {....}
# }
#
# flags = currently unused.
#
# argList = The list of  "-option value" pairs.
########################################################################
proc tclParseSpec {w niveau specs argList} {
    upvar #$niveau $w data
    
    proc tclListValidFlags {v} {
    # renvoie une chaine avec la liste des flags valids
        upvar $v cmd
    
        set len [llength [array names cmd]]
        set i 1
        set separator ""
        set errormsg ""
        foreach cmdsw [lsort [array names cmd]] {
            append errormsg "$separator$cmdsw"
            incr i
            if {$i == $len} {
                set separator " or "
            } else {
                set separator ", "
            }
        }
        return $errormsg
    } ; # endproc tclListValidFlags
    
    # 1: Put the specs in associative arrays for faster access
    #
    foreach spec $specs {
	if {[llength $spec] > 3} {
	    error "\"spec\" should contain 2 elements"
	}
 
	set cmdsw [lindex $spec 0]
	set cmd($cmdsw) ""
	set def($cmdsw)   [lindex $spec 1]
    }

    if {[expr [llength $argList] %2] != 0} {
	foreach {cmdsw value} $argList {
	    if ![info exists cmd($cmdsw)] {
	        bgerror "unknown option \"$cmdsw\", must be \
	                 [tclListValidFlags cmd]"
	    }
	}
	error "value for \"[lindex $argList end]\" missing"
    }

    # 2: set the default values
    #
    foreach cmdsw [array names cmd] {
	set data($cmdsw) $def($cmdsw)
    }

    # 3: parse the argument list
    #
    foreach {cmdsw value} $argList {
	if ![info exists cmd($cmdsw)] {
	    bgerror "unknown option \"$cmdsw\", must be \
	             [tclListValidFlags cmd]"
	}
	set data($cmdsw) $value
    }
} ; # endproc tclParseSpec

########################################################################
# PromptMakeButtons --
# Dessine une 3 bouttons dans une frame de nom $f.buttons.
# Un boutton Cancel qui ferme la fenetre
# Un boutton Reset qui reset les champs de chaque Prompt
# Un boutton Close qui ferme la fenetre et renvoie la liste des Prompt
#   a l'application
# Les chaines sont recuperees dans le tableau Prompt :
# set Prompt(msg,button_reset) "Reset"
# set Prompt(msg,button_ok) "Ok"
# set Prompt(msg,button_cancel) "Cancel"
########################################################################
proc PromptMakeButtons {f line} {
    global Prompt

    set w $f.buttons
    
    frame $w -relief flat -borderwidth 1
    pack $w -side bottom -fill x 
    # Les bouttons n'auront ne seront pas selectionnables pas <Tab> 
    # et <Shift-Tab>
    button $w.cancel -text $Prompt(msg,button_cancel) \
        -padx 5m  -pady 2m -takefocus 0 \
        -command "set Prompt(button) cancel"

    button $w.reset -text $Prompt(msg,button_reset)\
        -padx 5m  -pady 2m -takefocus 0\
        -command "set Prompt(button) reset"
                
    frame $w.ok -borderwidth 1m -relief sunken
    button $w.ok.b -text $Prompt(msg,button_ok) \
        -padx 5m  -pady 2m -takefocus 0 \
        -command "set Prompt(button) ok"
    
    pack $w.ok.b
    pack $w.ok \
         $w.reset \
         $w.cancel -side right 
  
    # Some bindings
    # La commande suivante :
    # bind Prompt <$Prompt(Meta)-c> "PromptInvokeButton $w.cancel"
    # ne permet pas de faire fonctionner la touche Escape si par exemple on est
    # dans une entry... C ennuyeux. Mais les bindings suivant fonctionnent
    # pour une telle que $f!=. 
    bind $f <$Prompt(Meta)-c> "set Prompt(button) cancel"
    bind $f <Escape> "set Prompt(button) cancel"
    bind $f <$Prompt(Meta)-r> "set Prompt(button) reset"
    bind $f <$Prompt(Meta)-o> "set Prompt(button) ok"
    bind $f <Return> "set Prompt(button) ok"

    # On selectionne la valeur d'une entry lors que l'entry est selectionnee
    # bind PromptEntry <FocusIn> \
    #            "%W select clear
    #             %W select range 0 end"
} ; # endproc PromptMakeButtons

########################################################################
# PromptReturnValues --
# Renvoie une liste des valeurs des differentes Prompt. L'ordre de ces 
# valeurs est l'ordre de specification des entrees avec l'option 
# -entries. Pour les autres on renvoie la valeur.
########################################################################
proc PromptReturnValues {f} {
    set listValues {}
    set indice 0
    upvar #[PromptReturnPrompt_BoxLevel] PromptLocal PromptLocal
    foreach el $PromptLocal(-entries) {
        set type [PromptGetType $el]
        set IsLock 0
        if {$type == "ENTRY"} {
            set IsLock [PromptIsLock $el]
        }
        if {($type != "SEPARATOR") && ($IsLock == 0) 
                                    && ($type != "WINDOW") } {
            upvar #0 $PromptLocal(variableName$indice) a
            set $listValues \
            [lappend listValues $a]
        }
        incr indice
    }
    return $listValues
} ; # endproc PromptReturnValues

########################################################################
# PromptResetValues --
# Reset les valeurs des differentes Prompt.
# On fait passer la frame contenant toutes les Prompt (cette frame
# contient la frame contenant les bouttons $f.bouttons et la frame 
# contenant les Prompt $f.prompt)
# Pour Reset une entry soit il existe un procedure 
# PromptResetValues$type, alors on l'execute. Sinon on effectue les lignes
# de commande : upvar #0 $PromptLocal(variableName$indice) a
#               set a $PromptLocal(default$indice)
# Pour faire un reset de l'entry.
# EFFETS DE BORD : Beaucoup !
# Modifie les variables de chaque entry. Reset chacune de ces variables
# avec leur valeur par defaut
########################################################################
proc PromptResetValues {f} {
    set indice 0
    upvar #[PromptReturnPrompt_BoxLevel] PromptLocal PromptLocal
    foreach el $PromptLocal(-entries) {
        set type [PromptGetType $el]
        if {"[info proc PromptResetValues$type]" 
              == "PromptResetValues$type"} {
            PromptResetValues$type $f $indice $el
        } else {
            # Pour les autre type, on reinitialise la variable
            upvar #0 $PromptLocal(variableName$indice) a
            set a $PromptLocal(default$indice)
        }
        incr indice
    }
} ; # endproc PromptResetValues

########################################################################
# PromptTypeENTRY --
# Permet de dessiner deux widgets de type label et entry
# La variable du widget entry sera stocke dans une variable de nom 
# Prompt. Ces 2 widgets seront packes dans la frame f
# Le nom du widget entry sera $f.entry et le nom du widget sera
# f.label$indice
# OPTIONS :
# -label NomLabel :label a afficher
# -variable varName : Nom de la varibla par default
# -default defaultValue : Valeur par default si la variable par default
# n'existe pas ou si il n'y a pas eu d'option -variable
# -lock {ON|OFF} : permet de locker l'entry : on affiche seulement une
# valeur.
# EFFETS DE BORDS : (valable pour toutes les procedures du style
# PromptResetValues$type ou type est element de [BOOLEAN..WINDOW])
# Creer un variable Prompt(value$indice) qui memorise la valeur 
# associe a l'entry si aucune option -variable n'est precisee. 
# Sinon cree une variable de nom $Prompt(variableName$indice) si il n'y a 
# une option -variable.
# Cree enfin une variable dont le nom est specidie par l'option -variable
# si elle n'existe pas.
########################################################################
proc PromptResetValuesENTRY {f indice options} {
    upvar #[PromptReturnPrompt_BoxLevel] PromptLocal PromptLocal
    set IsLock [PromptIsLock $options]
    if {$IsLock == 0} {
        upvar #0 $PromptLocal(variableName$indice) a
        set a $PromptLocal(default$indice)
    }
} ; # endproc PromptResetValuesENTRY
proc PromptTypeENTRY {f indice args} { 
    upvar #[PromptReturnPrompt_BoxLevel] PromptLocal PromptLocal
    set args [lindex $args 0]
    # Tant qu'il reste des arguments
    set specs "
               {-type \"\"}
               {-label \"\"}
               {-default \"\"}
               {-lock FALSE}
               {-variable \"\"}
               {-width 30}
              "
    
    tclParseSpec argument [expr 1+[PromptReturnPrompt_BoxLevel]] $specs $args
    set PromptLocal(variableName$indice) $argument(-variable)
    
    if {$argument(-lock)} {
        set argument(-lock) 1
    } 
    if {($argument(-lock) == 1) && ($argument(-variable) == "")} {
	bgerror "You must specifie a variable name with \"-lock\" option."
    }
    if {$argument(-label) != ""} {
        set w $f.label
        label $w -text $argument(-label) \
                -width $PromptLocal(maxWidthLabel) -anchor w
        pack $w -side left -fill x
    }
    if {$argument(-lock)} {
        # Avec l'option -lock ON
        global $PromptLocal(variableName$indice)
        label $f.label_2 \
                -textvariable $PromptLocal(variableName$indice) \
                -relief flat -anchor w -justify left \
                -width $argument(-width)
        pack $f.label_2 -side right -expand yes -fill x
    } else {
        # Avec l'option -lock OFF
        # L'option -default est utilise que si la variable n'existe pas
        upvar #0 $PromptLocal(variableName$indice) a
        if {$argument(-variable) == ""} {
        # l'utilisateur ne precise pas de nom de variable
            set PromptLocal(default$indice) $argument(-default)
            set PromptLocal(variableName$indice) \
                Prompt(value$indice)
            upvar #0 $PromptLocal(variableName$indice) a
            set a $argument(-default)
        } elseif {[info exists a]} {
            # La variable existe la valeur par defaut sera la valeur
            # de la variable
            set PromptLocal(default$indice) $a
        } else {
            # La variable n'existe pas la valeur par defaut sera celle precise
            # par -default
            set PromptLocal(default$indice) $argument(-default)
            set a $argument(-default)
        }
        set w $f.entry
        eval {entry $w -relief sunken -width $argument(-width) \
               -textvariable } $PromptLocal(variableName$indice)
        pack $w -side left -fill x -expand true
        set tmp [bindtags $w]
        lappend tmp PromptEntry Prompt
        eval bindtags $w [list $tmp]
        $w delete 0 end
        $w select clear
        $w insert 0 $PromptLocal(default$indice)
    }
} ; # endproc PromptTypeENTRY

########################################################################
# PromptTypeBOOLEAN --
# Permet de dessiner deux widgets de type label et checkbutton
# La variable du widget checkbutton sera stocke dans une variable de nom 
# Prompt(value$indice) (si il n'y a pas de d'option -variable).
# Ces 2 widgets seront packes dans la frame f.
# Le nom du widget checkbutton sera $f.check et le nom du widget sera
# f.label.
# On positionne le widget checkbutton a OFF par default, on le met
# a ON si l'option -default vaut YES, 1, ON.
# OPTIONS :
# -label NomLabel :label a afficher
# -variable varName : Nom de la varibla par default
# -default defaultValue : Valeur par default si la variable par default
# n'existe pas ou si il n'y a pas eu d'option -variable
########################################################################
proc PromptResetValuesBOOLEAN {f indice options} {
    upvar #[PromptReturnPrompt_BoxLevel] PromptLocal PromptLocal
    if {$PromptLocal(default$indice)} {
        $f.prompt$indice.check select
    } else {
        $f.prompt$indice.check deselect
    }
}
proc PromptTypeBOOLEAN {f indice args} { 
    upvar #[PromptReturnPrompt_BoxLevel] PromptLocal PromptLocal 
    set args [lindex $args 0]
    set specs "
               {-type \"\"}
               {-label \"\"}
               {-default OFF}
               {-variable \"\"}
              "
    
    tclParseSpec argument [expr 1+[PromptReturnPrompt_BoxLevel]] $specs $args
    set PromptLocal(variableName$indice) $argument(-variable)
    
    if {$argument(-label) != ""} {
        label $f.label -text $argument(-label) \
                       -width $PromptLocal(maxWidthLabel) \
                       -anchor w
        pack $f.label -side left
    }
    
    upvar #0 $PromptLocal(variableName$indice) a
    if {$argument(-variable) == ""} {
        # l'utilisateur ne precise pas de nom de variable
        set PromptLocal(default$indice) $argument(-default)
        set PromptLocal(variableName$indice)\
            Prompt(value$indice)
        upvar #0 $PromptLocal(variableName$indice) a
        set a $argument(-default)
    } elseif {[info exists a]} {
        # La variable existe la valeur par defaut sera la valeur
        # de la variable
        set PromptLocal(default$indice) $a
    } else {
        # LA variable n'existe pas la valeur par defaut sera celle precise
        # par -default
        set PromptLocal(default$indice) $argument(-default)
        set a $argument(-default)
    }
    
    eval {checkbutton $f.check \
          -text "On" \
          -variable} $PromptLocal(variableName$indice)
    pack $f.check -side left
    
    if {$PromptLocal(default$indice)} {
        $f.check select
    } else {
        $f.check deselect
    }
} ; # endproc PromptTypeBOOLEAN

########################################################################
# PromptTypeRADIOBUTTON --
# Permet de dessiner un widget de type label et une serie de 
# widget radiobutton
# La variable du widget radiobutton sera stocke dans une variable de 
# nom Prompt(value$indice) si il n'y a pas d'option -variable.
# Ces widgets seront packes dans la frame f.
# Le nom du widget label sera $f.label et des widgets sera
# $f.radio_$indice2 ou indice2 s'incremente a chaque nouveau
# radioboutton.
# On positionne le radiobutton a OFF par default, sauf le radiobutton
# specifie avec l'option -default.
# OPTIONS :
# -label NomLabel :label a afficher
# -typearg listeOfValue : liste des valeurs possibles
# -variable varName : Nom de la varibla par default
# -default defaultValue : Valeur par default si la variable par default
#  n'existe pas ou si il n'y a pas eu d'option -variable
########################################################################
proc PromptTypeRADIOBUTTON { f indice args} { 
    upvar #[PromptReturnPrompt_BoxLevel] PromptLocal PromptLocal
    set args [lindex $args 0]
    set specs "
               {-type \"\"}
               {-label \"\"}
               {-typearg \"\"}
               {-default OFF}
               {-variable \"\"}
               {-nbcolonnes 3}
              "

    tclParseSpec argument [expr 1+[PromptReturnPrompt_BoxLevel]] $specs $args
    set PromptLocal(variableName$indice) $argument(-variable)
        
    if {$argument(-typearg) == ""} {
        bgerror "No type arg option in RADIOBUTTON"
    }
    if {$argument(-label) != ""} {
        label $f.label -text $argument(-label) \
                -width $PromptLocal(maxWidthLabel) -anchor w
        pack $f.label -side left
    }
    
    upvar #0 $PromptLocal(variableName$indice) a
    if {$argument(-variable) == ""} {
        # l'utilisateur ne precise pas de nom de variable
        set PromptLocal(default$indice) $argument(-default)
        set PromptLocal(variableName$indice) \
            Prompt(value$indice)
        upvar #0 $PromptLocal(variableName$indice) a
        set a $argument(-default)
    } elseif {[info exists a]} {
        # La variable existe la valeur par defaut sera la valeur
        # de la variable
        set PromptLocal(default$indice) $a
    } else {
        # La variable n'existe pas la valeur par defaut sera celle 
        # precise par -default
        set PromptLocal(default$indice) $argument(-default)
        set a $argument(-default)
    }
    
    frame $f.radio
    set choices $argument(-typearg)
    set indice2 0
    foreach choice $choices {
        eval {radiobutton $f.radio.radio_${indice2} \
            -text $choice \
            -value $choice \
            -variable} $PromptLocal(variableName$indice)
#         pack $f.radio_${indice2} -side left
        grid $f.radio.radio_${indice2} \
              -row [expr int(${indice2}/$argument(-nbcolonnes))]\
              -column [expr ${indice2} % $argument(-nbcolonnes)] \
              -sticky w
        if {$PromptLocal(default$indice) == $choice} {
            $f.radio.radio_${indice2} select
        } else { 
            $f.radio.radio_${indice2} deselect
        }
        incr indice2
    }
    pack $f.radio
} ; # endproc PromptTypeRADIOBUTTON


########################################################################
# PromptTypePOPUP --
# Permet de dessiner un widget de type label et un popup avec une liste
# de nom.
# La variable du widget menu sera stocke dans une variable de nom 
# Prompt(value$indice) si aucune variable n'est specifie avec l'option
# -variable. Ces widgets seront packes dans la frame f.
# Le nom du widget label sera $f.label $indice et du widget menu sera
# f.menu
# OPTIONS : 
# -label NomLabel :label a afficher
# -typearg listeOfValue : liste des valeurs possibles
# -variable varName : Nom de la varibla par default
# -default defaultValue : Valeur par default si la variable par default
# n'existe pas ou si il n'y a pas eu d'option -variable
########################################################################
proc PromptTypePOPUP { f indice args} { 
    upvar #[PromptReturnPrompt_BoxLevel] PromptLocal PromptLocal
    set args [lindex $args 0]
    set specs "
               {-type \"\"}
               {-label \"\"}
               {-typearg \"\"}
               {-default \"\"}
               {-variable \"\"}
              "

    tclParseSpec argument [expr 1+[PromptReturnPrompt_BoxLevel]] $specs $args
    set PromptLocal(variableName$indice) $argument(-variable)
    
    if {$argument(-typearg) == ""} {
        bgerror "No type arg option in CHECKBUTTON"
    }
    if {$argument(-label) != ""} {
        label $f.label -text $argument(-label) \
                -width $PromptLocal(maxWidthLabel) -anchor w
        pack $f.label -side left
    }
    
    upvar #0 $PromptLocal(variableName$indice) a
    if {$argument(-variable) == ""} {
        # l'utilisateur ne precise pas de nom de variable
        set PromptLocal(default$indice) $argument(-default)
        set PromptLocal(variableName$indice) \
            Prompt(value$indice)
        upvar #0 $PromptLocal(variableName$indice) a
        set a $argument(-default)
    } elseif {[info exists a]} {
        # La variable existe la valeur par defaut sera la valeur
        # de la variable
        set PromptLocal(default$indice) $a
    } else {
        # LA variable n'existe pas la valeur par defaut sera celle precise
        # par -default
        set PromptLocal(default$indice) $argument(-default)
        set a $argument(-default)
    }
    
    eval tk_optionMenu $f.menu $PromptLocal(variableName$indice) \
                       $argument(-typearg)
    # On affiche rien... ou plutot un label vide..
    label $f.label_2 -justify center 
    pack $f.menu -side right -expand yes -fill x
    pack $f.label_2 -side right -expand yes -fill x
    
    set $PromptLocal(variableName$indice) \
        $PromptLocal(default$indice)
} ; # endproc PromptTypePOPUP

########################################################################
# PromptTypeFILE --
# Permet de dessiner un widget de type label, une entry et un boutton pour
# appeler LE browser de fichier (celui fournit avec tk4.2).
# La variable du widget checkbutton sera stocke dans une variable de nom 
# Prompt(value$indice) si il n'y a pas d'option -variable.
# Ces widgets seront packes dans la frame f.
# Le nom du widget label sera $f.label et du widget entry sera
# f.ent et celui du boutton sera $f.but
# OPTIONS :
# -variable varName
# LA variable (par default la variable sera Prompt(value$indice)
# -default directorie
# L'option -default est prit en compte que si la variable specifie grace
# a l'option -variable n'existe pas. Si il n'y a pas d'option -variable 
# la valeur par default sera celle precise avec l'otpion -default.
# l'option -default permet aussi au browser de savoir le repertoire ou
# commencer la recherche.
# -filetype ListeOfFileType : liste du type des fichiers.
# -operation {read|write}
# read pour ouvrir un fichier et write pour sauvegarder un fichier "Save As"
# -options ListOfOptions : Liste des options a passer a tk_getOpenFile ou
# a tk_getSaveFile.
########################################################################
proc PromptTypeFILE { f indice args} { 
    upvar #[PromptReturnPrompt_BoxLevel] PromptLocal PromptLocal
    proc fileDialog {w ent types operation initialdir options} {
    # appele tk_getOpenFile ou tk_getSaveFile en fonction de operation
    # et update le nom du fichier
        if {$operation == "read"} {
            set file [eval {tk_getOpenFile -filetypes $types -parent $w \
                -initialdir  $initialdir} $options]
        } else {
            set file [eval {tk_getSaveFile -filetypes $types -parent $w \
                -initialdir  $initialdir} $options]
        }
        if [string compare $file ""] {
            $ent delete 0 end
            $ent insert 0 $file
            $ent xview end
        }
    } ; # end proc fileDialog

    set args [lindex $args 0]
    set types {{
	{{All files}		*}
	{{Text files}		{.txt .doc}	}
	{{Text files}		{}		TEXT}
	{{Tcl Scripts}    	{.tcl}		TEXT}
	{{C Source Files}	{.c .h}		}
	{{All Source Files}	{.tcl .c .h}	}
	{{Image Files}    	{.gif}		}
	{{Image Files}	        {.jpeg .jpg}	}
	{{Image Files}    	{}		{GIFF JPEG}}
    }}
    set specs "
               {-type \"\"}
               {-label \"\"}
               {-default [pwd]}
               {-variable \"\"}
               {-filetype \"$types\"}
               {-operation read}
               {-options {-initialfile Untitled -defaultextension .txt}}
              "
    tclParseSpec argument [expr 1+[PromptReturnPrompt_BoxLevel]] $specs $args
    set PromptLocal(variableName$indice) $argument(-variable)
    
    if {$argument(-label) != ""} {
        label $f.label -text $argument(-label) \
                -width $PromptLocal(maxWidthLabel) -anchor w
        pack $f.label -side left
    }
    if {($argument(-operation) != "read") 
        && ($argument(-operation) != "write")} {
        bgerror "Option \"-operation\" must be \"read\" \
                 or \"write\" for type FILE."
    }
    
    upvar #0 $PromptLocal(variableName$indice) a

    if {$argument(-variable) == ""} {
        # l'utilisateur ne precise pas de nom de variable
        set PromptLocal(default$indice) $argument(-default)
        set PromptLocal(variableName$indice) \
            Prompt(value$indice)
        upvar #0 $PromptLocal(variableName$indice) a
        set a $argument(-default)
    } elseif {([info exists a]) && ($a == "")} {
        # La variable existe et vaut "", la valeur par defaut sera la valeur
        # de la variable
        set PromptLocal(default$indice) $argument(-default)
        set a $argument(-default)
    } elseif {[info exists a]} {
        # La variable existe la valeur par defaut sera la valeur
        # de la variable
        set PromptLocal(default$indice) $a
    } else {
        # LA variable n'existe pas, la valeur par defaut sera celle precise
        # par -default
        set PromptLocal(default$indice) $argument(-default)
        set a $argument(-default)
    }
    set argument(-initialdir) $PromptLocal(default$indice)
    
    eval {entry $f.ent -width 20 -textvariable} \
           $PromptLocal(variableName$indice)
    button $f.but \
        -text "Browse ..." -height 1 -width 7\
        -command "fileDialog $f $f.ent \
                  $argument(-filetype) $argument(-operation) \
                  $argument(-initialdir) \"$argument(-options)\""
    set tmp [bindtags $f.ent]
    lappend tmp PromptEntry Prompt
    eval bindtags $f.ent [list $tmp]
    pack $f.ent -side left -expand yes -fill x
    pack $f.but -side right 
    
    set a $PromptLocal(default$indice)
} ; # endproc PromptTypeFILE

########################################################################
# PromptTypeCOLOR --
# Permet de dessiner un widget de type label, une entry (permettant d'afficher
# la couleur choisie) et un boutton pour appeler LE browser de couleur 
# (celui fournit avec tk4.2).
# La variable du widget checkbutton sera stocke dans une variable de nom 
# Prompt(value$indice) si il n'y a pas d'option -variable.
# Ces widgets seront packes dans la frame f.
# Le nom du widget label sera $f.label et du widget entry sera
# f.label_2 et celui du boutton sera $f.but
# OPTIONS :
# -variable varName
# LA variable (par default la variable sera Prompt(value$indice)
# -default color
# L'option -default est prit en compte que si la variable specifie grace
# a l'option -variable n'existe pas. Si il n'y a pas d'option -variable 
# la valeur par default sera celle precise avec l'otpion -default.
# l'option -default permet aussi au browser de savoir par quel couleur 
# commencer.
# -title windowName
# nom de la fenetre contenant le browser de couleur
########################################################################
proc PromptResetValuesCOLOR {f indice options} {
    upvar #[PromptReturnPrompt_BoxLevel] PromptLocal PromptLocal
    upvar #0 $PromptLocal(variableName$indice) a
    set a $PromptLocal(default$indice)
    $f.prompt$indice.label_2 configure \
       -background $PromptLocal(default$indice)
} ; # endproc PromptResetValuesCOLOR

proc PromptTypeCOLOR {f indice args} { 
    upvar #[PromptReturnPrompt_BoxLevel] PromptLocal PromptLocal
    proc setColor {w button var title} {
    # appele le browser de couleur et update l'entry contenant le nom de la
    # couleur ET l'entry affichant la couleur
        upvar #0 $var a
        set initialColor [$button cget -background]
        set color [tk_chooseColor -title $title -parent $w \
            -initialcolor $initialColor]
        if [string compare $color ""] {
            # on change la couleur affiche
            $button config -background $color
            # on update la valeur de la couleur
            set a $color
        }
    } ; # end proc setColor
    
    set args [lindex $args 0]
    set specs "
               {-type \"\"}
               {-label \"\"}
               {-default \"\"}
               {-variable \"\"}
               {-title \"Choose a color\"}
              "

    tclParseSpec argument [expr 1+[PromptReturnPrompt_BoxLevel]] $specs $args
    set PromptLocal(variableName$indice) $argument(-variable)
    
    if {$argument(-label) != ""} {
        label $f.label -text $argument(-label) \
                -width $PromptLocal(maxWidthLabel) -anchor w
        pack $f.label -side left
    }
    
    upvar #0 $PromptLocal(variableName$indice) a
    
    if {$argument(-variable) == ""} {
        # l'utilisateur ne precise pas de nom de variable
        set PromptLocal(default$indice) $argument(-default)
        set PromptLocal(variableName$indice) \
            Prompt(value$indice)
        upvar #0 $PromptLocal(variableName$indice) a
        set a $argument(-default)
    } elseif {[info exists a]} {
        # La variable existe la valeur par defaut sera la valeur
        # de la variable
        set PromptLocal(default$indice) $a
    } else {
        # LA variable n'existe pas la valeur par defaut sera celle precise
        # par -default
        set PromptLocal(default$indice) $argument(-default)
        set a $argument(-default)
    }
    if {$PromptLocal(default$indice) == ""} {
       set PromptLocal(default$indice) black
    }
    label $f.label_2 -width 1 \
                     -background $PromptLocal(default$indice)
    button $f.but \
        -text "Browse ..." -height 1 -width 7 \
        -command "setColor $PromptLocal(-parent) $f.label_2 \
                  $PromptLocal(variableName$indice) \
                  \"$argument(-title)\""
    eval {label $f.label_3 \
               -width 10 \
               -textvariable} $PromptLocal(variableName$indice)
    pack $f.label_2 -side left -expand yes -fill x
    pack $f.label_3 -side left -expand yes -fill x 
    pack $f.but -side right 
    
    set $PromptLocal(variableName$indice) \
        $PromptLocal(default$indice)
} ; # endproc PromptTypeCOLOR

########################################################################
# PromptTypeWINDOW --
# Permet de dessiner deux widgets de type label et checkbutton
# La variable du widget checkbutton sera stocke dans une variable de nom 
# Prompt(value$indice) (si il n'y a pas de d'option -variable).
# Ces 2 widgets seront packes dans la frame f.
# Le nom du widget checkbutton sera $f.check$indice et le nom du widget sera
# f.label$indice.
# On positionne le widget checkbutton a OFF par default, on le met
# a ON si l'option -default vaut YES, 1, ON.
# OPTIONS :
# -label NomLabel :label a afficher
# -variable varName : Nom de la varibla par default
# -default defaultValue : Valeur par default si la variable par default
# n'existe pas ou si il n'y a pas eu d'option -variable
########################################################################
proc PromptResetValuesWINDOW {f indice options} {
} ; # endproc PromptResetValuesWINDOW
proc PromptTypeWINDOW {f indice args} { 
    upvar #[PromptReturnPrompt_BoxLevel] PromptLocal PromptLocal
    set args [lindex $args 0]
    set specs "
               {-type \"\"}
               {-frame \"\"}
               {-side top}
              "
    tclParseSpec argument [expr 1+[PromptReturnPrompt_BoxLevel]] $specs $args
    pack $argument(-frame) -side $argument(-side)
} ; # endproc PromptTypeWINDOW

########################################################################
# PromptTypeSEPARATOR --
# Permet de dessiner un widget de type label et une ligne au dessus (si
# l'option -line n'est pas specifiee).
# Ces widgets seront packes dans la frame f.
# Le nom du widget label sera $f.label.
# Le nom de la ligne de separation sera $f.label_1 si elle est
# place au dessus du label (option -line up ou both).
# Le nom de la ligne de separation sera $f.label_2 si elle est
# place au dessus du label (option -line down ou both).
########################################################################
proc PromptResetValuesSEPARATOR {f indice options} {
} ; # endproc PromptResetValuesSEPARATOR
proc PromptTypeSEPARATOR {f indice args} { 
    upvar #[PromptReturnPrompt_BoxLevel] Prompt Prompt
    set args [lindex $args 0]
    set specs {
               {-type ""}
               {-label ""}
               {-line none}
              }

    tclParseSpec argument [expr 1+[PromptReturnPrompt_BoxLevel]] \
                 $specs $args

    if {($argument(-line) == "up") || ($argument(-line) == "both")} {
        frame $f.label_1 -height 2 -width 2 \
                                  -borderwidth 1 -relief raised
        pack $f.label_1 -fill x
    }
    if {$argument(-label) != ""} {
        label $f.label -text $argument(-label) -anchor w
        pack $f.label -side top -fill both -expand true
    }
    if {($argument(-line) == "down") || ($argument(-line) == "both")} {
        frame $f.label_2 -height 2 -width 2 \
                                  -borderwidth 1 -relief raised
        pack $f.label_2 -fill x
    }
} ; # endproc PromptTypeSEPARATOR

########################################################################
# PromptIsLock --
# Renvoie 1 si il y a l'option -lock sinon retourne 0
########################################################################
proc PromptIsLock oneEntry {
    while {[llength $oneEntry] != 0} {
        switch -glob -- [lindex $oneEntry 0] {
            -lock {
            return 1
            set oneEntry [lreplace $oneEntry 0 1]
            }
            -* {
            set oneEntry [lreplace $oneEntry 0 1]
            continue 
            }
            default { bgerror "Illegal command name \"[lindex $oneEntry 0]\"\
                               in -entries parameter of 
                               procedure \"Prompt_Box\""}
        }
    }
    return 0
} ; # endproc PromptIsLock

########################################################################
# PromptGetType --
# recupere le type de l'entry a dessiner on lui passe 
# une liste du type : {-label "VOTRE NOM" ... -type ENTRY ....}
# Return value :
# Elle renvoie alors le type de l'entry (dans l'exemple "ENTRY")
########################################################################
proc PromptGetType oneEntry {
    set type "ENTRY"
    while {[llength $oneEntry] != 0} {
        switch -glob -- [lindex $oneEntry 0] {
            -type {
            set type [lindex $oneEntry 1]
            set oneEntry [lreplace $oneEntry 0 1]
            }
            -* {
            set oneEntry [lreplace $oneEntry 0 1]
            continue 
            }
            default { bgerror "Illegal command name \"[lindex $oneEntry 0]\"\
                               in -entries parameter of 
                               procedure \"Prompt_Box\""}
        }
    }
    return $type ; # Le type par default est ENTRY...
}

########################################################################
# PromptGetMaxWidthLabel --
# recupere la taille maximum des labels pour chaque entry.
# Return value :
# renvoie la taille maximum des labels de chaque entry.
########################################################################
proc PromptGetMaxWidthLabel Prompt {
    set max 0
    foreach el $Prompt {
        while {[llength $el] != 0} {
            switch -glob -- [lindex $el 0] {
                -label {
                    set width [string length [lindex $el 1]]
                    if {$width >= $max} {
                        set max $width
                    }
                    set el [lreplace $el 0 1]
                    continue
                }
                -* {
                    set el [lreplace $el 0 1]
                    continue 
                }
                default { bgerror "Illegal command name \"[lindex $el 0]\"\
                                   in -entries parameter of 
                                   procedure \"Prompt_Box\""}
            }
        }
    }
    return $max
} ; # endproc PromptGetType

########################################################################
# Prompt_Box --
# 
# Construit une fenetre permettant de demander des valeurs a un utilisateur
# Les parametres sont :
# -title Nom pour specifier le nom de la fenetre
# -parent Parent pour permettre d'incorporer la fenetre dans une 
#  autre fenetre
# -entries ListeDEntree :
# { -type ENTRY -label "LABEL" } : dessine un champs de type entry avec
# "LABEL" comme label.
# Return value:
# Renvoie un liste des differentes valeurs de chauqe Prompt dans l'ordre
# ou elles sont specifie dans le champs "-entries" de args.  
########################################################################
proc Prompt_Box {args} {
    global Prompt
    
    # Procedure renvoyant le niveau d'appel de la procedure Prompt_Box +1 !
    proc PromptReturnPrompt_BoxLevel {} "
        return [info level]
    "
    PromptInit
    
    # Au cas ou plusieurs fenetre serait par Prompt_Box, on numerote les
    # Fenetre, pour pouvoir dissocier les differentes variables.
    if {[info exists Prompt(boxId)]} {
        incr Prompt(boxId)
    } else {
        set Prompt(boxId) 1
    }
    
    set newWindow 0
    set specs {
        {-title ""}
        {-parent .prompt}
        {-entries ""}
        {-label ""}
        {-variable ""}
        {-default ""}
    }
    
    # On parse la ligne de commande et on recupere les differents
    # parametres
    tclParseSpec PromptLocal [info level] $specs $args
    
    # 2. Set the dialog to be a child window of $parent
    #
    #
    if [winfo exists $PromptLocal(-parent)] {
        # La fenetre existe
        if {[string compare $PromptLocal(-parent) .]} {
            # $PromptLocal(-parent) != .
            set w $PromptLocal(-parent)
        } else { 
            # $PromptLocal(-parent) == .
            set w $PromptLocal(-parent)
            frame $w -borderwidth 2
            pack $w -side top -fill x
        }            
    } else {
        set newWindow 1
        # La fenetre n'existe pas
        set w $PromptLocal(-parent)
        # 3. Create the top-level window and divide it into top
        # and bottom parts.
        catch {destroy $w}
        toplevel $w -class Prompt
        wm title $w $PromptLocal(-title)
        wm iconname $w $Prompt(msg,icon_title)
        # Si on ferme la fenetre on renvoie un resultat. L'utilisateur voit
        # Le boutton Cancel s'invoquer avant la fermeture de la fenetre.
        # C plus clair pour lui ! Fermer la fenetre equivaut a appuyer sur 
        # Cancel !
        wm protocol $w WM_DELETE_WINDOW "PromptInvokeButton $w.buttons.cancel"
        # On recupere l'ancienne fenetre active (Celle qui execute la procedure
        # Prompt_Box en fait. On laisse la joie au gestionnaire de fenetre de
        # gerer les fenetres olFocus et la fenetre ouverte par Prompt_Box (ici 
        # il s'agit de $w). Pour fvwm par exemple si on iconifie $oldFocus 
        # ca iconifie $w. Et $w sera TOUJOURS devant $w. 
        set oldFocus [focus]
        wm transient $w $oldFocus
        regexp "(.\[^.\]*)" $oldFocus match window
        bind $window <Visibility> [subst {
          if {\[string match $window %W\]} {
            raise $w
            focus $w
          }
        }]      
    }
    # 5. Create an entry foreach entry specified in option -entry
    # Si il n'y a pas d'option entries, alors c un raccourcit pour
    # saisir une chaine
    if {$PromptLocal(-entries) == ""} {
        set PromptLocal(-entries) \
            [list [list -type ENTRY \
                        -label  $PromptLocal(-label) \
                        -variable $PromptLocal(-variable) \
                        -default $PromptLocal(-default)]]
    }
        
    # On recupere la taille du plus long label
    set PromptLocal(maxWidthLabel) \
        [PromptGetMaxWidthLabel $PromptLocal(-entries)]
        
    # On construit la fenetre en fonctions de l'option -entries :
    set indice 0 ; # A chaque entry est associe un indice
    foreach el $PromptLocal(-entries) {
        # On recupere le type de l'entry
        set type [PromptGetType $el]
        # On cree une frame pour cette entry de nom 
        # $main.__tk__Prompt.prompt.promptXXX ou XXX est un entier
        if {$type != "WINDOW"} {
            set frame $w.prompt$indice
            frame $frame -borderwidth 2
            pack $frame -side top -fill x
        }
        # On pack l'entry courante
        # If such a proc exist: we use it
        if {"[info proc PromptType$type]" == "PromptType$type"} {
            PromptType$type $frame $indice $el
        } else {
            # Else we raise an error
            bgerror "The type $type doesn't exist."
        }
        incr indice
    }
    
    # 6. Create a row of buttons at the bottom of the dialog.
    PromptMakeButtons $w $indice        

    if {$newWindow == 1} {
        set x [expr [winfo screenwidth $w]/2 - [winfo reqwidth $w]/2 \
                - [winfo vrootx [winfo parent $w]]]
        set y [expr [winfo screenheight $w]/2 - [winfo reqheight $w]/2 \
                - [winfo vrooty [winfo parent $w]]]
        wm geom $w +$x+$y
        wm deiconify $w
    }
    
    # $w is "withdraw" ; we have to update to known the real size
    # of the window (from tk_dialog procedure).
    update idletasks
    
    # 7. Set a grab and claim the focus too.
    set oldFocus [focus]
# puts "old focus : $oldFocus"
    set oldGrab [grab current $w]
# puts "old grab : $oldGrab"
    if {$oldGrab != ""} {
        set grabStatus [grab status $oldGrab]
    }
    
# puts "new window : $newWindow avec w : $w"
    if {$newWindow == 1} {
        grab $w
    }

    # 8. Wait for the user to respond, then restore the focus and
    # return the list of entries' values.  Restore the focus
    # before quitting procedure Prompt_Box, since otherwise the window manager
    # may take the focus away so we can't redirect it.  Finally,
    # restore any grab that was in effect.
    # On boucle tant que l'utilisateur appuie sur "Reset", si il appuie sur
    # "cancel" ou si l'utilisateur tente de fermer la fenetre : la variable
    # Prompt(button) vaut cancel. Si l'utilisateur a appuye sur "ok", 
    # Prompt(button) vaudra ok.
    while {1} {
# puts "j'attends l'appui sur un bouton"
        tkwait variable Prompt(button)
# puts "bouton : $Prompt(button)"
        switch -exact -- $Prompt(button) {
           ok {
# puts "ok appuye"
               break
           }
           cancel {
               PromptResetValues $w
# puts "cancel appuye"

               bind $window <Visibility> {}
               break
           }
           reset {
# puts "reset appuye"
              PromptResetValues $w
           }
           default {
# puts "probleme"
               bgerror "Internal error"
           }
        }
    } 
    
    if { $oldFocus != "" } {
      catch {focus $oldFocus}
    }

    if {$oldGrab != ""} {
        if {$grabStatus == "global"} {
            grab -global $oldGrab
        } else {
            grab $oldGrab
        }
    }
    
    # On retourne la liste des valeurs correspondant a bonne fenetre
    set  PromptReturnValues [PromptReturnValues $w]
    # Il y a une fentre en moins...
    incr Prompt(boxId) -1
    destroy $w
    bind $window <Visibility> {}
    return $PromptReturnValues
} ; # endproc Prompt_Box

# A FAIRE ???
# Pour destroy detruire ".", Si Prompt(newWindow) == 0 
#                          et si Prompt(-parent) == .
# sinon detruire $w

