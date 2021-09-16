########################################################################
# programme de traitement des objets "transition"<BR>
# nom du programme : grtransition.tcl<BR>
# crée le 18/09/96 par <A HREF="mailto:commeau@ensta.fr">
# commeau@ensta.fr</A><BR>
# dernières modifications :
# le 10 Feb 1997 par CARQUEIJAL David : ajout d'une variable 
#  gred(grafcets) contenant la liste des grafcets en cours d'édition,
#  chaque élement de la liste contient le nom d'un tableau visible au
#  niveau #0. Le premier élement de la liste correspond au grafcet
#  courant (ie celui en cours d'édition).
# le 11 Feb 1997 par CARQUEIJAL David : Mise en place et utilisation
#  cohérente du flag indiquant si le fichier à été modifié.
# le 12 Feb 1997 par CARQUEIJAL David : Ajout d'un tag Grafcet
#  permettant d'accéder aisement au grafcet courant affiché dans le
#  canvas.
########################################################################


########################################################################
# Trans:add -- Création d'une transition
# 
# 
# 
proc Trans:add {c x y \
                {name {}} \
                {receptivity {}} \
                {comment {}}} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  gred:markDirty .[gred:getGrafcetName $c]
  
  # On impose les coordonnées sur la grille
  set x [Grid $x]
  set y [Grid $y]
  set dx [expr $gred(transition,height) / 2]
  set dy [expr $gred(transition,height) / 2]
  
  # definition de l'id de la transition
  set id [incr grafcet(TransUId)]
  set oid oidTrans$id

  # definition des valeurs par defaut
  set default(name) [FindNameTrans $c]
  set default(receptivity) {}
  set default(comment) [list [expr -1.5*$dx] [expr -2*$dy] {}]
  
  # On change le nom par défaut si il existe déjà une étape ayant ce nom
  if {($name != {}) && [Obj:name:exist $c Trans $name]} {
        set name $default(name)
  }
  
  # mise a jour de la base de donnee
  set grafcet($oid) {}
  set grafcet($oid,x) $x
  set grafcet($oid,y) $y
    
  foreach option $gred(transition,options) {
      if {[set $option] != {}} {
          set grafcet($oid,$option) [set $option]
      } else {
          set grafcet($oid,$option) $default($option)
      }
  }
  
  undo_saveInfos .[gred:getGrafcetName $c] \
                 "Trans:delete $c $oid" \
                 "Trans:addFromUndo $id $c $x $y\
                          \"$grafcet($oid,name)\" \"$receptivity\"\
                          \"$comment\""

  Trans:updateCommandField $c $oid
  # mise a jour de la representation graphique
  Trans:draw $c $oid

  return $oid
}

########################################################################
# FindNametrans -- Renvoie un nom pour une transition
# Ce nom est pour l'instant une nombre. Cette procédure renvoie
# un nom non déjà utilisé dans ce grafcet.
# On peut passer un paramètre optionnelle à cette procédure qui correspond
# à un nom par défault. Si ce nom existe déjà dans le grafcet, la procédure
# en trouve un autre sinon elle renvoie le nom proposé.
########################################################################
proc FindNameTrans {c {name {}}} {
#   upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
#   while {[Obj:name:exist $c Trans $grafcet(TransNameId)]} {
#       set name [incr grafcet(TransNameId)]
#   }
#   
#   return $grafcet(TransNameId)
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  
  while {[Obj:name:exist $c Trans $grafcet(TransNameId)]} {
      regexp "^(\[^0-9\]*)(\[0-9\]*)(\[^$]*)$" $grafcet(TransNameId)\
                                           match prefixe valeur suffixe
      incr valeur
      set grafcet(TransNameId) "$prefixe$valeur$suffixe"
  }
  
  return $grafcet(TransNameId)
}

proc Trans:addFromPopup {c} {
    upvar #0 gred.[gred:getGrafcetName $c] grafcet
    Trans:add $c $grafcet(mouse,xPress) $grafcet(mouse,yPress)
}

proc Trans:updateCommandField {c oid} {
    upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
    set grafcet($oid,command)\
            "Trans:create \
                 -coord   \{\[set grafcet.[gred:getGrafcetName $c]($oid,x)\]\
                            \[set grafcet.[gred:getGrafcetName $c]($oid,y)\]\}\
                 -name \{$grafcet($oid,name)\}\
                 -receptivity \{$grafcet($oid,receptivity)\}\
                 -comment \{$grafcet($oid,comment)\}"
# puts $grafcet($oid,command)
}

########################################################################
# Trans:addFromUndo -- creation d'une transition avec un identificateur donné
# Cette fonction permet de créer une nouvelle transition. A la différence de
# la fonction transition:add qui crée un identificateur en fonction de la
# variable grafcet(transitionUId), cette fonction crée une transition avec un
# identificateur que l'on passe en paramètre.
# FONCTION A OPTIMISER
proc Trans:addFromUndo {id c x y \
                    {name {}} \
                    {receptivity {}} \
                    {comment {}}} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  gred:markDirty .[gred:getGrafcetName $c]
  
  # On impose les coordonnées sur la grille
  set x [Grid $x]
  set y [Grid $y]
  
  # definition de l'id de la transition
  set oid oidTrans$id

  # definition des valeurs par defaut
  set default(name) $id
  set default(receptivity) {}
  set default(comment) {}
  
  # mise a jour de la base de donnee
  set grafcet($oid) {}
  set grafcet($oid,x) $x
  set grafcet($oid,y) $y
    
  foreach option $gred(transition,options) {
      if {[set $option] != {}} {
          set grafcet($oid,$option) [set $option]
      } else {
          set grafcet($oid,$option) $default($option)
      }
  }

  Trans:updateCommandField $c $oid
  # mise a jour de la representation graphique
  Trans:draw $c $oid

  return $oid
}

########################################################################
# Trans:draw -- Affichage de la transition
# 
# 
# 
proc Trans:draw {c transitionId} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  # effacement complet de la transition
  $c delete $transitionId
  
  set x $grafcet($transitionId,x)
  set y $grafcet($transitionId,y)
  set dx [expr $gred(transition,width) / 2]
  set dy [expr $gred(transition,height) / 2]

  # dessin de la partie gauche
  $c create rectangle \
    [expr $x - $dx] [expr $y - $dy] [expr $x + $dx] [expr $y + $dy] \
    -fill black -tags "Transition $transitionId GrafcetTag"
#   $c create line \
    $x [expr $y + $dy] $x [expr $y + $dy + $gred(transition,link)] \
    -tags "LineUp $transitionId GrafcetTag"
#   $c create line \
    $x [expr $y - $dy] $x [expr $y - $dy - $gred(transition,link)] \
    -tags "LineDown $transitionId GrafcetTag"

  
  # dessin de la partie droite (name + receptivite + commentaire)
  
  set text $grafcet($transitionId,name)
  if {$gred(transition,showName)} {
      $c create text [expr $x - 1.5 * $dx] $y  \
        -text $text -anchor e -tags "Receptivity $transitionId GrafcetTag"\
        -font $gred(fontGrafcet)
  }
  
  if {[info exist grafcet($transitionId,receptivity)]} {
      $c create text [expr $x + 1.5 * $dx] $y  \
        -text $grafcet($transitionId,receptivity) \
        -anchor w -tags "Receptivity $transitionId GrafcetTag"\
        -font $gred(fontGrafcet)
  }
  if { [info exist grafcet($transitionId,comment)] } {
    $c create text [expr $x+[lindex $grafcet($transitionId,comment) 0]] \
                   [expr $y+[lindex $grafcet($transitionId,comment) 1]] \
      -text [lindex $grafcet($transitionId,comment) 2] -anchor se \
      -fill blue -tags "Comment $transitionId GrafcetTag"\
      -font $gred(fontGrafcet)
  }  

}


########################################################################
# Trans:delete -- Destruction de la transition
# 
# 
# 
proc Trans:delete {c transitionId} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  gred:markDirty .[gred:getGrafcetName $c]
  
  # destruction des liaisons
  set liaisons [Link:getLinks $c -all $transitionId]
  foreach liaison $liaisons {
      Link:delete $c $liaison
  }
#   foreach liaison $liaisons {
#     # suppression de la liaison de la base de donnee
#     unset grafcet($liaison)
#     # effacement de la liaison
#     catch {$c delete $liaison}
#   }
  
  # destruction graphique de l'objet
  $c delete $transitionId
  
  regexp "^oidTrans(\[0-9\]+)" $transitionId match id
  undo_saveInfos .[gred:getGrafcetName $c] \
                 "Trans:addFromUndo $id $c $grafcet($transitionId,x)\
                  $grafcet($transitionId,y)\
                  \"$grafcet($transitionId,name)\"\
                  \"$grafcet($transitionId,receptivity)\"\
                  \"$grafcet($transitionId,comment)\"" \
                 "Trans:delete $c $transitionId"
    
  # mise a jour de la base de donnee
  # effacement de la variable "transitionId"
  unset grafcet($transitionId)
  # effacement de toutes les sous-variables de "transitionId"  
  set objects [array names grafcet ${transitionId},*]
  foreach object $objects {
    unset grafcet($object)
  }
}

########################################################################
# Trans:changeParams --
# 
# Modification d'un ou des parametres d'une transition dans la base de 
# donnée
# 
proc Trans:changeParams {c oid what {value {}} } {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  gred:markDirty .[gred:getGrafcetName $c]
    
  if { [string compare $what all] != 0 } {
    set tmp(${oid},x) $grafcet(${oid},x)
    set tmp(${oid},y) $grafcet(${oid},y)
    foreach option $gred(transition,options) {
      if { ![info exist grafcet(${oid},$option)] } {
        set tmp(${oid},$option) {}
      } else {
        set tmp(${oid},$option) $grafcet(${oid},$option)
      }
    }
    
    set tmp($oid,$what) $value
    set grafcet($oid,$what) $value
    
    undo_saveInfos .[gred:getGrafcetName $c] \
                   "Trans:changeParamsFromUndo $oid $c\
                         \"$grafcet($oid,name)\"\
                         \"$grafcet($oid,receptivity)\"\
                         \"$grafcet($oid,comment)\"" \
                   "Trans:changeParamsFromUndo $oid $c\
                         \"$tmp($oid,name)\"\
                         \"$tmp($oid,receptivity)\"\
                         \"$tmp($oid,comment)\""
  } else {
    # modification de tous les parametres
    # option "file" pas pris en compte"
    global tmp

    set tmp(${oid},XYPosition) "($grafcet(${oid},x),$grafcet(${oid},y))"
    set tmp(${oid},commentPositionX) [lindex $grafcet($oid,comment) 0]
    set tmp(${oid},commentPositionY) [lindex $grafcet($oid,comment) 1]
    
    foreach option $gred(transition,options) {
      if { ![info exist grafcet(${oid},$option)] } {
        set tmp(${oid},$option) {}
      } else {
        set tmp(${oid},$option) $grafcet(${oid},$option)
      }
    }
    set tmp($oid,comment) [lindex $grafcet($oid,comment) 2]
    
    Prompt_Box 	\
               -title "Changer les paramètres de la transition $tmp($oid,name)"\
               -parent .top \
               -entries [subst { 
    {-type SEPARATOR -line down \
      -label "Modification des parametres de la transition $tmp($oid,name)"}
    {-type ENTRY -variable tmp($oid,XYPosition) \
                 -lock 1 -label "Coordonnees graphiques (X,Y)"} 
    {-type SEPARATOR -line down} 
    {-type ENTRY -label "Nom generique" -default [list $tmp($oid,name)] \
      -variable tmp($oid,name)}
    {-type SEPARATOR -line down} 
    {-type ENTRY -label "receptivite" -default [list $tmp($oid,receptivity)] \
      -variable tmp($oid,receptivity)}
    {-type SEPARATOR -line down} 
    {-type ENTRY -label "commentaire" -default [list $tmp($oid,comment)] \
      -variable tmp($oid,comment)}}]
      
    # On recolle les informations concernant le commentaire
    set tmp($oid,comment) [list $tmp(${oid},commentPositionX)\
                                $tmp(${oid},commentPositionY)\
                                $tmp(${oid},comment)]
                                    
    undo_saveInfos .[gred:getGrafcetName $c] \
                   "Trans:changeParamsFromUndo $oid $c\
                         \"$grafcet($oid,name)\"\
                         \"$grafcet($oid,receptivity)\"\
                         \"$grafcet($oid,comment)\"" \
                   "Trans:changeParamsFromUndo $oid $c\
                         \"$tmp($oid,name)\"\
                         \"$tmp($oid,receptivity)\"\
                         \"$tmp($oid,comment)\""
        
    # prise en compte des valeurs
    foreach option $gred(transition,options) {
      # pour l'option "name" :
      # si un nouveau nom generic a ete saisi et que ce nouveau nom
      # exist alors alarme sonore et pas de modif.
      if {[string compare $option name] == 0 } {
        if { [string compare $tmp(${oid},name) $grafcet(${oid},name)] != 0 && \
             ([Obj:name:exist $c Trans $tmp(${oid},name)] == 1 || \
             [string compare $tmp(${oid},name) {}] == 0)} {
          set tmp(${oid},name) $grafcet(${oid},name)
          bell
        }
      }
      set grafcet($oid,$option) $tmp(${oid},$option)
    }
    unset tmp
  }
  
  Trans:updateCommandField $c $oid
  Trans:draw $c $oid
  foreach link [Link:getLinks $c -all $oid] {
      Link:draw $c $link
  }
  Sel:redraw $c
}

proc Trans:changeParamsFromUndo {oid c name {receptivity {}}\
                                 {comment {}}} {
    global gred
    upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
    set grafcet($oid,name) $name
    set grafcet($oid,receptivity) $receptivity
    set grafcet($oid,comment) $comment
    
    Trans:draw $c $oid
    foreach link [Link:getLinks $c -all $oid] {
        Link:draw $c $link
    }
    Sel:redraw $c
}

########################################################################
# Trans:create -- Procédure interactive de création d'une transition
# 
# Ex.: 
# <CODE>Trans:create -coord {10 10} -name Tra32 \<BR>
#                    -receptivity "A+B" \<BR>
#                    -comment "du commentaire" </CODE>
# 
proc Trans:create {c args} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  if { ([string compare $args {}] == 0) || \
       ([expr [llength $args] % 2] != 0) } {
    puts stderr "Transition Error : one option left."
    return
  }

  # mise a jour du tableau des options
  array set option $args

  # test des options passees en argument
  # liste des options : coord, name, receptivity, comment
###### DAVID ########
# set command {Trans:add $c }

  set command "Trans:add $c "

  # option "-coord" : coordonnees graphiques de la transition
  set oid {}
  if { ![info exist option(-coord)] } {
    puts stderr "Transition Error : no coord. given. \
      No graphical representation."
    return
  } elseif { [string compare $option(-coord) {}] == 0 } { 
    puts stderr "Transition Error : empty coord."
    return
  } elseif { [llength $option(-coord)] != 2 } {
    puts stderr "Transition Error : bad format coord."
    return
  }
  lappend command [lindex $option(-coord) 0]
  lappend command [lindex $option(-coord) 1]
  
  # test de l'existence de toutes les options
  foreach opt $gred(transition,options) {
    if { ![info exist option(-$opt)] } {
      set option(-$opt) {}
    }
  }
  
  # option "-name" : nom generique de la transition
#   if { [Obj:name:exist $c Trans $option(-name)] == 1 } {
#       set option(-name) [incr grafcet(TransUId)]
#   }
  lappend command $option(-name)
  
  # option "-receptivity" : receptivite associee a la transition
  lappend command $option(-receptivity)
  
  # option "-comment" : commentaire associe a la transition
  lappend command $option(-comment)

  set oid [eval $command]

  # mise a jour de la variable "record"
  Record:add $oid
  
  return $oid
}

########################################################################
# Trans:modifyParams --
# 
# Procédure interactive de modification des paramètres d'une transition
# 
proc Trans:modifyParams {c name what {value {}} } {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  set oid [Obj:getOidFromName $c Trans $name]
  if {[string length $oid] == 0} {
    puts stderr "Transition Error : Generic Transition Name unknown."
    return
  }    
  
  if { [lsearch -exact $gred(transition,options) $what] == -1 } {
    puts stderr "Transition Error : Parameter unknown."
    return
  }
  
  if { [string compare $what name] == 0 } {
    if { [string compare $value {}] == 0 || \
        [Obj:name:exist $c Trans $value] == 1 } {
      set value [incr grafcet(TransUId)]
    }
  }
  Trans:changeParams $c $oid $what $value
}

proc Trans:find {c name} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  
  set oid [Obj:getOidFromName $c Trans $name]
  if {[string length $oid] == 0} {
    gred:status $c "Etape Error : Generic Transition Name unknown."
    return
  }
  
  Sel:clear $c
 
  Sel:new $c $oid 
  
  set x $grafcet($oid,x)
  set y $grafcet($oid,y)
  set scrollRegion [$c cget -scrollregion]
  set canvasWidth  [winfo pixels $c [lindex $scrollRegion 2]]
  set canvasHeight [winfo pixels $c [lindex $scrollRegion 3]]
  $c xview moveto [expr double($x)/double($canvasWidth)-0.1]
  $c yview moveto [expr double($y)/double($canvasHeight)-0.1]
}