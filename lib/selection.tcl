########################################################################
# procédure relatives a la sélection<BR>
# nom du programme : sélection.tcl<BR>
# crée le 18/09/96 par <A HREF="mailto:commeau@ensta.fr">
# commeau@ensta.fr</A>
# dernières modifications :
########################################################################

########################################################################
# Package de gestion de la selection pour le programme <I>gred</I>
# La selection est gérée par l'intermédiaire d'un grand nombre de 
# commandes qui modifient l'état de la selection.
# La selection est mémorisée à l'aide de plusieurs variables:
# <OL>
# <LI> <I>grafcet(sel,oids)</I>: Permet de mémoriser la liste des
#  <I> oids</I> selectionné.
# <LI> <I>gred(sel,color)</I>: Couleur de selection des éléments
#  selectionnés.
# <LI> <I>grafcet(sel,new)</I>: Variable d'état utilisée pour le copié
#  collé entre application. Variable positionnée à 1 dès que l'on selectionne
#  de nouveau oids. Cette variable permet de ne pas avoir à recalculer la
#  valeur de la selection pour un copié collé entre application.grafcet(sel,new)
########################################################################

########################################################################
# Sel:move -- Déplacement de la sélection 
# 
# 
# 
proc Sel:move {c dx dy} {
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  # ON sauvegarde l'état du curseur, qui doit être normalement "iron_cross"...
  set cursor [$c cget -cursor]
  $c config -cursor watch
  
  # On impose les coordonnées de déplacement sur la grille
  set dx [Grid $dx]
  set dy [Grid $dy]
  # Y'a rien a "mover", on sort de la procédure...
  if {!$dx && !$dy} {
    $c config -cursor tcross
    return
  }
  
  # A ce stade y'a vraiment des objets à "mover"...
  undo_saveInfos .[gred:getGrafcetName $c] \
                 "moveForUndo $c [expr -1.0*$dx] [expr -1.0*$dy] \
                              $grafcet(sel,oids)" \
                 "moveForUndo $c $dx $dy $grafcet(sel,oids)"
  undo_notSave .[gred:getGrafcetName $c]
  # On desselectionne les liens avant déplacement de la sélection :
  set grafcet(sel,oids) [Obj:filterType -not {Link} $grafcet(sel,oids)]
  
  # On sépare les oids "noeuds" (Etape et Trans), les liens internes, 
  # et les liens externes a la selection.
  set noids [Obj:filterType {Etape Trans} $grafcet(sel,oids)]
  set internal_loids [Link:getInternalLinks $c $grafcet(sel,oids)]
  set external_loids [Link:getExternalLinks $c $grafcet(sel,oids)]
  # Deplacement des noeuds (Etape et Trans)
  foreach oid $noids {
    $c move $oid $dx $dy
    
    # mise a jour des coordonnees de reference des objets
    set grafcet($oid,x) [expr $grafcet($oid,x) + $dx]
    set grafcet($oid,y) [expr $grafcet($oid,y) + $dy]
  }
  
  # deplacement des liaisons internes
  foreach loid $internal_loids {
    $c move $loid $dx $dy
    set coord {}
    foreach {x y} $grafcet($loid) {
      lappend coord  [expr $x + $dx]  [expr $y + $dy]
    }
    set grafcet($loid) $coord
  }
    
  # Effacement des liaisons externes 
  foreach loid $external_loids {
    Link:draw $c $loid
  }

  # mise a jour des rectangles de selection
  Sel:redraw $c

  undo_Save .[gred:getGrafcetName $c]
  
  $c config -cursor $cursor
}

########################################################################
# Sel:clear -- Mise à zero de la selection
# 
# 
# 
proc Sel:clear {c} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  set grafcet(sel,oids) {}
  Sel:redraw $c
  $c config -cursor tcross
}

# #################################################################
# # Sel:show --
# # 
# # visualisation de la selection (rectangle de selection)
# # ATTENTION A MODIFIER
# # faire appel a "Sel:show$type" ou bien "$type:showSel"
# # RENOMMER Sel:show en Sel:draw ??
# # 
# proc Sel:show {} {
# global gred
#   set c $grafcet(canvas)
# 
#   $c delete withtag selectBox  
#   foreach oid $gred(sel,oids) {
#     #############################################################
#     # [Obj:getType $oid]:showSel
#     set box [$c bbox $oid]
#     eval $c create rectangle $box -outline $gred(sel,color) \
#       -tag selectBox
#     #############################################################
#     
#   } 
# }

########################################################################
# Sel:redraw --  (IDEM Sel:show ou Sel:refresh)
# 
# visualisation de la séléction (rectangle de séléction)
# ATTENTION A MODIFIER:
# Faire appel a "Sel:show$type" ou bien "$type:showSel"
# RENOMMER Sel:show en Sel:draw ??
# 
proc Sel:redraw {c} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  $c delete withtag selectBox
  foreach oid $grafcet(sel,oids) {
    ####################################################################
    # A MODIFIER
    # [Obj:getType $oid]:showSel
    set box [$c bbox $oid]
    eval $c create rectangle $box -outline $gred(sel,color) \
           -tag selectBox
    ####################################################################
    
  } 
}

# ################################################################
# # Sel:hide --
# # 
# # masquage de la selection (rectangle de selection)
# # 
# proc Sel:hide {} {
# global gred
#   set c $grafcet(canvas)
#   $c delete withtag selectBox  
# }


########################################################################
# Sel:new --
# 
# Définition d'une nouvelle selection. la séléction est initialisée avec
# la liste des oids passée en paramètre
# 
proc Sel:new {c oids} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  set grafcet(sel,oids) $oids
  if {$grafcet(sel,oids) != {}} {
    $c config -cursor $gred(cursor,withSelection)
  }
  Sel:redraw $c
  # X11
  selection own $c
  set grafcet(sel,new) 1
}

########################################################################
# Sel:complément --
# 
# Mise à jour de la séléction avec la liste des oids passés en arguments
# si l'oid existe dans la selection, il est supprime
# sinon il est ajouté
# 
proc Sel:complement {c oids} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  foreach oid $oids {
    set idx [lsearch -exact $grafcet(sel,oids) $oid]
    if { $idx == -1  } {
      lappend grafcet(sel,oids) $oid
    } else {
      set grafcet(sel,oids) [lreplace $grafcet(sel,oids) $idx $idx]
    }
  }
  if {$grafcet(sel,oids) != {}} {
    $c config -cursor $gred(cursor,withSelection)
  }
  Sel:redraw $c
  # X11
  selection own $c
  set grafcet(sel,new) 1
}

########################################################################
# Sel:delete -- Destruction de tous les oids contenus dans la séléction
# 
# 
# 
# proc Sel:delete {} {
# global gred
# 
#   set c $grafcet(canvas)
#   
#   # On va d'abord détruire les liens sélectionnés :
#   set links [Obj:filterType Link $gred(sel,oids)]
#   foreach LinkOid $links {
#      Link:delete $c $LinkOid
#   }
#   
#   # Ensuite, on détruits les autres types (Etape, Trans, Com, ...)
#   foreach oid [Obj:filterType -not Link $gred(sel,oids)] {
#   
#     [Obj:getType $oid]:delete  $c $oid
#     
#   }
# 
#   set gred(sel,oids) {}
#   Sel:redraw
# }

proc Sel:delete {c} {
# global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  
  Obj:delete $c $grafcet(sel,oids)
  set grafcet(sel,oids) {}
  $c config -cursor tcross
  Sel:redraw $c
}

########################################################################
# Sel:bbox --
# 
# Calcul du contour formé par l'ensemble des objets de la séléction
# 
proc Sel:bbox {c} {
#   global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  set box [eval $c bbox $grafcet(sel,oids)]
}

########################################################################
# Sel:isOidSelected -- L'oid passé en paramètre est-il dans la selection ?
# 
# 
# 
proc Sel:isOidSelected {c oid} {
#   global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  
  if {[lsearch -exact $grafcet(sel,oids) $oid] != -1} {
     return 1
  } else {
     return 0
  } 
}

########################################################################
# Sel:exist -- Teste si la selection est non vide
# 
# 
# 
proc Sel:exist {c} {
#   global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  return [expr [llength $grafcet(sel,oids)] != 0] 
}

########################################################################
# Sel:getSelectedOids -- Retourne l'ensemble des oids séléctionnés
# 
# 
# 
proc Sel:getSelectedOids {c} {
# global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  return $grafcet(sel,oids)
}

########################################################################
# Sel:getX11 -- Procédure renvoyant le contenue du presse papier
# Procédure renvoyant le contenue du presse papier sous forme de texte
# Pour l'applicvation X11 effectuant la demande. On utilise la
# variable <I>grafcet(sel,new)</I> pour ne pas a avoir à ré-exécuter
# la procédure <I>Obj:getGrafcetCommands</I> gourmande en ressource
# systrème.
proc Sel:getX11 {c offset maxbytes} {
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  
  # On  ne recalcule la description du grafcet que si c'est nécessaire
  if {$grafcet(sel,new) == 1} {
    set grafcet(sel,commands) [Obj:getGrafcetCommands $c\
                        [lsort -ascii -increasing [Sel:getSelectedOids $c]]]
    set grafcet(sel,new) 0
  }
  return [string range $grafcet(sel,commands) $offset \
                        [expr $offset+$maxbytes]]
}