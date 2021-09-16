########################################################################
# Package affichant une boite de dialogue permettant la saisie 
# d'information pour une étape.
# Dans ce package, on utilise le tableau temporaire tmp pour faire
# passer des informations de procédures en procédures.
# Ce tableau existe durant l'ouverture de la fenetre "getInfo" et
# disparait ensuite.


# getInfo -- Crée une fenêtre permettant de saisir des valeurs
# Procédure principale: crée une fenêtre permettant de saisir des valeurs.
# Les informations sont conservees temporairement dans un tableau de
# nom tmp (A CHANGER... Utiliser la portée des noms ? Nvelle fonctionnalité
# De la version 8.0 ????)
proc getInfo {c oid} {
  global gred
  global tmp
  
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  
  set w .getInfo
  
  getInfoInitValues $w $c $oid
  
  getInfo_MakeToplevel $w $c $oid
  
  set oldFocus [focus]
  set oldGrab [grab current $w]
  if {$oldGrab != ""} {
      set grabStatus [grab status $oldGrab]
  }

  grab $w

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
    tkwait variable tmp(button)
    switch -exact -- $tmp(button) {
      ok {
        break
      }
      cancel {
        destroy $w
        unset tmp
        bind .[gred:getGrafcetName $c] <Visibility> {}
        return
      }
      reset {
        getInfoResetValues $w $c $oid
      }
      default {
        bgerror "Internal error"
      }
    }
  }
  # Arrive ici, on a appuye sur ok... On traite les informations...
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
  updateOidField $c $oid
  puts $grafcet($oid,comment)
  destroy $w
  unset tmp
  bind .[gred:getGrafcetName $c] <Visibility> {}
}

# Initialise les valeurs du tableau tmp en fonction de la valeur de l'oid.
proc getInfoInitValues {w c oid} {
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  global gred
  global tmp
  set tmp(name)    $grafcet($oid,name)
  set tmp(type)    [Etape:ReturnTypeName $grafcet($oid,type)]
  set tmp(state)   $grafcet($oid,state)
  set tmp(comment) [lindex $grafcet($oid,comment) 2]
  
  set tmp(file) BIDON
  set i 0
  foreach el $grafcet($oid,action) {
    set tmp($i,symbol) [lindex $el 0]
    set tmp($i,action) [lindex $el 1]
    set tmp($i,reference) [lindex $el 2]
    incr i
  }
}

# Permet de faire un reset des valeurs du tableau tmp. On remet les infomations
# initiales en fonction de l'oid.
proc getInfoResetValues {t c oid} {
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  global gred
  global tmp
  
  set tmp(name)    $grafcet($oid,name)
  set tmp(type)    [Etape:ReturnTypeName $grafcet($oid,type)]
  set tmp(state)   $grafcet($oid,state)
  set tmp(comment) [lindex $grafcet($oid,comment) 2]
  
  set tmp(file) BIDON
 
  set i 0
  while {$i <= $tmp(nbAction)} {
    if {[set action [lindex $grafcet($oid,action) $i]] != {}} {
      # Anciennes cases
      set tmp($i,symbol) [lindex $action 0]
      set tmp($i,action) [lindex $action 1]
      set tmp($i,reference) [lindex $action 2]
    } else {
      # Cases nouvelles crées
      set tmp($i,symbol) ""
      set tmp($i,action) ""
      set tmp($i,reference) ""
    }
    incr i
  }
}

# Crée un champ action dans le tableau tmp. Ce champs est constitue d'une liste
# crée à partir des différents valeurs du tableau tmp.
proc updateOidField {c oid} {
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  global tmp
  global gred
  
  # On cree un champ action au tableau tmp... Ce champs est calcule en fonction
  # des champs symbol, reference et action issues du widget...
  set i 0
  set tmp(action) [list]
  while {$i <= $tmp(nbAction)} {
    if {($tmp($i,symbol) != {})
        || ($tmp($i,action) != {})
        || ($tmp($i,reference) != {})} {
      lappend tmp(action) [list "$tmp($i,symbol)" "$tmp($i,action)"\
                                "$tmp($i,reference)"]
    }
#     unset tmp($i,symbol) tmp($i,action) tmp($i,reference)
    incr i
  }
  set tmp(comment) [list [lindex $grafcet($oid,comment) 0]\
                         [lindex $grafcet($oid,comment) 1]\
                         "$tmp(comment)"]
  set tmp(type) [Etape:ReturnType "$tmp(type)"]
  # On sauvegarde les infos pour le UNDO/REDO	
  undo_saveInfos .[gred:getGrafcetName $c] \
                 "Etape:changeParamsFromUndo $oid $c\
                       $grafcet($oid,type)\
                       \"$grafcet($oid,name)\" $grafcet($oid,state)\
                       \"$grafcet($oid,action)\"\
                       \"$grafcet($oid,file)\"\
                       \"$grafcet($oid,comment)\"" \
                 "Etape:changeParamsFromUndo $oid $c\
                       $tmp(type)\
                       \"$tmp(name)\" $tmp(state)\
                       \"$tmp(action)\" \"$tmp(file)\"\
                       \"$tmp(comment)\""
  
  # prise en compte des valeurs
  foreach option $gred(etape,options) {
    # pour l'option "name" :
    # si un nouveau nom generic a ete saisi et que ce nouveau nom
    # exist ou le nom est vide alors alarme sonore et pas de modif.
    if {[string compare $option name] == 0 } {
      if { [string compare $tmp(name) $grafcet(${oid},name)] != 0 && \
           ([Obj:name:exist $c Etape $tmp(name)] == 1 || \
           [string compare $tmp(name) {}] == 0)} {
        set tmp(name) $grafcet(${oid},name)
        bell
      }
    }
    set grafcet($oid,$option) $tmp($option)
  }
}

########################################################################
# PromptMakeButtons --
# Dessine une 3 bouttons dans une frame de nom $f.buttons.
# Un boutton Cancel qui ferme la fenetre
# Un boutton Reset qui reset les champs de chaque Prompt
# Un boutton Close qui ferme la fenetre et renvoie la liste des Prompt
#   a l'application
########################################################################
proc getInfoMakeButtons {f} {
  global tmp
  global gred
  
  set w $f.buttons
  
  frame $w -relief flat -borderwidth 1
  pack $w -side bottom -fill x 
  # Les bouttons n'auront ne seront pas selectionnables pas <Tab> 
  # et <Shift-Tab>
  button $w.cancel -text "Cancel" \
                   -padx 5m  -pady 2m -takefocus 0 \
                   -command "set tmp(button) cancel"

  button $w.reset -text "Reset"\
                  -padx 5m  -pady 2m -takefocus 0\
                  -command "set tmp(button) reset"
              
  frame $w.ok -borderwidth 1m -relief sunken
  button $w.ok.b -text "Ok" \
                 -padx 5m  -pady 2m -takefocus 0 \
                 -command "set tmp(button) ok"
  
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
  bind $f <$gred(Meta)-c> "set tmp(button) cancel"
  bind $f <Escape> "set tmp(button) cancel"
  bind $f <$gred(Meta)-r> "set tmp(button) reset"
  bind $f <$gred(Meta)-o> "set tmp(button) ok"
  bind $f <Return> "set tmp(button) ok"

  # On selectionne la valeur d'une entry lors que l'entry est selectionnee
  # bind PromptEntry <FocusIn> \
  #            "%W select clear
  #             %W select range 0 end"
} ; # endproc PromptMakeButtons

# Install et crée une nouvelles toplevel.
# On Installe le protocole de destruction de la fenetre, son titre, son icone,
# etc...
proc getInfo_MakeToplevel {t c oid} {
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  if [winfo exists $t] {
    gred:status $c "Can't create $t"
    return
  }
  toplevel $t -class getInfo
  wm title $t "Changer les paramètres de l'étape $grafcet($oid,name)"
  wm iconname $t "Changer les paramètres de l'étape $grafcet($oid,name)"
  
  # Si on ferme la fenetre on renvoie un resultat. L'utilisateur voit
  # Le boutton Cancel s'invoquer avant la fermeture de la fenetre.
  # C plus clair pour lui ! Fermer la fenetre equivaut a appuyer sur 
  # Cancel !
  wm protocol $t WM_DELETE_WINDOW "PromptInvokeButton $t.buttons.cancel"
  # On recupere l'ancienne fenetre active (Celle qui execute la procedure
  # Prompt_Box en fait. On laisse la joie au gestionnaire de fenetre de
  # gerer les fenetres olFocus et la fenetre ouverte par Prompt_Box (ici 
  # il s'agit de $w). Pour fvwm par exemple si on iconifie $oldFocus 
  # ca iconifie $w. Et $w sera TOUJOURS devant $w. 
  set oldFocus [focus]
  wm transient $t $oldFocus
  
  getInfoPackAll $t $c $oid
  
  set x [expr [winfo screenwidth $t]/2 - [winfo reqwidth $t]/2 \
              - [winfo vrootx [winfo parent $t]]]
  set y [expr [winfo screenheight $t]/2 - [winfo reqheight $t]/2 \
          - [winfo vrooty [winfo parent $t]]]
  wm geom $t +$x+$y
  wm deiconify $t
  
  bind .[gred:getGrafcetName $c] <Visibility> [subst {
    if {\[string match .[gred:getGrafcetName $c] %W\]} {
      raise $t
      focus $t
    }
  }]
  
  update idletasks
}

# Pack les différents éléments de la fenêtre.
# Les differentes lignes packées sont séparées par des "#######"
proc getInfoPackAll {t c oid} {
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  global tmp
  global gred
  
  set tmp(length) 30
  set tmp(width)  50
  ###################################################################
  set w $t.coord
  frame $w -borderwidth 2
  label $w.text \
              -text "Coordonnées graphiques (X,Y)" \
              -width $tmp(length) -anchor w
  label $w.entry \
              -text "($grafcet($oid,x),$grafcet($oid,y))" \
              -relief flat -anchor w -justify left \
              -width $tmp(width)
  
  pack $w.text -side left
  pack $w.entry -side left
  pack $w -side top -fill x
  
  ####################################################################
  frame $t.sep1 -height 2 -width 2 \
                -borderwidth 1 -relief raised
  pack $t.sep1 -fill x -side top
  ####################################################################
  set w $t.name
  frame $w -borderwidth 2
  label $w.text \
              -text "Nom générique" \
              -width $tmp(length) -anchor w
  entry $w.entry -relief sunken -width $tmp(width) \
             -textvariable tmp(name)
  
  pack $w.text -side left -fill x
  pack $w.entry -side left -expand yes -fill x
  pack $w -side top -fill x
  ####################################################################
  frame $t.sep2 -height 2 -width 2 \
                -borderwidth 1 -relief raised
  pack $t.sep2 -fill x -side top
  ####################################################################
  set w $t.type
  frame $w -borderwidth 2
  label $w.text -text "Type de l'étape" \
                -width $tmp(length) -anchor w
  frame $w.radio
  set choices $gred(etape,name)
  set indice2 0
  set nbcolonnes 2
  set valueTypeForOid [Etape:ReturnTypeName $grafcet($oid,type)]
  
  foreach choice $choices {
      radiobutton $w.radio.radio_${indice2} \
          -text $choice \
          -value $choice \
          -variable tmp(type)
      grid $w.radio.radio_${indice2} \
            -row [expr int(${indice2}/$nbcolonnes)]\
            -column [expr ${indice2} % $nbcolonnes] \
            -sticky w
      if {$valueTypeForOid == $choice} {
          $w.radio.radio_${indice2} select
      } else { 
          $w.radio.radio_${indice2} deselect
      }
      incr indice2
  }
  pack $w.text -side left
  pack $w.radio -side left
  pack $w -side top -fill x
  ####################################################################
  frame $t.sep3 -height 2 -width 2 \
                -borderwidth 1 -relief raised
  pack $t.sep3 -fill x -side top
  ####################################################################
  set w $t.etat
  frame $w -borderwidth 2
  label $w.text -text "Etat de l'étape" \
                -width $tmp(length) -anchor w
  frame $w.radio
  set choices $gred(etape,state)
  set indice2 0
  set nbcolonnes 2
      
  foreach choice $choices {
      radiobutton $w.radio.radio_${indice2} \
          -text $choice \
          -value $choice \
          -variable tmp(state)
      grid $w.radio.radio_${indice2} \
            -row [expr int(${indice2}/$nbcolonnes)]\
            -column [expr ${indice2} % $nbcolonnes] \
            -sticky w
      if {$grafcet($oid,state) == $choice} {
          $w.radio.radio_${indice2} select
      } else { 
          $w.radio.radio_${indice2} deselect
      }
      incr indice2
  }
  pack $w.text -side left
  pack $w.radio -side left
  pack $w -side top -fill x
  ####################################################################
  frame $t.sep4 -height 2 -width 2 \
                -borderwidth 1 -relief raised
  pack $t.sep4 -fill x -side top
  ####################################################################
  set w $t.comment
  frame $w -borderwidth 2
  label $w.text \
              -text "Commentaire" \
              -width $tmp(length) -anchor w
  entry $w.entry -relief sunken -width $tmp(width) \
             -textvariable tmp(comment)
  
  pack $w.text -side left -fill x
  pack $w.entry -side left -expand yes -fill x
  pack $w -side top -fill x
  ####################################################################
  frame $t.sep5 -height 2 -width 2 \
                -borderwidth 1 -relief raised
  pack $t.sep5 -fill x -side top
  ####################################################################
  set w $t.action
  set tmp(nbAction) -1
  frame $w
  foreach el $grafcet($oid,action) {
    addNewActionField $w
  }
  addNewActionField $w
  addbutton $w
  
  pack $w -side top -fill x
  
  getInfoMakeButtons $t
}

# Procédures rajoutant une nouvelle ligne d'action 
proc addNewAction {t} {
  global tmp
  
  destroy $t.action$tmp(nbAction).more
  addNewActionField $t
  addbutton $t
  focus $t.action$tmp(nbAction).symbol$tmp(nbAction)
}

# Procédure ajoutant un bouton permettant de rajouter des lignes d'action
proc addbutton {w} {
  global tmp
  button $w.action$tmp(nbAction).more -text "+" -command "addNewAction $w"\
                           -padx 10 -pady 1
  pack $w.action$tmp(nbAction).more -side left -fill x
}

# Procédure ajoutant un bouton permettant de rajouter une ligne d'action
# Dans 7 procédure on crée seulement les 3 entries pour saisir les
# données symbole, action et reference.
proc addNewActionField {t} {
  global tmp
  global gred
  
  incr tmp(nbAction)
  set w $t.action$tmp(nbAction)
  frame $w
  label $w.text$tmp(nbAction) \
              -text "Action $tmp(nbAction)" \
              -width $tmp(length) -anchor w
  entry $w.symbol$tmp(nbAction) -relief sunken -width 3 \
                 -textvariable tmp($tmp(nbAction),symbol)
  entry $w.action$tmp(nbAction) -relief sunken -width $tmp(width) \
                 -textvariable tmp($tmp(nbAction),action)
  entry $w.reference$tmp(nbAction) -relief sunken -width 3 \
                 -textvariable tmp($tmp(nbAction),reference)
  pack $w.text$tmp(nbAction) -side left
  pack $w.symbol$tmp(nbAction) -side left
  pack $w.action$tmp(nbAction) -side left
  pack $w.reference$tmp(nbAction) -side left
  
  pack $w -side top -fill x
}