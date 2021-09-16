########################################################################
# proc�dure relatives a la s�lection<BR>
# nom du programme : s�lection.tcl<BR>
# cr�e le 18/09/96 par <A HREF="mailto:commeau@ensta.fr">
# commeau@ensta.fr</A>
# derni�res modifications :
########################################################################

########################################################################
# Package de gestion de la selection pour le programme <I>gred</I>
# La selection est g�r�e par l'interm�diaire d'un grand nombre de 
# commandes qui modifient l'�tat de la selection.
# La selection est m�moris�e � l'aide de plusieurs variables:
# <OL>
# <LI> <I>grafcet(sel,oids)</I>: Permet de m�moriser la liste des
#  <I> oids</I> selectionn�.
# <LI> <I>gred(sel,color)</I>: Couleur de selection des �l�ments
#  selectionn�s.
# <LI> <I>grafcet(sel,new)</I>: Variable d'�tat utilis�e pour le copi�
#  coll� entre application. Variable positionn�e � 1 d�s que l'on selectionne
#  de nouveau oids. Cette variable permet de ne pas avoir � recalculer la
#  valeur de la selection pour un copi� coll� entre application.grafcet(sel,new)
########################################################################

########################################################################
# Sel:move -- D�placement de la s�lection 
# 
# 
# 
proc Sel:move {c dx dy} {
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  # ON sauvegarde l'�tat du curseur, qui doit �tre normalement "iron_cross"...
  set cursor [$c cget -cursor]
  $c config -cursor watch
  
  # On impose les coordonn�es de d�placement sur la grille
  set dx [Grid $dx]
  set dy [Grid $dy]
  # Y'a rien a "mover", on sort de la proc�dure...
  if {!$dx && !$dy} {
    $c config -cursor tcross
    return
  }
  
  # A ce stade y'a vraiment des objets � "mover"...
  undo_saveInfos .[gred:getGrafcetName $c] \
                 "moveForUndo $c [expr -1.0*$dx] [expr -1.0*$dy] \
                              $grafcet(sel,oids)" \
                 "moveForUndo $c $dx $dy $grafcet(sel,oids)"
  undo_notSave .[gred:getGrafcetName $c]
  # On desselectionne les liens avant d�placement de la s�lection :
  set grafcet(sel,oids) [Obj:filterType -not {Link} $grafcet(sel,oids)]
  
  # On s�pare les oids "noeuds" (Etape et Trans), les liens internes, 
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
# Sel:clear -- Mise � zero de la selection
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
# visualisation de la s�l�ction (rectangle de s�l�ction)
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
# D�finition d'une nouvelle selection. la s�l�ction est initialis�e avec
# la liste des oids pass�e en param�tre
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
# Sel:compl�ment --
# 
# Mise � jour de la s�l�ction avec la liste des oids pass�s en arguments
# si l'oid existe dans la selection, il est supprime
# sinon il est ajout�
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
# Sel:delete -- Destruction de tous les oids contenus dans la s�l�ction
# 
# 
# 
# proc Sel:delete {} {
# global gred
# 
#   set c $grafcet(canvas)
#   
#   # On va d'abord d�truire les liens s�lectionn�s :
#   set links [Obj:filterType Link $gred(sel,oids)]
#   foreach LinkOid $links {
#      Link:delete $c $LinkOid
#   }
#   
#   # Ensuite, on d�truits les autres types (Etape, Trans, Com, ...)
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
# Calcul du contour form� par l'ensemble des objets de la s�l�ction
# 
proc Sel:bbox {c} {
#   global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  set box [eval $c bbox $grafcet(sel,oids)]
}

########################################################################
# Sel:isOidSelected -- L'oid pass� en param�tre est-il dans la selection ?
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
# Sel:getSelectedOids -- Retourne l'ensemble des oids s�l�ctionn�s
# 
# 
# 
proc Sel:getSelectedOids {c} {
# global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  return $grafcet(sel,oids)
}

########################################################################
# Sel:getX11 -- Proc�dure renvoyant le contenue du presse papier
# Proc�dure renvoyant le contenue du presse papier sous forme de texte
# Pour l'applicvation X11 effectuant la demande. On utilise la
# variable <I>grafcet(sel,new)</I> pour ne pas a avoir � r�-ex�cuter
# la proc�dure <I>Obj:getGrafcetCommands</I> gourmande en ressource
# systr�me.
proc Sel:getX11 {c offset maxbytes} {
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  
  # On  ne recalcule la description du grafcet que si c'est n�cessaire
  if {$grafcet(sel,new) == 1} {
    set grafcet(sel,commands) [Obj:getGrafcetCommands $c\
                        [lsort -ascii -increasing [Sel:getSelectedOids $c]]]
    set grafcet(sel,new) 0
  }
  return [string range $grafcet(sel,commands) $offset \
                        [expr $offset+$maxbytes]]
}