

# <B>A FAIRE :</B> option d"initialisation de la grille "grid_setup"<BR>
# 
# Rajouter les options d"initialisation de la grille "grid_setup"<BR>
#   <CODE>Grid_Setup -unitspecif 5mm -visible 1 -colre blue ...</CODE>
# 
# G�rer la variable Grid_UpdatePixel
#   Pour l'instant, on doit rentrer directement<BR> 
# Inspirer de  <A HREF="mailto:Frank.Mangin@sophia.inria.fr">
# Frank.Mangin@sophia.inria.fr </A>(Picasso)
# 

########################################################################
# Grid_Setup --
# 
# 
# 
proc Grid_Setup {args} {
global grid

  # Initialisation des option par d�faut seulement la premi�re fois.
  if ![array exist grid] {
    array set a {
      -pixel        5
      -visible      0
      -color     black
      -dashstep  {2 5}
      -tag       Grid
    } 
  }
  
  array set a $args
  set grid(pixel)      $a(-pixel)   ;# SERA REMPLAC� PAR grid(unitspecif)
  set grid(visible)    $a(-visible) 
  set grid(color)      $a(-color) 
  set grid(dashstep)   $a(-dashstep) ;# NON UTILIS�
  set grid(gridtag)   $a(-tag) 

#   set grid(canvas)      $c
  
  # On verra bien ce qu'on gardera
  set grid(unitnumber)   5
  set grid(unitstep)    mm
  set grid(unitspecif) 5mm ;# exemples : 0.4cm, 3mm, ...
  
  
  set grid(tkunit,mm)    m
  set grid(tkunit,cm)    c
  set grid(tkunit,inch)  i
  set grid(visible)      0
    
  # "grid(pixel)" sera mise a jour directement par "Grid_UpdatePixel"
  # a partir de la sp�cification utilisateur gred(spec
  # Grid_UpdatePixel
#   Grid_Hide $c
}

########################################################################
# Grid_UpdatePixel --
# 
# Grid_UpdatePixel NON UTILISER POUR L'INSTANT<BR>
# Met � jour la variable grid(pixel) en fonction de la sp�cification 
# de grille au format utilisateur grid(unitspecif) ou bien � partir
# des deux variable s�par�e grid(unitnumber) et grid(unitstep) 
# 
proc Grid_UpdatePixel {} {
  global grid
  set grid(pixel) "[set grid(points)][set grid(tkunit,[set grid(unit)])]"
}

################################################################
# Grid --
# 
# Return a coord list according to the current grid(pixel)<BR>
# <B>Ex:</B> <CODE>Grid  x1 y1 x2</CODE><BR>
# return<BR>
#    <CODE>{gx1 gx2 gy1}</CODE>   gxi repr�sentant une coordonn�e grid�e
# 
proc Grid {args} {
  global grid

  set g $grid(pixel)
  set gpixel {}
  foreach pt $args {
    # set pt [expr round($pt)]
    # lappend gpixel [expr $pt - $pt % $g]
    lappend gpixel [expr $g*round($pt/$g)]
  }
  return $gpixel
}

################################################################
# Gridcanvasxy --
# 
# Return a coord list according to the current grid(pixel)<BR>
# <B>Ex:</B> <CODE>Grid  x1 y1 x2</CODE><BR>
# return<BR>
#    <CODE>{cvx(x1) cvy(y1) cvx(x2)}</CODE>
# 
proc Gridcanvasxy {c args} {
  global grid

#   set c $grid(canvas)
  set res [eval "$c canvasx [lindex $args 0] $grid(pixel)"]
  if {![catch {lindex $args 1} y]} {
    lappend res [eval "$c canvasy $y $grid(pixel)"]
  }

  return $res
}

################################################################
# Grid_ToggleShow -- Toggles grid showing
# 
# 
# 
proc Grid_ToggleShow {c} {
  global grid

#   set c $grid(canvas)
  if $grid($c,visible) {
    Grid_Hide $c
  } else {
    Grid_Show $c
  }
}

################################################################
# Grid_Hide -- Hide grid
# 
# 
# 
proc Grid_Hide {c} {
  global grid
  
  $c delete withtag $grid(gridtag)
  set grid($c,visible) 0
  update
}
proc Grid_State {c} {
    global grid
    return $grid($c,visible)
}
################################################################
# Grid_Show -- Show grid
# 
# 
# 
proc Grid_Show {c} {
  global grid
  
  # RESTE A FAIRE... (withtag Grid )
  
  # On cherche les coordonn�es des extr�mit� en PIXEL alors que 
  # scrollregion peut etre d�fini en cm ou autre (29.7c, ...)
  # Principe : on cr�e un rectangle de taille scrollregion
  set coords [$c cget -scrollregion]
  set rectIt [eval $c creat rectangle $coords -tag VIRTUAL]
  set coords [$c coords $rectIt]
  $c delete $rectIt
  set W [expr round([lindex $coords 2])]
  set H [expr round([lindex $coords 3])]
  
# report -v W H coords
  
  # grid increment (in pixel)
  set g $grid(pixel)
  
  # List of the coordonne of the  polygon
  set Poly {0 0}
  
  # Current width
  set w 0
  # ZigZag verticaux de haut-gauche � haut-droite
  while {$w < $W} {
     append Poly " $w $H  [incr w $g] $H $w 0 [incr w $g] 0"
  }
  
  # Current height
  set h 0
  # ZigZag horizontaux de haut-droite � bas-droite
  while {$h < $H} {
     append Poly " 0 $h  0 [incr h $g]  $W $h  $W [incr h $g]"
  }
  
  # Retour au point d'original (pour eviter une diagonale !)
  # append Poly " 0 $h 0 0 $W 0 $W $H 0 $H"
  append Poly " 0 $h 0 0" 
  
  
  # Contruction et ex�cution de la commande de cr�ation du polygone
  set options {            
            -tag $grid(gridtag) \
            -fill {} \
            -outline $grid(color)
  }
  eval $c create polygon $Poly $options
  
  $c lower $grid(gridtag)
  set grid($c,visible) 1
  update
}
#./
