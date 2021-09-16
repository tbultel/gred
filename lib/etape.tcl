########################################################################
# procedure de traitement des objets "etape"<BR>
# nom du programme : gretape.tcl<BR>
# cree le 18/09/96 par commeau@ensta.fr<BR>
# dernieres modifications :<BR>
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
# le 13 Feb 1997 par CARQUEIJAL David : Intégration du UNDO/REDO
#  ça marche bien...
########################################################################

########################################################################
# Etape:add -- creation d'une etape
# 
# 
proc Etape:add {c x y \
               {type Normal} \
               {name {}} \
               {state inactive} \
               {action {}} \
               {file {}} \
               {comment {}}} {
               
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  gred:markDirty .[gred:getGrafcetName $c]
  # On impose les coordonnées sur la grille
  set x [Grid $x]
  set y [Grid $y]

  # definition de l'id de l'etape
  set id [incr grafcet(EtapeUId)]
  set oid oidEtape$id
  
  set dx [expr $gred(etape,height) / 2]
  set dy [expr $gred(etape,height) / 2]
  
  # definition des valeurs par defaut
  set default(name)    [FindNameEtape $c]
  set default(type)    Normal
  set default(state)   inactive
  set default(action)  {}
  set default(file)    {}
  set default(comment) [list [expr $dx+7] [expr -$dy] {}]
  
  # On change le nom par défaut si il existe déjà une étape ayant ce nom
  if {($name != {}) && [Obj:name:exist $c Etape $name]} {
        set name $default(name)
  }
#    else {
#         set default(name) [FindNameEtape $c]
#   }
  
  
  # mise a jour de la base de donnee
  set grafcet($oid)   {}
  set grafcet($oid,x) $x
  set grafcet($oid,y) $y
  
  # L'option vaut l'option passée en paramètre sinon vaut default(...)
  foreach option $gred(etape,options) {
      if {[set $option] != {}} {
          set grafcet($oid,$option) [set $option]
      } else {
          set grafcet($oid,$option) $default($option)
      }
  }

  undo_saveInfos .[gred:getGrafcetName $c] \
                 "Etape:delete $c $oid" \
                 "Etape:addFromUndo $id $c $x $y $type\
                        \"$grafcet($oid,name)\" $state \"$action\"\
                        \"$file\"\
                        \"$comment\""
  
  # On crée les champs command de l'objet. Ce champs permet une sauvegarde
  # rapide du grafcet              
  Etape:updateCommandField $c $oid

  # mise a jour de la representation graphique
  Etape:draw $c $oid

  return $oid
}

########################################################################
# FindNameEtape -- Renvoie un nom pour une étape
# Ce nom est pour l'instant une nombre. Cette procédure renvoie
# un nom non déjà utilisé dans ce grafcet.
########################################################################
proc FindNameEtape {c} {
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  
  while {[Obj:name:exist $c Etape $grafcet(EtapeNameId)]} {
      regexp "^(\[^0-9\]*)(\[0-9\]*)(\[^$]*)$" $grafcet(EtapeNameId)\
                                           match prefixe valeur suffixe
      incr valeur
      set grafcet(EtapeNameId) "$prefixe$valeur$suffixe"
  }
  
  return $grafcet(EtapeNameId)
}

########################################################################
# Etape:addFromPopup -- Procédure permettant d'ajouté une étape
# Procédure permettant d'ajouter une étape de type <I>type</I>. Cette
# procédure ajoute une étape au point de coordonnée:
# (X,Y)=($grafcet(mouse,xPress),$grafcet(mouse,yPress))
########################################################################
proc Etape:addFromPopup {c type} {
  upvar #0 gred.[gred:getGrafcetName $c] grafcet
  Etape:add $c $grafcet(mouse,xPress) $grafcet(mouse,yPress) "$type"
}

########################################################################
# Etape:updateCommandField -- Création d'un champs "command" pour l'étape oid
# Procédure permettant de créer un champs command pour l'étape identifié
# par <I>oid</I>. Ce champs permet une sauvegarde rapide du grafcet.
# Détail important: Les coordonnées de l'étape ne sont pas mémorisées,
# on garde un "pointeur" sur les vrais coordonnées de l'étape... 
########################################################################
proc Etape:updateCommandField {c oid} {
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  set grafcet($oid,command)\
          "Etape:create \
               -coord   \{\[set grafcet.[gred:getGrafcetName $c]($oid,x)\]\
                          \[set grafcet.[gred:getGrafcetName $c]($oid,y)\]\}\
               -name    \{$grafcet($oid,name)\}\
               -state   $grafcet($oid,state)\
               -type    $grafcet($oid,type)\
               -action  \{$grafcet($oid,action)\}\
               -file    \{$grafcet($oid,file)\}\
               -comment \{$grafcet($oid,comment)\}"
}

########################################################################
# Etape:addFromUndo -- Création d'une étape avec un identificateur donné
# Cette fonction permet de créer une nouvelle étape. A la différence de
# la fonction Etape:add qui crée un identificateur en fonction de la
# variable grafcet(EtapeUId), cette fonction crée une étape avec un
# identificateur que l'on passe en paramètre.
# FONCTION A OPTIMISER
########################################################################
proc Etape:addFromUndo {id c x y \
               {type Normal} \
               {name {}} \
               {state inactive} \
               {action {}} \
               {file {}} \
               {comment {}}} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  
  gred:markDirty .[gred:getGrafcetName $c]
  
  # definition de l'id de l'etape
  set oid oidEtape$id
  
  # definition des valeurs par defaut
  set default(name) $id
  set default(type) Normal
  set default(state) inactive
  set default(action) {}
  set default(file) {}
  set default(comment) {}
  
  # mise a jour de la base de donnee
  set grafcet($oid) {}
  set grafcet($oid,x) $x
  set grafcet($oid,y) $y
  
  foreach option $gred(etape,options) {
      if {[set $option] != {}} {
          set grafcet($oid,$option) [set $option]
      } else {
          set grafcet($oid,$option) $default($option)
      }
  }
  
  # On crée le champs command associé à l'étape
  Etape:updateCommandField $c $oid
  
  # mise a jour de la representation graphique
  Etape:draw $c $oid
  
  return $oid
}


########################################################################
# Etape:draw -- Affichage d'une étape
proc Etape:draw {c etapeId} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  # effacement complet de l'etape
  $c delete $etapeId
  
  set type $grafcet($etapeId,type)
  set state $grafcet($etapeId,state)
  set name $grafcet($etapeId,name)
  
  set x $grafcet($etapeId,x)
  set y $grafcet($etapeId,y)
  set dx [expr $gred(etape,height) / 2]
  set dy [expr $gred(etape,height) / 2]
  
  # dessin de la partie gauche  
  $c create rectangle \
    [expr $x - $dx] [expr $y - $dy] [expr $x + $dx] [expr $y + $dy] \
    -outline black -fill white -width $gred(etape,border) \
    -tags "Etape $etapeId GrafcetTag"

  # On dessinne l'étape
  Etape:drawInsideBox:$type $c $x $y $etapeId
  
  set decalage 0
  if { ![string compare $state active] } {
      set decalage 4
      $c create oval [expr $x-$dx/8] [expr $y+$dy/2-1]\
                     [expr $x+$dx/8] [expr $y+3*$dy/4-1]\
                     -fill black -tags "State $etapeId GrafcetTag"
  }
  
  $c create text $x [expr $y-$decalage] -text $name -anchor center \
                       -tags "Name $etapeId GrafcetTag"\
                       -font $gred(fontGrafcet)
                       
  # dessin de la partie droite (action)
  if {$grafcet($etapeId,action) != ""} {
    $c create line \
      [expr $x + $dx] $y [expr $x + $dx + 7] $y \
      -tags "LineRight $etapeId GrafcetTag"
    
    drawActionBox $c [expr $x + $dx + 7 + 4] [expr $y-$dy/2] $etapeId
  }
  
  if {[lindex $grafcet($etapeId,comment) 2] != ""} {
    $c create text [expr $x+[lindex $grafcet($etapeId,comment) 0]]\
                   [expr $y+[lindex $grafcet($etapeId,comment) 1]]\
      -text [lindex $grafcet($etapeId,comment) 2] -anchor sw \
      -fill blue -tags "Comment $etapeId GrafcetTag"\
                    -font $gred(fontGrafcet)
  }  
}

# Dessine un rectangle contenant les informations concernant le champs
# action.
proc drawActionBox {c x y oid} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  
  set dx [expr $gred(etape,height) / 2]
  set dy [expr $gred(etape,height) / 2]
  
  # On centre la boîte d'action si il y a une seule action !
  if {[llength $grafcet($oid,action)] == 1} {
    set y [expr $y+$dy/2]
  }
  set x1 $x
  set y1 $y
  
  set allTextId [list]
  set IdColonne [list]
  set allLineId [list]
  
  # On ecrit le texte en colonne
  foreach indice {0 1 2} {
    # On ecrit les lignes pour chaque colonne
    foreach actionField $grafcet($oid,action) {
      set value [lindex $actionField $indice]
      if {$value != {}} {
        set textId [$c create text $x1 $y1 \
                    -text $value -anchor w \
                    -tags "Value$indice $oid GrafcetTag" \
                    -font $gred(fontGrafcet)]
# #                     -font "-*-*-*-*-*-$gred(fontSize)-*-*-*-*-*-*"
# #                     -font "*-*-*-$gred(fontSize)-*-*-*-*-*-*"
        lappend allTextId $textId
        lappend IdColonne $textId
      }
      set y1 [expr $y1+$dy]
    }
    if {[llength $IdColonne] > 0} {
      set box [eval {$c bbox} $IdColonne]
      set lineId [$c create line [expr [lindex $box 2]+2]\
                                 [expr [lindex $box 1]-2]\
                                 [expr [lindex $box 2]+2]\
                                 [expr [lindex $box 3]+2]\
                                  -tags "lineId $oid GrafcetTag"]
      set x1 [expr [lindex $box 2]+5]
      lappend allLineId $lineId
    }
    set y1 $y
    set IdColonne [list]
  }
  
  $c delete $lineId
  set box [eval {$c bbox} $allTextId]
  set x1 $x
  set y1 $y
  
  # On dessinne le rectangle
  $c create rectangle [expr [lindex $box 0]-2]\
             [expr [lindex $box 1]-2]\
             [expr [lindex $box 2]+2]\
             [expr [lindex $box 3]+2]\
             -tags "rectangle $oid GrafcetTag"\
             -outline black -fill white
             
  # On dessinne les lignes séparant les lignes d'action...
  foreach actionField $grafcet($oid,action) {
    set lineId [$c create line [expr [lindex $box 0]-2] [expr $y1+$dy/2]\
                  [expr [lindex $box 2]+2] [expr $y1+$dy/2] \
      -tags "lineId $oid GrafcetTag"]
    set y1 [expr $y1 + $dy]
  }
  
  # On détruit la dernière ligne
  $c delete $lineId

  foreach id $allTextId {
    $c raise $id
  }
  foreach id $allLineId {
    $c raise $id
  }
}

# Dessine un rectangle contenant les informations concernant le champs
# action. Procédure non utilisée... On utilise "drawActionBox" à la place :-)
proc drawActionBox2 {c x y oid} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  
  set dx [expr $gred(etape,height) / 2]
  set dy [expr $gred(etape,height) / 2]
  
  set x1 $x
  set y1 $y
  set allTextId [list]
  set allLineId [list]
  
  # On ecrit le texte
  foreach actionField $grafcet($oid,action) {
    set symbol [lindex $actionField 0]
    set action [lindex $actionField 1]
    set reference [lindex $actionField 2] 
    
    if {$symbol != {}} {
      set textId1 [$c create text $x1 $y1 \
        -text $symbol -anchor w \
        -tags "SymbolText $oid GrafcetTag"]
      set box [$c bbox $textId1]
      set lineId [$c create line [expr [lindex $box 2]+2]\
                                 [expr [lindex $box 1]-2]\
                                 [expr [lindex $box 2]+2]\
                                 [expr [lindex $box 3]+2]\
                                  -tags "lineId $oid GrafcetTag"]
      set x1 [expr $x1 + ([lindex $box 2]-[lindex $box 0]) + 5]
      lappend allTextId $textId1
      lappend allLineId $lineId
    }
    
    set textId2 [$c create text $x1 $y1 \
        -text $action -anchor w \
        -tags "ActionText $oid GrafcetTag"]
    lappend allTextId $textId2
    
    if {$reference != {}} {
      set box [$c bbox $textId2]
      set lineId [$c create line [expr [lindex $box 2]+2]\
                                 [expr [lindex $box 1]-2]\
                                 [expr [lindex $box 2]+2]\
                                 [expr [lindex $box 3]+2]\
                                  -tags "lineId $oid GrafcetTag"]
      set x1 [expr $x1 + ([lindex $box 2]-[lindex $box 0]) + 5]
      
      set textId3 [$c create text $x1 $y1 \
        -text $reference -anchor w \
        -tags "ReferenceText $oid GrafcetTag"]
      lappend allTextId $textId3
      lappend allLineId $lineId
    }
    
    set textId [list]
    set x1 $x
    set y1 [expr $y1 + $dy]
  }
  
  set box [eval {$c bbox} $allTextId]
  set x1 $x
  set y1 $y
  
  # On dessinne le rectangle
  $c create rectangle [expr [lindex $box 0]-4]\
             [expr [lindex $box 1]-2]\
             [expr [lindex $box 2]+4]\
             [expr [lindex $box 3]+2]\
             -tags "rectangle $oid GrafcetTag"\
             -outline black -fill white
             
  # On dessinne les lignes siparant les lignes d'action...
  foreach actionField $grafcet($oid,action) {
    set lineId [$c create line [expr [lindex $box 0]-4] [expr $y1+$dy/2]\
                  [expr [lindex $box 2]+4] [expr $y1+$dy/2] \
      -tags "lineId $oid GrafcetTag"]
    set y1 [expr $y1 + $dy]
  }
  
  # On ditruit la dernihre ligne
  $c delete $lineId

  foreach id $allTextId {
    $c raise $id
  }
  foreach id $allLineId {
    $c raise $id
  }
}


########################################################################
# Les procédures suivantes permettent de dessinner l'intérieur d'une
# étape. Si on veut créer une nouvelle étape, il faut la rajouter dans la
# liste des étapes:
#     1) Rajouter un type d'étape dans la liste gred(etape,type) ie une 
#        descripton de l'étape en un mot (sans espace :-)
#     2) Rajouter une chaîne de caractéres dans la liste gred(etape,name)
#        décrivant plus précisement le type.
########################################################################
proc Etape:drawInsideBox:Normal {c x y etapeId} {
}
proc Etape:drawInsideBox:Initial {c x y etapeId} {
  global gred
  
  set dx [expr $gred(etape,height) / 2]
  set dy [expr $gred(etape,height) / 2]
  $c create rectangle \
      [expr $x - $dx + 3 ] [expr $y - $dy + 3] \
      [expr $x + $dx - 3] [expr $y + $dy - 3] \
      -outline black -fill white -width $gred(etape,border) \
      -tags "Etape $etapeId GrafcetTag"
}
proc Etape:drawInsideBox:Hyper {c x y etapeId} {
}
proc Etape:drawInsideBox:MacroBegin {c x y etapeId} {
  global gred
  
  set dx [expr $gred(etape,height) / 2]
  set dy [expr $gred(etape,height) / 2]
  $c create line \
         [expr $x - $dx] [expr $y - $dy + 3]\
         [expr $x + $dx] [expr $y - $dy + 3] \
         -width $gred(etape,border) -tags "LineDown $etapeId GrafcetTag"
}
proc Etape:drawInsideBox:MacroEnd {c x y etapeId} {
  global gred
  
  set dx [expr $gred(etape,height) / 2]
  set dy [expr $gred(etape,height) / 2]
  $c create line \
         [expr $x - $dx] [expr $y + $dy - 3] \
         [expr $x + $dx] [expr $y + $dy - 3] \
         -width $gred(etape,border) -tags "LineDown $etapeId GrafcetTag"
}
proc Etape:drawInsideBox:Macro {c x y etapeId} {
    Etape:drawInsideBox:MacroBegin $c $x $y $etapeId
    Etape:drawInsideBox:MacroEnd   $c $x $y $etapeId
}

########################################################################
# Etape:delete -- Destruction de l'étape
# 
# 
# 
proc Etape:delete {c etapeId} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  gred:markDirty .[gred:getGrafcetName $c]
  # destruction de toutes les liaisons liees a l'étape
  set liaisons [Link:getLinks $c -all $etapeId]
  foreach liaison $liaisons {
      Link:delete $c $liaison
  }
 
  # destruction graphique de l'objet
  $c delete $etapeId
  
  regexp "^oidEtape(\[0-9\]+)" $etapeId total id
  undo_saveInfos .[gred:getGrafcetName $c] \
                 "Etape:addFromUndo $id $c $grafcet($etapeId,x)\
                  $grafcet($etapeId,y) $grafcet($etapeId,type)\
                  \"$grafcet($etapeId,name)\" $grafcet($etapeId,state)\
                  \"$grafcet($etapeId,action)\" \"$grafcet($etapeId,file)\"\
                  \"$grafcet($etapeId,comment)\"" \
                 "Etape:delete $c $etapeId"

  # mise a jour de la base de donnee
  # effacement de la variable "etapeId"
  unset grafcet($etapeId)
  # effacement de toutes les sous-variables de "etapeId"  
  set objects [array names grafcet ${etapeId},*]
  foreach object $objects {
    unset grafcet($object)
  }
}

# CREER UNE PROC Etape:changeParamsBox INDEPENDANTE DE Etape:changeParams
# Etape:changeParams ne devra plus etre interactive.

########################################################################
# Les 2 procédures suivantes permettent de trouver la correspondance 
#   - entre le nom d'une étape et son type,
#   - entre le nom d'une type et son étape.
proc Etape:ReturnTypeName {type} {
    global gred
    set match [lsearch -exact $gred(etape,type) $type]
    return [lindex $gred(etape,name) $match]
}
proc Etape:ReturnType {typeName} {
    global gred
    set match [lsearch -exact $gred(etape,name) $typeName]
    return [lindex $gred(etape,type) $match]
}

########################################################################
# Etape:changeParams --
# 
# Modification d'un ou des parametres d'une etape dans la base de donnee
# 
proc Etape:changeParams {c oid what {value {}} } {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  gred:markDirty .[gred:getGrafcetName $c]

  if ![string match "all" $what] {
    set tmp(${oid},x) $grafcet(${oid},x)
    set tmp(${oid},y) $grafcet(${oid},y)
    foreach option $gred(etape,options) {
        set tmp(${oid},$option) $grafcet(${oid},$option)
    }
    
    set tmp($oid,$what) $value
    set grafcet($oid,$what) $value
    
    # On sauvegarde les infos pour le UNDO/REDO	
    undo_saveInfos .[gred:getGrafcetName $c] \
                   "Etape:changeParamsFromUndo $oid $c\
                         $grafcet($oid,type)\
                         \"$grafcet($oid,name)\" $grafcet($oid,state)\
                         \"$grafcet($oid,action)\"\
                         \"$grafcet($oid,file)\"\
                         \"$grafcet($oid,comment)\"" \
                   "Etape:changeParamsFromUndo $oid $c\
                         $tmp($oid,type)\
                         \"$tmp($oid,name)\" $tmp($oid,state)\
                         \"$tmp($oid,action)\" \"$tmp($oid,file)\"\
                         \"$tmp($oid,comment)\""
    unset tmp
  } else {
    # modification de tous les parametres
    # option "file" pas pris en compte
    getInfo $c $oid
    
  }
  Etape:updateCommandField $c $oid
  Etape:draw $c $oid
  Sel:redraw $c
  return
}

########################################################################
# Procédure changeant les paramètres d'une étape pour la procédure de
# undo. Cette procédure marche en batch ie sans ouvrir de fenetre de
# dialogue...
########################################################################
proc Etape:changeParamsFromUndo {oid c type name state {action {}}\
                                 {file {}} {comment {}}} {
    global gred
    upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
    
    set grafcet($oid,type) $type
    set grafcet($oid,name) $name
    set grafcet($oid,state) $state
    set grafcet($oid,action) $action
    set grafcet($oid,file) $file
    set grafcet($oid,comment) $comment
    
    Etape:updateCommandField $c $oid
    Etape:draw $c $oid
    Sel:redraw $c
}

########################################################################
# Etape:create -- Procédure interactive de création d'une étape
# 
# Ex : 
# <CODE>
#  Etape:create -coord {10 10} -name Eta52 -type macro \<BR>
#               -state inactive \<BR>
#               -action "N|action" -file "~commeau/appli/examples" \<BR>
#               -comment "du commentaire"</CODE>
# 
proc Etape:create {c args} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
 
  if { ([string compare $args {}] == 0) || \
       ([expr [llength $args] % 2] != 0) } {
    puts stderr "Etape Error : one option left."
    return
  }
  
  # mise a jour du tableau des options
  array set option $args

  # test des options passees en argument
  # liste des options : coord, type, name, state, action, file, comment

####### DAVID ##########
# set command {Etape:add $c }
  set command "Etape:add $c "
  
  # option "-coord" : coordonnees graphiques de l'etape
  set oid {}
  if { ![info exist option(-coord)] } {
    puts stderr "Etape Error : no coord. given. No graphical representation."
    return
  } elseif { [string compare $option(-coord) {}] == 0 } { 
    puts stderr "Etape Error : empty coord."
    return
  } elseif { [llength $option(-coord)] != 2 } {
    puts stderr "Etape Error : bad format coord."
    return
  }
  lappend command [lindex $option(-coord) 0]
  lappend command [lindex $option(-coord) 1]

  # test de l'existence de toutes les options
  foreach opt $gred(etape,options) {
    if { ![info exist option(-$opt)] } {
      set option(-$opt) {}
    }
  }
  
  # option "-type" : type de l'etape : Normal, Initial, Macro, Hyper
# #   if { [info exist option(-type)] && \
# #        [lsearch -exact {standard initial macro hyper} $option(-type)] == -1} {}
  if { [info exist option(-type)] && \
       [lsearch -exact $gred(etape,type) $option(-type)] == -1} {
    puts stderr "Etape Error : unknown type."
    set option(-type) {}
  }
  lappend command $option(-type)

  # option "-name" : nom generique de l'etape
#   if { [Obj:name:exist $c Etape $option(-name)] == 1 } {
#       set option(-name) [incr grafcet(EtapeUId)]
#   }
  lappend command $option(-name)
  
  # option "-state" : etat dynamique de l'etape : inactive, active
  if { [info exist option(-state)] && \
    [lsearch -exact {active inactive} $option(-state)] == -1} {
    puts stderr "Etape Error : unknown state."
    set option(-state) {}
  }
  lappend command $option(-state)

  # option "-action" : actions associees a l'etape
  lappend command $option(-action)

  # option "-file" : fichier associe a la macro-etape
  lappend command $option(-file)

  # option "-comment" : commentaire a l'etape
  lappend command $option(-comment)
  
  set oid [eval $command]

  # mise a jour de la variable "record"
  Record:add $oid
# puts $command
  return $oid
}

########################################################################
# Etape:modifyParams --
# 
# Procédure interactive de modification des paramètres d'une étape
# 
proc Etape:modifyParams {c name what {value {}} } {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  set oid [Obj:getOidFromName $c Etape $name]
  if {[string length $oid] == 0} {
    puts stderr "Etape Error : Generic Etape Name unknown."
    return
  }    
  
  if { [lsearch -exact $gred(etape,options) $what] == -1 } {
    puts stderr "Etape Error : Parameter unknown."
    return
  }
  
  if { [string compare $what name] == 0 } {
    if { [string compare $value {}] == 0 || \
        [Obj:name:exist $c Etape $value] == 1 } {
      set value [incr grafcet(EtapeUId)]
    }
  }
  Etape:changeParams $c $oid $what $value
}

proc Etape:find {c name} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  
  set oid [Obj:getOidFromName $c Etape $name]
  if {[string length $oid] == 0} {
    gred:status $c "Etape Error : Generic Etape Name unknown."
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