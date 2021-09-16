

package provide canvas 0.1


# procedure effectue des operations sur deux listes d'items 
# generees a partir de leurs tags passes en argument.
# (de picasso)
# 
# Les options suivantes retourne une liste correspondant :
# -intersec : items possedant les deux tags
# -union : items possedant au moins l'un des deux tags.
# -exclude : items ne possedant qu'un et un seul des deux tags
# -1without2 : items possedant le tag1 mais pas le tag2
# -2without1 : items possedant le tag2 mais pas le tag1
# 
# Necessite le package de pist "tclx" pour l'emulation des 
# commandes de tclx (intersect3)
# 
proc tkCanvasFind {c how tag1 tag2} {
  global canvas
  
  set liste1 [$c find withtag $tag1]
  set liste2 [$c find withtag $tag2]
  
  switch -exact -- $how {
    -intersec {
      return [lindex [intersect3 $liste1 $liste2] 1]
    }
    -union {
      return [concat $liste1 [lindex [intersect3 $liste1 $liste2] 2]]
    }
    -exclude {
      return [concat 	[lindex [intersect3 $liste1 $liste2] 0]\
      			[lindex [intersect3 $liste1 $liste2] 2]]
    }
    -1without2 {
      return [lindex [intersect3 $liste1 $liste2] 0]
    }
    -2without1 {
      return [lindex [intersect3 $liste1 $liste2] 2]
    }
    default { return {} }
  }
  
}

