# MODIFICATIONS:
# le 11 Feb 1997 par CARQUEIJAL David : re-modification des procédures :
#   - gred:cmd:save,
#   - gred:cmd:saveas,
#   - gred:cmd:open,
#  Création des procédures gred:file:... et du fichier grfile.tcl
########################################################################

########################################################################
# gred:file:open --
# Ouvre un fichier dans la fenetre contenant le canvas <I>c</I>.
# Cette procédure ouvre un browser, efface le grafcet précédent et
# affiche le nouveau.
proc gred:file:open {c} {
   global gred
   upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
   
   $c config -cursor watch
   
   if ![gred:isClean .[gred:getGrafcetName $c]] {
   
      # On va demander confirmation pour "Sauver / Ne pas sauver / Annuler"
      set choice [tk_messageBox -type yesnocancel\
                    -parent .[gred:getGrafcetName $c] \
                    -message "$grafcet(filename) has been modified. \
                              Do you want to save it first?" \
                    -icon warning]
      switch -exact $choice {
        cancel {
            return
        }
        yes {
            gred:file:save $c
        } 
      }

   }
   
   set OK 0
   while {!$OK} {
     set types {
          {{Grafcet Files}   {.gra}}
          {{Text Files}       {.txt}        }
          {{TCL Scripts}      {.tcl}        }
          {{All Files}        *             }
     }
     set fileNameToOpen [tk_getOpenFile -title "Load New File:" \
                                        -defaultextension ".grd" \
                                        -filetypes $types \
                                        -parent .[gred:getGrafcetName $c] \
                                        -initialfile $grafcet(filename)]
     if {![string length $fileNameToOpen]} {
        $c config -cursor tcross
        return
     }
     if {![file readable $fileNameToOpen]} {
        tk_messageBox -type ok \
                -parent .[gred:getGrafcetName $c] \
                -message "File $fileNameToOpen is unreadable ! Try again..." \
                -icon warning
        continue
     }
     set OK 1
   }
  
   # On detruit la structure du grafcet en cours d'edition :
   gred:clear .[gred:getGrafcetName $c]
   # On prépare le chargement du nouveau grafcet
   grafcet:init [gred:getGrafcetName $c]
   
   $c config -cursor tcross
   
   gred:file:load $c $fileNameToOpen
}

########################################################################
# gred:file:load -- Procédure autorisant la lecture "safe" d'un fichier
# Ouvre un fichier dans la fenetre contenant le canvas <I>c</I>.
# Procédure permettant de lire un fichier d'entrée contenat un grafcet
proc gred:file:load {c fileName} {
   global gred
   upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
   
   $c config -cursor watch
   
   # On crée un safe interpréteur pour loader le fichier
   gred:status $c "Creating safe interp for loading $fileName"

   # initialisation de la liste de objets qui vont etre crees
   Record:clear $c
    
   # On ouvre le fichier en lecture
   set in [open $fileName r]
   
   # On crée l'interpréteur qui va permettre de lire le fichier .gra
   interp create -safe loadingInterp
   
   gred:status $c "Loading File : $fileName."
   update
   # On crée les procédures utiles à la création d'un grafcet
   # Ces procédures vont être exécutées dans l'interpréteur maître
   interp alias loadingInterp Etape:create {} Etape:create $c
   interp alias loadingInterp Trans:create {} Trans:create $c
   interp alias loadingInterp Link:create {} Link:create $c
   
   set grafcet(filename) ""
   
   # On évalue le fichier dans l'interpréteur esclave
   if [catch {interp eval loadingInterp [read $in]} error] {
       # Le fichier contient une commande illégale...
       bgerror "$error while reading $fileName"
       # On range nos petits...
       close $in
       interp delete loadingInterp
       # On detruit la structure du grafcet en cours d'édition,
       # on réinitialise gred et on détruit l'interp...
       gred:clear .[gred:getGrafcetName $c]
       # Ligne suivante a changer ?
       set grafcet(untitled) $gred(untitled)
       gred:markClean .[gred:getGrafcetName $c]
       grafcet:init  [gred:getGrafcetName $c]
       $c config -cursor tcross
       return
   }
   
   # On range nos petits...
   close $in
   interp delete loadingInterp
   
   set grafcet(filename) $fileName
   
   gred:markClean .[gred:getGrafcetName $c]
   undo_Save .[gred:getGrafcetName $c]
   gred:status $c "File : $fileName edited."
   $c config -cursor tcross
}



#######################################################################
# gred:file:commandSort
#
#

proc gred:file:commandSort {commands} {
   
    set buf ""
    set transitions {}
    set links	{}
    set etapes	{}
    
    set sbuf [split $commands \n]
   
    foreach line $sbuf	{
	if {[string first "Trans:create" $line] == 0}  {
	    set tokens [split $line]
	    set name [lindex $tokens 8]
	    set name [lindex $name 0]
	    set transitions [linsert $transitions end [list $name $line]]
        } elseif {[string first "Link:create" $line] == 0}  {
	    # support with and without -detail option
	    set source_index 2
	    set dest_index 4
	    if {[llength $tokens] > 5} {
		set source_index 4
		set dest_index 6
	    }
	    set tokens [split $line]
	    set name [lindex $tokens $source_index]
	    set name [lindex $name 0]
	    set links [linsert $links end [list $name $line]]
	} elseif {[string first "Etape:create" $line] == 0}  {
	    # etapes	    
	    set tokens [split $line]
	    set name [lindex $tokens 11]
	    set name [lindex $name 0]
	    set etapes [linsert $etapes end [list $name $line]]
	}	    
    }
      

    set setapes [lsort -ascii $etapes]
#   puts stdout $setapes
    
    set stransitions [lsort -ascii $transitions]
#    puts stdout $stransitions

    set slinks [lsort -ascii $links]
#    puts stdout $slinks

    foreach {t} $setapes {
	set tr [lindex $t 1]
#	puts stdout $tr
	set buf [format "%s\n%s" $buf $tr]
    }

    foreach {t} $stransitions {
	set tr [lindex $t 1]
#	puts stdout $tr
	set buf [format "%s\n%s" $buf $tr]
    }

    foreach {t} $slinks {
	set tr [lindex $t 1]
#	puts stdout $tr
	set buf [format "%s\n%s" $buf $tr]
    }


    return $buf
    
}

########################################################################
# gred:file:save --
# Sauvegarde le fichier de la fenetre contenant le canvas <I>c</I>.
# A ce stade, on est certain que le fichier est writable !
# 
# 
proc gred:file:save {c} {
    upvar #0 gred.[gred:getGrafcetName $c] gred
    upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
    
    $c config -cursor watch
    
    if {$grafcet(filename) == ""} {
       gred:file:saveas $c
    } else {
      gred:status $c "Saving File : $grafcet(filename)"
      # on recupere la representation du grafcet sous forme de commandes
      set commands [Obj:getGrafcetCommands $c\
                       [lsort -ascii -increasing [Obj:getAllSelectable $c]]]
      update
      set fid [open $grafcet(filename) w]
      puts $fid \
       "# Fichier sauvegardé par Gred, l'éditeur de Grafcet développé à l'Ensta"
      puts $fid "# Votre contact à l'Ensta : diam@ensta.fr"
      set clock [clock format [clock seconds] \
                 -format {%d/%m/%y à %T}]
      puts $fid "# Sauvegarde du : $clock"

      set sortedCommands [gred:file:commandSort $commands]
      
      puts $fid $sortedCommands
      close $fid
      
      gred:markClean .[gred:getGrafcetName $c]
      undo_referenceSet .[gred:getGrafcetName $c]
    }
    
    $c config -cursor tcross
}


########################################################################
# gred:file:saveas --
# Sauvegarde le fichier de la fenetre contenant le canvas <I>c</I>.
# Prépare la sauvegarde d'un fichier en ouvrant un browser de fichier.
# Ne sauvegarde pas le fichier, c'est la procédure <I>gred:file:save</I>
# qui s'en occupe.
proc gred:file:saveas {c} {

   global gred
   upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
   
   $c config -cursor watch
   
   set OK 0
   while {!$OK} {
     set types {
          {{Grafcet Files}   {.gra}}
          {{Text Files}       {.txt}        }
          {{TCL Scripts}      {.tcl}        }
          {{All Files}        *             }
     }
     set fileNameToSave [tk_getSaveFile -title "Save As:" \
                                        -defaultextension ".grd"\
                                        -filetypes $types \
                                        -parent .[gred:getGrafcetName $c] \
                                        -initialfile $grafcet(filename)]
     if ![string length $fileNameToSave] {
         return
     }
     if {[file exists $fileNameToSave] 
         && ![file writable $fileNameToSave]} {
         tk_messageBox -type ok\
            -parent .[gred:getGrafcetName $c] \
            -message "File $fileNameToSave is unwritable ! Try again..." \
            -icon warning
         continue
     }
     set OK 1
   }
   
   set grafcet(filename) $fileNameToSave
   
   gred:updateTitle .[gred:getGrafcetName $c]
   
   $c config -cursor tcross
   
   gred:file:save $c
}

