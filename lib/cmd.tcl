########################################################################
# MODIFICATIONS:
# le 10 Feb 1997 par CARQUEIJAL David : 
#   - Un tableau gred pour les variables globales au grafcet
#   - Un tableau pour chaque grafcet + graphPP pour le Presse papier
#   - Mise en route de Save+SaveAs+Load+Open
#   - ouverture du fichier passe en parametre si il existe au demarrage 
#     de gred
# le 11 Feb 1997 par CARQUEIJAL David : re-modification des procédures :
#   - gred:cmd:save,
#   - gred:cmd:saveas,
#   - gred:cmd:open,
#  C procédures ont été renommées en gred:file:... dans un fichier
#  grfile.tcl
# le 11 Feb 1997 par CARQUEIJAL David : Création de la procédure
#  gred:clear
# le 11 Feb 1997 par CARQUEIJAL David : ajout des procédures :
#   - grafcet:init qui initialise certaine variable de gred(généraliser 
#        7 procédure en appelant : etape:init, trans:init, object:init 
#        et link:init).
#   - gred:load charge un fichier par l'intermédiaire d'un safe interp
# le 12 Feb 1997 par CARQUEIJAL David : Suppression du bug dans
#  gred:cmd:reopen


proc gred:windowToCanvas {w} {
    return $w.draw.c
}

proc gred:getGrafcetName {c} {
    regexp "^\.(\[^\.]+)" $c match grafcet
    return $grafcet
}
########################################################################
# gred:cmd:newProcess --
# 
# 
# 
proc gred:cmd:newProcess {} {
    global gred
    exec $gred(exe) &
}
   
########################################################################
# gred:cmd:new --
# 
# 
# 
proc gred:cmd:new {} {
    return [gred:new]
}

########################################################################
# gred:cmd:reopen --
# 
# 
# 
proc gred:cmd:reopen {c} {
    global gred
    upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
    
    if {$grafcet(filename) != ""} {
        gred:status $c "Opening same file : $grafcet(filename) !" 
        exec $gred(exe) $grafcet(filename) &
    } else {
        gred:status $c "Opening new gred window !"
        exec $gred(exe) &
    }
}

########################################################################
# grafcet:init -- Procédure finale d'initialisation
# Procédure d'initialisation appelée à la fin de la création de
# la fenêtre.
# Permet d'initialiser les informations utiles pour gérer le undo.
proc grafcet:init {grafcetName} {
  global grafcet.$grafcetName gred
  upvar #0 grafcet.$grafcetName grafcet
    
    Record:clear [gred:windowToCanvas $grafcetName]
    
    Sel:clear [gred:windowToCanvas .$grafcetName]
    
    undo_init .$grafcetName
    
    # init. des identifications uniques des objets etape, trans. et liens
    set grafcet(TransUId)  0
    set grafcet(TransNameId) $gred(transition,nameIndex)
    set grafcet(EtapeUId)  0
    set grafcet(EtapeNameId) $gred(etape,nameIndex)
    set grafcet(LinkUId)   0
}
########################################################################
# gred:cmd:close -- Ferme l'application courante
# options a prevoir : 
# -save, -nosave, -ask
# 
# 
interp alias {} Close {} gred:cmd:close
proc gred:cmd:close {w} {
   global gred
   upvar #0 grafcet.[gred:getGrafcetName $w] grafcet
   
   [gred:windowToCanvas $w] config -cursor watch
    
   if ![gred:isClean .[gred:getGrafcetName $w]] {
   
      # On va demander confirmation pour "Sauver / Ne pas sauver / Annuler"
      if {$grafcet(filename) == ""} {
        set choice [tk_messageBox -type yesnocancel \
                      -parent  .[gred:getGrafcetName $w]\
                      -message "Grafcet \"Untitled\" has been modified.\
                                Do you want to save it first?" \
                      -icon warning]
      } else {
        set choice [tk_messageBox -type yesnocancel\
                      -parent .[gred:getGrafcetName $w] \
                      -message "$grafcet(filename) has been modified. \
                                Do you want to save it first?" \
                      -icon warning]
      }
      switch -exact $choice {
        cancel {
            [gred:windowToCanvas $w] config -cursor tcross
            return
        }
        yes {
            gred:file:save [gred:windowToCanvas $w]
        }
      }
   }
   
   # On récupére le nom du grafcet à partir du nom de la fenêtre
   regexp "^\.(\[^\.]+)" $w match grafcetName
   
   gred:delete $grafcetName
   
   # On supprime la fenêtre de la liste des fenêtres ouvertes
   if {[set matchidx [lsearch -exact $gred(grafcets) $grafcetName]] != -1} {
       set gred(grafcets) [lreplace $gred(grafcets) $matchidx $matchidx]
   } else {
       error "Internal bug : You try to close a non existing window !"
   }
   # On quitte l'application si il n'y a plus de fenêtre d'ouverte !
   if {[llength $gred(grafcets)] <= 0} {
       exit 0
   }
}

########################################################################
# gred:cmd:quit -- Quitte tous les esclaves de pist puis pist.
# 
# 
#
proc gred:cmd:quit {} {
   global gred
   gred:status all "Closing all window..."
   set grafcets [lsort $gred(grafcets)]
   foreach grafcet $grafcets {
       wm deiconify .$grafcet
       raise .$grafcet
       gred:cmd:close .$grafcet
   }
}


########################################################################
# gred:cmd:export --
# 
# 
# 
proc gred:cmd:export {} {

   global gred
   
   warn "Exportation : PAS ENCORE IMPLEMENTE !"
   return 
   
   1 - creer une toplevel (.export)
   2 - grider (ou packer) en bas un popup pour selectionner un 
       format d'export
   3 - lancer tk_fileSaveGet -parent .export
       -retourne nom du fichier fileName
       - et la variable $currentFormat est positionné
   4 - si tout n'est pas OK : return
   
   5 - set txtToExport [gred:getExport$currentFormat] 

   6 - write_file $fileName $txtToExport
   
}

########################################################################
# gred:cmd:import --
# 
# 
# 
proc gred:cmd:import {c} {

   global gred
   upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
   
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
   
   set result [Prompt_Box \
                -title "Import" \
                -entries {
                    {-type POPUP -label "Format to import"
                     -default Gra
                     -typearg {Bidon Gra Bidon2 Bidon3}}
                    {-type FILE  -label "File to import"
                     -operation read }}]
   set format [lindex $result 0]
   set file [lindex $result 1]

   gred:parseFile $c $format $file
}

proc gred:parseFile {c format file} {
    gred:status $c "Import à implanter... $format $file"
}

########################################################################
# gred:cmd:print --
# 
# 
# 
proc gred:cmd:print {c} {
    Epsf_Box $c
}

########################################################################
# Menu Edit...
########################################################################

########################################################################
# gred:clear --
# 
# Supprime le grafcet (du point de vue graphique et structure de donnée)
# 
proc gred:clear {w} {
    global gred
    
    [gred:windowToCanvas $w] config -cursor watch
    
    upvar #0 grafcet$w grafcet
    unset grafcet
    [gred:windowToCanvas $w] delete GrafcetTag
    
    [gred:windowToCanvas $w] config -cursor tcross
} ;# endproc gred:clear


########################################################################
# gred:cmd:undo --
# 
# 
# 
proc gred:cmd:undo {w} {
    undo_undo $w
    
    [gred:windowToCanvas $w] config -cursor watch
    # On ajourne le témoin de sauvegarde du fichier en cours d'édition.
    if [undo_isReference $w] {
        gred:markClean $w
    } else {
        gred:markDirty $w
    }
    
    [gred:windowToCanvas $w] config -cursor tcross
}

########################################################################
# gred:cmd:redo --
# 
# 
# 
proc gred:cmd:redo {w} {
    undo_redo $w

    [gred:windowToCanvas $w] config -cursor watch
    # On ajourne le témoin de sauvegarde du fichier en cours d'édition.
    if [undo_isReference $w] {
        gred:markClean $w
    } else {
        gred:markDirty $w
    }
    
    [gred:windowToCanvas $w] config -cursor tcross
}

########################################################################
# gred:cmd:copy --
# 
# 
# 
proc gred:cmd:copy {c} {
  global gred
  
  $c config -cursor watch
  
  if ![string compare [Sel:getSelectedOids $c] {}] {
    gred:status $c "Pas de sélection: Copier impossible..."
    $c config -cursor tcross
    return
  } else {
    gred:status $c "Sélection Copié"
    Clipboard:clear
    Clipboard:setCommands $c [Sel:getSelectedOids $c]
  }
  
  $c config -cursor tcross
}

########################################################################
# gred:cmd:cut --
# 
# 
# 
proc gred:cmd:cut {c} {
  global gred
  
  $c config -cursor watch 
  if ![string compare [Sel:getSelectedOids $c] {}] {
    gred:status $c "Pas de sélection: Couper impossible..."
    $c config -cursor tcross
    return
  } else {
    gred:status $c "Sélection Copié"
    Clipboard:clear
    Clipboard:setCommands $c [Sel:getSelectedOids $c]
    Sel:delete $c
  }
  $c config -cursor tcross
}

########################################################################
# gred:cmd:paste --
# 
# 
# 
proc gred:cmd:paste {c} {
  upvar #0 gred.[gred:getGrafcetName $c] gred
  
  $c config -cursor watch
  
  undo_mark .[gred:getGrafcetName $c]
  set commandToPaste [Clipboard:get]
  if {$commandToPaste == ""} {
    gred:status $c "Buffer vide: Coller impossible..."
    $c config -cursor tcross
    return
  }
  gred:status $c "Pasting Buffer..."
  regsub -all "_CANVAS_" $commandToPaste $c commandToPaste
#   puts $commandToPaste
  catch {eval $commandToPaste}
  
  # déplace la selection a la derniere position de la souris
  if {[info exist gred(mouse,xPress)] && [info exist gred(mouse,yPress)]} {
    set box [eval $c bbox [Sel:getSelectedOids $c]]
    set x [lindex $box 0]
    set y [lindex $box 1]
    set dx [expr $gred(mouse,xPress) - $x]
    set dy [expr $gred(mouse,yPress) - $y]
  } else {
    set dx 10
    set dy 10
  }
  
  Sel:move $c $dx $dy
  undo_unMark .[gred:getGrafcetName $c]
  
  $c config -cursor tcross
}

########################################################################
# gred:cmd:selectAll --
# 
# 
# 
proc gred:cmd:selectAll {c} {
 Sel:new $c [Obj:getAllSelectable $c]
}

########################################################################
# gred:cmd:changeParamsBox --
# 
# A MODIFIER:
#  POUR CHANGER LES PARAMETTRE DE (DES ?) OBJET SELECTIONNE.
#  Cette procédure appelle la boite de modification des parametres 
#  correspondant au dernier objet pointé et clické.
# 
# 
proc gred:cmd:changeParamsBox {c} {
upvar #0 gred.[gred:getGrafcetName $c] gred

  set oid [Obj:getPointedOid $c\
          $gred(mouse,xPress) $gred(mouse,yPress)]
  switch -exact -- [Obj:getType $oid] {
    Etape {Etape:changeParams $c $oid "all"}
    Trans {Trans:changeParams $c $oid "all"}
  }
}

########################################################################
# gred:cmd:changeEtapeType --
# 
# 
# 
proc gred:cmd:changeEtapeType {c newType} {
upvar #0 gred.[gred:getGrafcetName $c] gred
  set oid [Obj:getPointedOid $c\
          $gred(mouse,xPress) $gred(mouse,yPress)]
          
  switch -exact -- [Obj:getType $oid] {
    Etape {Etape:changeParams $c $oid type $newType}
    Trans {Trans:changeParams $c $oid type $newType}
  }
}

########################################################################
# gred:evalSel --
# 
# 
# 
proc gred:evalSel {} {
   global gred
   
   if {[catch {selection get} script]} {
       return
   } {
      gred:status all "result : [uplevel #0 $script]"
   }
}

proc showVersion {} {
# #    Prompt_Box\
# #        -title "Informations sur l'exécutable GRED" \
# #        -parent .top \
# #        -entries [subst {
# #          {-type SEPARATOR -line down -label "VERSION DE GRED"}
# #          {-type ENTRY -variable gred(version) -lock 1 -width 60}
# #          {-type SEPARATOR -line down -label "VERSION DE PIST"}
# #          {-type ENTRY -variable gred(pistversion) -lock 1 -width 60}
# #          {-type SEPARATOR -line down -label "Chemin de l'exécutable GRED"}
# #          {-type ENTRY -variable gred(exe) -lock 1 -width 60} 
# #          {-type SEPARATOR -line down -label "Chemin du répertoire GRED"}
# #          {-type ENTRY -variable gred(pistsetup) -lock 1 -width 60} 
# #          {-type SEPARATOR -line down -label "Chemin du répertoire PIST"}
# #          {-type ENTRY -variable gred(setup) -lock 1 -width 60} 
# #        }]
   Prompt_Box\
       -title "Informations sur l'exécutable GRED" \
       -parent .top \
       -entries [subst {
         {-type SEPARATOR -line up -label "VERSION DE GRED :"}
         {-type ENTRY -variable gred(version) -lock 1 -width 60}
         {-type SEPARATOR -line up -label "VERSION DE PIST :"}
         {-type ENTRY -variable gred(pistversion) -lock 1 -width 60}
         {-type SEPARATOR -line up -label "Chemin de l'exécutable GRED :"}
         {-type ENTRY -variable gred(exe) -lock 1 -width 60} 
         {-type SEPARATOR -line up -label "Chemin du répertoire GRED :"}
         {-type ENTRY -variable gred(pistsetup) -lock 1 -width 60} 
         {-type SEPARATOR -line up -label "Chemin du répertoire PIST :"}
         {-type ENTRY -variable gred(setup) -lock 1 -width 60} 
       }]
}

########################################################################
# console --
# 
# 
# 
# proc console {} {
#     global gred 
#     # exec tkcon
#     console .gredconsole
# }

proc gred:cmd:mailto {w} {
    global gred
    SMTP_Box [gred:getGrafcetName $w]_MailBox \
             diam@ensta.fr $gred(userMail)
}