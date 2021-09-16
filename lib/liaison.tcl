########################################################################
# procédure de traitement des objets "liaison "
# nom du programme : grliaison.tcl
# cree le 18/09/96 par commeau@ensta.fr
# dernieres modifications :
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
# Link:add -- création d'une liaison
# Ajouter les coordonnées du lien.
# 
# 
proc Link:add {c oidSource oidDesti {points {}}} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  gred:markDirty .[gred:getGrafcetName $c]
  
  # $oidSource ou $oidDesti n'existe pas !
  if {![info exists grafcet($oidSource)]\
      || ![info exists grafcet($oidDesti)]} {
      gred:status .[gred:getGrafcetName $c] \
          "Impossible de créer la liaison entre $oidSource et $oidDesti..."
      return
  }
  
  # Test de l'existence de la liaison
  if { [Link:exist $c $oidSource $oidDesti] == 1 } {
    bell;bell
    return
  }
  set loid [Obj:newLinkOid $c $oidSource $oidDesti]
  set grafcet($loid) {}
  regexp "^oidLink(\[0-9\]+)" $loid match id
  undo_saveInfos .[gred:getGrafcetName $c] \
                 "Link:delete $c $loid" \
                 "Link:addFromUndo $id $c $oidSource $oidDesti"
                 
  # affichage de la liaison
  Link:draw $c $loid
  return $loid
}

# Link:getCommandField --
# Crée un champs commande qui permet de re-créer rapidement la liaison
# Ceci accélère le refresh et la sauvegarde du grafcet.
proc Link:getCommandField {c loid oidSource oidDesti} {
    upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
    set command "Link:create "
    if { [Obj:getType $oidSource] == "Etape" } {
      lappend command -source E$grafcet($oidSource,name)
    } else {
      lappend command -source T$grafcet($oidSource,name)
    }
    if { [Obj:getType $oidDesti] == "Etape" } {
      lappend command -desti E$grafcet($oidDesti,name)
    } else {
      lappend command -desti T$grafcet($oidDesti,name)
    }
    return $command
}

########################################################################
# Link:addFromUndo -- creation d'une liaison avec un identificateur donné
# Cette fonction permet de créer une nouvelle liaison. A la différence de
# la fonction liaison:add qui crée un identificateur en fonction de la
# variable grafcet(liaisonUId), cette fonction crée une liaison avec un
# identificateur que l'on passe en paramètre.
# FONCTION A OPTIMISER
proc Link:addFromUndo {id c oidSource oidDesti {points {}}} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  gred:markDirty .[gred:getGrafcetName $c]

  # Test de l'existence de la liaison
  if { [Link:exist $c $oidSource $oidDesti] == 1 } {
    bell;bell
    return
  }
  
  set loid [Obj:newLinkOid $c $oidSource $oidDesti $id]
  set grafcet($loid) {}
 
  # affichage de la liaison
  Link:draw $c $loid
  return $loid
}

########################################################################
# Link:draw -- Affichage de la liaison
# A revoir pour gérer la gestion des liens. Ajouter les coordonnées
# du lien, et dessinner le liens en conséquences :-)
# 
proc Link:draw {c loid} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  set a 2
  set desti     [Link:getLinkDesti $loid]
  set source    [Link:getLinkSource $loid]
  set direction [Link:getLinkDirection $loid]

  # prevoir eventuellement une procedure "gred:getEtapeFromLink $loid"
  # une procedure "gred:getTransFromLink $loid" 
  if { [Obj:getType $source] == "Etape" } {
    set etape $source
    set transition $desti
  } else {
    set etape $desti
    set transition $source
  }
  
  set src(Etape_Trans) etape
  set src(Trans_Etape) transition
  set dst(Etape_Trans) transition
  set dst(Trans_Etape) etape
  set s(Etape_Trans) +
  set s(Trans_Etape) -
  set ns(Etape_Trans) -
  set ns(Trans_Etape) +
  set comp(Etape_Trans) >=
  set comp(Trans_Etape) <=

  # effacement de la double ligne 
  set items [$c find withtag $transition]
  foreach item $items {
    if { [lsearch -exact [$c gettags $item] DoubleLine${direction}] != -1 } {
      $c delete $item
    }
  }
  
  set liaisons [Link:getLinks $c -$direction $transition]
  if { [llength $liaisons] == 1 } {
    # effacement de l'ancienne liaison
    $c delete $liaisons
    set x1 $grafcet([set $src($direction)],x)
    set y1 [expr $grafcet([set $src($direction)],y) \
      + ($gred($src($direction),height)/2)]
    set x2 $grafcet([set $dst($direction)],x)
    set y2 [expr $grafcet([set $dst($direction)],y) \
      - ($gred($dst($direction),height)/2)]
    # test des placements etapes/transitions
    if {[expr $y2 - $y1] <= 0 } {
      if { [expr $x1 - $x2] <= 10 && [expr $x1 - $x2] >= -10 } {
        set xmiddle [expr $x1 - 30]
      } else {
        set xmiddle [expr ($x1 + $x2) / 2]
      }
      set coords [concat \
        $x1 $y1 \
        $x1 [expr $y1 + 5] \
        $xmiddle  [expr $y1 + 5] \
        $xmiddle [expr $y2 - 5] \
        $x2 [expr $y2 - 5] \
        $x2 $y2]
      # Coordonnées de la flèche
      set fleche [concat \
         [expr $xmiddle-7] [expr ($y1+$y2)/2+10] \
         [expr $xmiddle]   [expr ($y1+$y2)/2] \
         [expr $xmiddle+7] [expr ($y1+$y2)/2+10]]
    } else {
      # On décale la cassure de quelque pixel vers le haut ou vers le bas
      if {[expr $x2 - $x1] <= 0 } {
        set deltay 1
      } else {
        set deltay -1
      }
      set ymiddle [expr ($y1 + $y2) / 2]
      set coords [concat $x1 $y1\
                         $x1 [expr $ymiddle+$deltay*3]\
                         $x2 [expr $ymiddle+$deltay*3]\
                         $x2 $y2]
#       set coords [concat $x1 $y1 $x1 $ymiddle $x2 $ymiddle $x2 $y2]
    }
    set item [eval $c create line $coords -width $gred(link,width)]
    # Dessin de la flèche si elle existe
    if [info exists fleche] {
        set flecheItem [eval $c create line $fleche -width $gred(link,width)]
        $c itemconfigure $flecheItem -tags "Liaison $loid Fleche GrafcetTag"
    }
    $c itemconfigure $item -tags "Liaison $loid GrafcetTag"
  } else {
    set xTR $grafcet([set transition],x)
    set yTR $grafcet([set transition],y)
    set dyPins [expr ($gred(transition,height)/2) + $gred(doubleLine,yOffset) \
      + $gred(doubleLine,height)]
    set xMin $grafcet([set transition],x)
    set xMax $grafcet([set transition],x)
    set around [expr $gred(etape,height) / 2]

    # affichage des lignes
    foreach liaison $liaisons {
      # tester si la liaison a ete editee manuellement

      # effacement de l'ancienne liaison
      $c delete $liaison
      # mise a jour des coordonnees de la double ligne (xMax yMin)
      set id1 [Link:getLinkSource $liaison]
      set id2 [Link:getLinkDesti  $liaison]
      set $src($direction) $id1
      set $dst($direction) $id2
      set x $grafcet([set etape],x)
      set y $grafcet([set etape],y)
      
      # test des placements etapes/transitions
      if { [expr [expr $y - $yTR] $comp($direction) 0] } {
        set y1 [expr $y $s($direction) ($gred(etape,height)/2)]
        set coords [concat \
          $x $y1 \
          $x [expr $y1 $s($direction) $around] \
          [expr $x - ($gred(etape,height)/2) - $around] \
            [expr $y1 $s($direction) $around]\
          [expr $x - ($gred(etape,height)/2) - $around] \
            [expr $yTR $ns($direction) $dyPins $ns($direction) $around] \
          [expr $x - ($gred(etape,height)/2) - (2 * $around)] \
            [expr $yTR $ns($direction) $dyPins $ns($direction) $around] \
          [expr $x - ($gred(etape,height)/2) - (2 * $around)] \
            [expr $yTR $ns($direction) $dyPins ]]
            
        set a 2
        # Coordonnées de la flèche
        set flechexMiddle [expr $x - ($gred(etape,height)/2) - $around]
        set milieu [expr ([expr $y1 $s($direction) $around]\
                +[expr $yTR $ns($direction) $dyPins $ns($direction) $around])/2]
        set fleche [concat \
         [expr $flechexMiddle-7] [expr $milieu+10] \
         [expr $flechexMiddle]   [expr $milieu] \
         [expr $flechexMiddle+7] [expr $milieu+10]]
        
        set x [expr $x - ($gred(etape,height)/2) - (2 * $around)]
      } else {
        set coords [concat \
          $x [expr $y $s($direction) ($gred(etape,height)/2)] \
          $x [expr $yTR $ns($direction) $dyPins] ]
      } 
      
      if { $x > $xMax } {
        set xMax $x
      } elseif { $x < $xMin } {
        set xMin $x
      }
      
      if [info exists fleche] {
        set flecheItem [eval $c create line $fleche -width $gred(link,width)]
        $c itemconfigure $flecheItem -tags "Liaison $loid Fleche GrafcetTag"
        unset fleche
      }
      # affichage de la liaison
      set item [eval $c create line $coords -width $gred(link,width)]
      $c itemconfigure $item -tag "Liaison $liaison GrafcetTag"
    }

    # affichage de la double ligne
    $c create line \
       [expr $xMin - $gred(doubleLine,xOffset)] \
       [expr $yTR $ns($direction) $dyPins] \
       [expr $xMax + $gred(doubleLine,xOffset)] \
       [expr $yTR $ns($direction) $dyPins] \
        -width $gred(link,width) \
        -tag "DoubleLine$direction $liaison GrafcetTag"
#         -tag "DoubleLine$direction $transition GrafcetTag"
    $c create line \
       [expr $xMin - $gred(doubleLine,xOffset)] \
       [expr $yTR $ns($direction) $dyPins \
         $s($direction) $gred(doubleLine,height)] \
       [expr $xMax + $gred(doubleLine,xOffset)] \
       [expr $yTR $ns($direction) $dyPins \
         $s($direction) $gred(doubleLine,height)] \
        -width $gred(link,width) \
        -tag "DoubleLine$direction $liaison GrafcetTag"
#         -tag "DoubleLine$direction $transition GrafcetTag"
    $c create line \
       $xTR [expr $yTR $ns($direction) ($gred(transition,height) / 2)] \
       $xTR \
       [expr $yTR $ns($direction) ($gred(transition,height) / 2) \
          $ns($direction) $gred(doubleLine,yOffset)] \
        -width $gred(link,width) \
        -tag "DoubleLine$direction $liaison GrafcetTag"
#         -tag "DoubleLine$direction $transition GrafcetTag"
  }
  # On enfuie les liens sous les transition pour permettre la sélection
  # des transitions lorsequ'on clique juste sur la grille.
  $c lower $loid
}

########################################################################
# Link:delete -- déstruction de la liaison
# 
# 
# 
proc Link:delete {c liaisonId} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  gred:markDirty .[gred:getGrafcetName $c]
  
  # recherche de la transition associee à cette liaison
  set oidDesti [Link:getLinkDesti $liaisonId]
  set oidSource [Link:getLinkSource $liaisonId]
  
  regexp "^oidLink(\[0-9\]+)" $liaisonId match id
  undo_saveInfos .[gred:getGrafcetName $c] \
                 "Link:addFromUndo $id $c \
                   $oidSource $oidDesti"\
                 "Link:delete $c $liaisonId"
  
  # On recupere la liste des liens a redessiner
  # mise a jour de toutes les liaisons associées à la transition
  # 1. on teste le type de liaison ET/TR ou TR/ET
  # 2. on recherche toutes les liaisons associées à la transition
  # 3. chacune de ces liaisons est redessinée
  switch -exact -- [Obj:getType $oidSource] {
    Etape {
      # c'est une liaison ET -> TR
      set option -Etape_Trans
    }
    Trans {
      # c'est une liaison TR -> ET
      set option -Trans_Etape
      set oidDesti $oidSource
    }
    default {
      # On ignore les oid autre que Etape ou Trans
      return {}
    }
  }
  # on recherche tous les liens de la transition suivant la direction
  set loidLink [Link:getLinks $c $option $oidDesti]
  # On enleve le lien que l'on vient de detruire de la liste des liens 
  # a redessiner
  set match [lsearch -exact $loidLink $liaisonId]
  set oidsLink [lreplace $loidLink $match $match]

  $c delete $liaisonId
  
  foreach var [array names grafcet $liaisonId*] {
    unset grafcet($var)
  }
  # On redessine enfin les liens qui doivent l'etre
  foreach link $oidsLink {
    Link:draw $c $link
  }
}

########################################################################
# Link:exist -- Teste si la liaison existe
# 
# 
# 
proc Link:exist {c oidSource oidDesti} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  # On supprime les prefixes "oid" des objets oidTrans23 -> Trans23
  # Les objets peuvent etre vide "" : le resultat sera 0.
  regsub ^oid $oidSource "" idS
  regsub ^oid $oidDesti  "" idD
  
  set RegPat  [format "%s%s%s" {^oidLink[0-9]+} "$idS$idD" {$}]
  set GlobPat [format   "%s%s"  {oidLink[0-9]*} "$idS$idD"    ]
  if [llength [array names grafcet $GlobPat]] {
    return 1
  } else {
    return 0
  }
}

########################################################################
# Link:getExternalLinks --
# 
# Retourne la liste des liaisons externes a un groupe d'objets
# 
# ALGO POTENTIEL (A FAIRE) POUR AMELIORER CES DEUX PROCEDUIRES :
# <PRE>
# set oids [Obj:filterType {Etape Trans} $objects
# foreach loid [Obj:getAll {Link}] {
#    Link:assignNodes $lois SourceOid DestiOid ;# passage par variable
#    
#    
# }</PRE>
proc Link:getExternalLinks {c objects} {
global gred

  set liaisonsExternes {}
  foreach object $objects {

    if ![regexp ^(Etape|Trans)$ [Obj:getType $object]] continue
    
    set liaisons [Link:getLinks $c -all $object]
    
    foreach liaison $liaisons {
      set source [Link:getLinkSource $liaison]
      set desti [Link:getLinkDesti $liaison]
      if { [lsearch -exact $objects $source] == -1 ||
           [lsearch -exact $objects $desti] == -1} {
        lappend liaisonsExternes $liaison
      }
    }
  }
  return $liaisonsExternes
}

########################################################################
# Link:getInternalLinks --
# 
# Retourne la liste des liaisons internes a un groupe d'objets
# 
proc Link:getInternalLinks {c objects} {
global gred

  set liaisonsInternes {}
  foreach object $objects {
    
    if ![regexp ^(Etape|Trans)$ [Obj:getType $object]] continue
    
    set liaisons [Link:getLinks $c -all $object]

    foreach liaison $liaisons {
      set source [Link:getLinkSource $liaison]
      set desti [Link:getLinkDesti $liaison]
      if { [lsearch -exact $objects $source] != -1 &&
           [lsearch -exact $objects $desti] != -1} {
        if { [lsearch -exact $liaisonsInternes $liaison] == -1 } {
          lappend liaisonsInternes $liaison
        }
      }
    }
  }
  return $liaisonsInternes
}

########################################################################
# Link:getLinks --
# 
# Retourne toutes (-all) ou une partie (-Etape_Trans ou -Trans_Etape) des
# liaisons attachées à l'objet dont l'oid est passé en paramètre
# 
proc Link:getLinks {c option oid} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  # recupere juste l'id de l'etape (ex. : Etape34 au lieu de oidEtape34)
  regexp {^oid(Etape[0-9]+|Trans[0-9]+)$} $oid full object

  switch -exact -- [Obj:getType $oid] {
    Etape {
      set pathE_T oidLink*${object}Trans*
      set pathT_E oidLink*Trans*$object
    }
    Trans {
      set pathE_T oidLink*Etape*$object
      set pathT_E oidLink*${object}Etape*
    }
    default {
      # On ignore les oid autre que Etape ou Trans
      return {}
    }
  }
  
  switch -exact -- $option {
    -Etape_Trans {
      set links [array names grafcet $pathE_T]
    }
    -Trans_Etape {
      set links [array names grafcet $pathT_E]
    }
    -all {
      # pour une etape ou une transition
      set links [concat [array names grafcet $pathE_T] \
                        [array names grafcet $pathT_E] ]
    }
  }
  
  # On supprime les liens du style "oidLink1Etape4Trans2,command" !
  # A CHANGER !!!!!!
  # DAVID
  set linksPure {}
  foreach link $links {
    if ![string match *,* $link] {
        lappend linksPure $link
    }
  }
  return $linksPure
}

########################################################################
# Link:getLinkDescription --
# 
# Retourne la composition de la liaison sous forme d'une liste :<BR>
# <CODE>{oidliaison oidSource oidDesti}</CODE>
# 
proc Link:getLinkDescription loid {
global gred
  regexp {^oid(Link[0-9]+)(Etape[0-9]+|Trans[0-9]+)(Etape[0-9]+|Trans[0-9]+)$} \
           $loid full link source desti

  return [list oid$link oid$source oid$desti]
}

########################################################################
# Link:getLinkDirection --
# 
# Retroune le sens de la liaison : Etape_Trans ou Trans_Etape
# 
proc Link:getLinkDirection {loid} {
global gred

  set source [Link:getLinkSource $loid]
  set desti [Link:getLinkDesti $loid]
  
  return [Obj:getType $source]_[Obj:getType $desti]
}

########################################################################
# Link:getLinkSource --
# 
# Retourne la source de la liaison passée en paramètre
# 
proc Link:getLinkSource loid {
global gred

  return [lindex [Link:getLinkDescription $loid] 1]

}

########################################################################
# Link:getLinkDesti --
# 
# Retourne la destination de la liaison passée en paramètre
# 
proc Link:getLinkDesti {loid} {
global gred

  return [lindex [Link:getLinkDescription $loid] 2]
}

########################################################################
# Link:showLinkHandle --
# 
# Affichage des poignées de saisie sur les liaisons
# 
proc Link:showLinkHandle {c liaison} {
global gred
  set handleSize $gred(link,handlesize)
  set handleUId 0
  
  # si les poignees existent ne pas les afficher une deuxieme fois
  if { [llength [$c find withtag LinkHandle]] != 0 } {
    return
  }
  
  # # set coords [$c coord $liaison]
  # # for {set i 0} {$i < [llength $coords]} {incr i 2} {
  # #   set id LH[incr handleUId]
  # #   set x [lindex $coords $i]
  # #   set y [lindex $coords [expr $i + 1]]
  # #   
  # #   set item [$c create rectangle \
  # #       [expr $x - $handleSize] [expr $y - $handleSize] \
  # #       [expr $x + $handleSize] [expr $y + $handleSize] \
  # #       -fill red -outline red -tags "LinkHandle $id"]
  # # }
  foreach {x y} [$c coord $liaison] {
    set id LH[incr handleUId]
    
    set item [$c create rectangle \
        [expr $x - $handleSize] [expr $y - $handleSize] \
        [expr $x + $handleSize] [expr $y + $handleSize] \
        -fill red -outline red -tags "LinkHandle $id"]
  }
  
#   $c bind LinkHandle <Enter> "ChangeCursor $c sb_h_double_arrow"
#   $c bind LinkHandle <Leave> "ChangeCursor $c top_left_arrow"

}

########################################################################
# Link:hideLinkHandle --
# 
# éffacement des poignées de saisie sur les liaisons
# (EST-CE BIEN NECESSAIRE ??)
# 
proc Link:hideLinkHandle {c} {
global gred

 $c delete LinkHandle
  
}

########################################################################
# Link:create --
# 
# procédure interactive de création d'une liaison
# 
proc Link:create {c args} {
global gred

  if { ([string compare $args {}] == 0) || \
       ([expr [llength $args] % 2] != 0) } {
    puts stderr "\"Link:add $args\"\n\
                 Liaison Error : one option left."
    return
  }
  
  # mise a jour du tableau des options
  array set option $args

  # test des options passees en argument
  # liste des options : source, desti, points

######### DAVID ##########
# set command {Link:add $c }
  set command "Link:add $c "

  # test de l'existence de toutes les options
  foreach opt $gred(etape,options) {
    if { ![info exist option(-$opt)] } {
      set option(-$opt) {}
    }
  }

  set typ(E) Etape
  set typ(T) Trans

  # test de la source
  if { ![info exist option(-source)] } {
    puts stderr "\"Link:add $args\"\n\
                 ==> Liaison Error : Missing source."
    return
  } else {
    # extraction du nom generique de l'etape
    if ![regexp {^(E|T)(.*$)}  $option(-source) full prefix source] {
      puts stderr "\"Link:add $args\"\n\
                   ==> Liaison Error : Missing prefix E or T."
      return
    }
    # test de l'existence du nom generique de l'objet
    set oidSource [Obj:getOidFromName $c $typ($prefix) $source]
    if {[string length $oidSource] == 0} {
      puts stderr "\"Link:add $args\"\n\
                   ==> Liaison Error : in \"-source $option(-source)\"\
                   (Etape or Transition) unknown."
      return
    }    
  }
  lappend command $oidSource
    
  # test de la desti
  if { ![info exist option(-desti)] } {
    puts stderr "\"Link:add $args\"\n\
                 ==> Liaison Error : Missing destination."
    return
  } else {
    # extraction du nom generique de la transition
    if ![regexp {^(E|T)(.*$)}  $option(-desti) full prefix desti] {
      puts stderr "\"Link:add $args\"\n\
                   ==> Liaison Error : Missing prefix E or T."
      return
    }
    # test de l'existence du nom generique de l'objet
    set oidDesti [Obj:getOidFromName $c $typ($prefix) $desti]
    if {[string length $oidDesti] == 0} {
      puts stderr "\"Link:add $args\"\n\
                   ==> Liaison Error : in \"-destination $option(-desti)\"\
                   (Etape or Transition) unknown."
      return
    }    
  }
  lappend command $oidDesti
  
  
  # test du nombre de points a afficher  
  if { [info exist option(-points)] && \
       ([expr [llength $option(-points)] % 2] != 0) } {
    puts stderr "Liaison Error : bad format points."
    return
  }
  # la prise en compte des points n'est pas operationnelle
#   lappend command $option(-points)

  set oid [eval $command]

  return $oid
}
