########################################################################
# procédure de traitement des objets en général<BR>
# nom du programme : grobjects.tcl<BR>
# crée le 18/09/96 par <A HREF="mailto:commeau@ensta.fr">commeau@ensta.fr
# </A><BR>
# dernières modifications :
########################################################################

########################################################################
# Obj:getType --
# 
# Retourne le type de l'objet (Etape | Link | Grid | Comment | ...)
# ou bien retourne {} si l'objet est de type inconnu
# 
proc Obj:getType {oid} {
global gred

  switch -regexp $oid {
    ^oidEtape[0-9]+$    {return Etape}
    ^oidTrans[0-9]+$    {return Trans}
    ^oidLink[0-9]+(Etape[0-9]+Trans[0-9]+)|(Trans[0-9]+Etape[0-9]+)$ \
                        {return Link}
    ^oidGrid[0-9]*$     {return Grid}
    ^oidCartouch[0-9]+$ {return Cartouch}
    ^oidCom[0-9]+$      {return Com}
    default             {return ""}
  }
}

########################################################################
# Obj:isEtapeOrTrans --
# 
# Retourne  1 si oid est une Etape ou Trans, retourne 0 sinon
# 
proc Obj:isEtapeOrTrans {oid} {
global gred

  switch -regexp $oid {
    ^oidEtape[0-9]+$ -
    ^oidTrans[0-9]+$ {return 1}
    default          {return 0}
  }
}

########################################################################
# Obj:filterType --
# 
# Retourne la liste des oids dont le type est l'un de ceux de la liste.
# 
# Arguments:
#    &lt;typeList&gt; - liste des types à conserver
#    oids - liste des oids à examiner
# 
# Exemple:
#    <CODE>Obj:filterType {Etape Trans} [Sel:getSelectedOids $c]</CODE>
# 
# A Faire ?:
#     option -not pour retourner le complément du résultat
# 
proc Obj:filterType {args} {
  
  set NOT 0
  
  # Tant qu'il reste des arguments :
  while {[string match -* $args]} {
    switch -glob -- [lindex $args 0] {
       --  {
          set args [lreplace $args 0 0]
          break
       }
       -not  { 
          set NOT 1
          set args [lreplace $args 0 0]
          continue
       }
       -*         { error "unknow option $arg"}
       default    { break  ;# no more options}
    }
  }
  # args contains on the list of unread arguments
  set typeList [lindex $args 0]
  set oids     [lindex $args 1]
  # On va définir une patterne à partir des types à filtrer
  switch -exact [llength $typeList] {
     0 {
       error "<typeList> should not be empty"
     }
     1 { 
       # peut-on virer ce cas particulier ? (car inclu dans default)
       set regPat "^oid[lindex $typeList 0]"
     } 
     default {
       # On va construire la patterne multiple (car rare ou on a plus 
       # de trois types a traiter)
       set type1 [lindex $typeList 0]
       set typeList [lreplace $typeList 0 0]
       set regPat "^oid($type1"
       foreach type $typeList {
          append regPat "|$type"
       }
       append regPat ").*"
     }
  }
  set result {}
  if $NOT {
  
    foreach oid $oids {
      switch -regexp $oid "
        $regPat  {}
        default  {lappend result $oid}
      "
    }

  } else {
  
    foreach oid $oids {
      switch -regexp $oid "
        $regPat   {lappend result $oid}
      "
    }
    
  }
  return $result
}

########################################################################
# Obj:isSelectable --
# 
# Retourne  1 si oid est un objet sélectionnable, retourne 0 sinon 
#  
proc Obj:isSelectable {oid} {
global gred

  switch -regexp $oid {
    ^oidEtape[0-9]+$ -
    ^oidTrans[0-9]+$ -
    ^oidCom[0-9]+$ -
    ^oidLink[0-9]+(Etape[0-9]+Trans[0-9]+)|(Trans[0-9]+Etape[0-9]+)$ \
                  {return 1}
    default       {return 0}
  }
}

########################################################################
# Obj:getAllSelectable --
# 
# Retourne la liste de tous les oids sélectionnables
# 
# Pas d'argument pour l'instant.
# 
proc Obj:getAllSelectable {c args} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  
  set oids [array names grafcet oid*]
  
  set result {}
  foreach oid $oids {
    switch -regexp $oid {
      ^oidEtape[0-9]+$ -
      ^oidTrans[0-9]+$ -
      ^oidCom[0-9]+$ -
      ^oidLink[0-9]+(Etape[0-9]+Trans[0-9]+)$ -
      ^oidLink[0-9]+(Trans[0-9]+Etape[0-9]+)$ \
                    {lappend result $oid}
      default       { }
    }
  }
  return $result
}

########################################################################
# Obj:areComplementary --
# 
# Retourne 1 si les objets passés en paramètres sont complémentaires
# 
proc Obj:areComplementary {oid1 oid2} {
  switch -exact -- [Obj:getType $oid1]_[Obj:getType $oid2] {
    Etape_Trans - 
    Trans_Etape {return 1}
    default     {return 0}
  }
}

########################################################################
# Obj:getComplementaryType --
# 
# Retourne le type complémentaire (Etape ou Trans) au type passé en 
# paramètre.
# Le parametre "oidOrType" peut etre un TYPE (Etape ou Trans) ou un 
# OID (Trans23, ...)
# 
proc Obj:getComplementaryType {oidOrType} {
  switch -exact -- $oidOrType {
    Etape   {return Trans} 
    Trans   {return Etape} 
  }
  switch -exact -- [Obj:getType $oidOrType] {
    Etape   {return Trans} 
    Trans   {return Etape} 
  }
  default {error "Obj:getComplementaryType take Etape or Trans Oid\
               but receive \"$oidOrType\""}
}

########################################################################
# Obj:getOidFromName --
# 
# Retourne l'oid d'un objet dont on a passé le nom générique en paramètre
# Ex. :
# ETAPE123 --> oidET11<BR>
# l'argument préfix (Etape ou Trans) sert a différencier une étape 
# d'une transition
# 
# A FAIRE :  
# améliorer (idem pour la proc Obj:name:exist)<UL>
# <LI> par un accès direct à l'$oid à partir du $name
# <LI> soit en inversant le tableau :<BR>
#     Pour inverser un tableau **bijectif** :<BR>
#     <CODE>array set tab2 [lreverse [array get tab1 $pattern]]</CODE>
# </UL>
proc Obj:getOidFromName {c prefix name} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  set pat oid${prefix}*,name
  set objectNames [array get grafcet $pat ]
# #   if { [set idx [lsearch -exact $objectNames $name]] != -1 && \
# #     [expr $idx % 2] == 1} {
# # #   ^^^^^^^^^^^^^^^^^^^^   ==>  inutile
# #     regexp {^oid(Etape[0-9]+|Trans[0-9]+)} \
# #       [lindex $objectNames [expr $idx - 1]] oid
# #     return $oid
# #   } else {
# #     return {}
# #   }
  if { [set idx [lsearch -exact $objectNames $name]] != -1} {
    regexp {^oid(Etape[0-9]+|Trans[0-9]+)} \
      [lindex $objectNames [expr $idx - 1]] oid
    return $oid
  } else {
    return {}
  }
}

########################################################################
# Obj:name:exist --
# 
# retourne 1 si le nom generique passe en argument correspond a un objet
# l'argument prefix (Etape ou Trans) sert a differencier une etape 
# d'une transition
# 
# A FAIRE:
# <UL> 
# <LI> renommer en Obj:nameExist ?
# <LI> voir aussi proc Obj:getOidFromName
# </UL>
proc Obj:name:exist {c prefix name} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  # # # switch $prefix {
  # # #   Trans {; # ok}
  # # #   Etape {; # ok}
  # # #   default { error "unknow \"prefix\" arg for Obj:name:exist"
  # # #   }
  # # # }
  set pat oid${prefix}*,name
  set objectNames [array get grafcet $pat ]
# #   if { [set idx [lsearch -exact $objectNames $name]] != -1 && \
# #     [expr $idx % 2] == 1} {
# #     return 1
# #   } else {
# #     return 0
# #   }
  if { [set idx [lsearch -exact $objectNames $name]] != -1} {
    return 1
  } else {
    return 0
  }
}

########################################################################
# Obj:newLinkOid --
# 
# Retourne un nouvel oid de lien à partir des oids source et destination
# 
# Exemple :
#  on veut "oidLink32Etape16Trans41" à partir de "oidEtape16" 
#  et de "oidTrans41"
# 
proc Obj:newLinkOid {c oidSource oidDesti {id {}}} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  
  if {$id == {}} {
      set    loid "oidLink[incr grafcet(LinkUId)]"
  } else {
      set    loid "oidLink$id"
  }
  append loid [string range $oidSource 3 end]
  append loid [string range $oidDesti  3 end]
  return $loid
} ;# endproc Obj:newLinkOid


########################################################################
# 
# Obj:delete --
# 
# Detruit les oids passés en parametre.
# 
proc Obj:delete {c oids} {
  undo_mark .[gred:getGrafcetName $c]
  # On va d'abord détruire les liens :
  set linkOids [Obj:filterType Link $oids]
  foreach linkOid $linkOids {
     Link:delete $c $linkOid
  }

  # Ensuite, on détruits les autres types (Etape, Trans, Com, ...)
  foreach oid [Obj:filterType -not Link $oids] {
    [Obj:getType $oid]:delete  $c $oid
    
  }
  undo_unMark .[gred:getGrafcetName $c]
} ;# endproc Obj:delete

########################################################################
# Obj:move --
# 
# Arguments:
#  oids - une liste d'oids à déplacer
#   Chaque oids doivent etre "déplaçables"
#
# A FAIRE:
#  TOUT ! (voir Sel:move laquelle fera appel à Obj:move)

proc Obj:move {oids} {
  error "Procédure Obj:move pas encore implementée"
} ;# endproc Obj:move


########################################################################
# Obj:getPointedOid --
# 
# Recherche de l'identificateur de l'objet présent en {x y}
# quelque soit le type de l'objet (grid, comment, etape, ...)
# 
proc Obj:getPointedOid {c x y} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  
  set oid ""
  # pour chaque élément (au sens canvas) au voisinage du point {x y}
  # On choisie le DERNIER item appartenant a un oid (le plus recent)
  foreach item [Canvas_GetPointedItems $c $x $y] {
    
    set tags [$c gettags $item]
    
    set idx [lsearch -regexp $tags "^oid"]
    if { $idx != -1 } {
      set oid [lindex $tags $idx]
    }
  }
  return $oid
}

########################################################################
# Obj:getOidFromItem --
# 
# Retourne l'oid auquel appartient un item de canvas quelconque
# ou "" si l'item n'appartient à aucun oid.
# 
proc Obj:getOidFromItem {c item} {

    set tags [$c gettags $item]
    set idx [lsearch -regexp $tags {^oid.+$} ]
    if {$idx != -1} {
       return [lindex $tags $idx]
    } else {
       return ""
    }
    
    
} ;# endproc Obj:getOidFromItem

########################################################################
# Obj:find --
# 
# Retourne la liste des "goids" (grafcet  oids) inclus dans le rectangle 
# ou pointé par le point : retourne une liste d'Etapes ou Trans.
# 
# A FAIRE:
#  COMPLETER LES OPTIONS<BR>
#  SUPPRIMER "Obj:getPointedOid" après complétion<BR>
#  RENOMMER EN Obj:get (?)<BR>
# 
# Syntaxe: 
# 
#  <CODE>Obj:find &lt;options&gt; &lt;zoneSpec&gt;</CODE><BR>
# 
# où &lt;zoneSpec&gt; est la spécification de zone sous une des forme suivante
# <PRE>
#    Obj:find {x1 y1 x2 y2}   (une bbox)
#    Obj:find {x1 y1} {x2 y2} (deux points)
#    Obj:find x1 y1 x2 y2     (quatre coordonnées)
# 
#    Obj:find x1 y1  (deux coordonnées)
#    Obj:find {x1 y1}  (un point)
# </PRE>
# 
# Arguments:
# -type <typeList> - Ne retourne que les "oids" d'un des types de la liste
# -overlapp - 
# -enclosed -  (=defaut)  (vérifier orthographe de ces termes)
# -keeporder - maintient l'ordre de création des oid
# -fast -      plus rapide mais ordre arbitraire
# -sort -      tri alphabetique
# -regexp <regPat> - les oids sont filtres par cette pattern
# -glob <globPat> - 
# 
proc Obj:find {c x1 y1 x2 y2} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  set oids {}
  set items [$c find enclosed $x1 $y1 $x2 $y2]
  
  foreach item $items {
    set oid [Obj:getOidFromItem $c $item]
    if [Obj:isSelectable $oid] { 
       lappend oids $oid
    }
  }
  
  return [lunique -keeporder $oids]

}

########################################################################
# Obj:get --
# 
# C'est la procedure Obj:find en construction
# 
proc Obj:get {c args} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  set oids {}

  # initialisation des parametres 
  set typesSearch {}
  set searchSpec enclosed
  set regexpSpec {}
  set globSpec {}
  
  # traitement des arguments
  while { [string match -* $args] } {
    switch -glob -- [lindex $args 0] {
      -- {
        set args [lreplace $args 0 0] 
        break
      }
      -type {
        # JE PREFERE ETRE OBLIGE DE PASSER UNE SEULE LISTE QUE DE POUVOIR
        # PASSER PLUSIEURS ARGUMENTS SEPARES :
        # Obj:find -type Etape Trans -- popo (J'AIME PAS BEAUCOUP)
        # Obj:find -type {Etape Trans} popo (JE PREFERE)
        set args [lreplace $args 0 0]
        set i [lsearch -glob $args -*]
        incr i -1
        set typesSearch [lrange $args 0 $i]
        set args [lreplace $args 0 $i]
        continue
      }
      -overlapping {
        set searchSpec overlapping
        set args [lreplace $args 0 0]
        continue
      }
      -enclosed {
        set searchSpec enclosed
        set args [lreplace $args 0 0]
        continue
      }
      -regexp {
        set regexpSpec [lrange $args 1 1]
        set args [lreplace $args 0 1]
        continue
      }
      -glob {
        set globSpec [lrange $args 1 1]
        set args [lreplace $args 0 1]
        continue
      }
      -sort {
        set args [lreplace $args 0 0]
        continue
      }
      -keeporder {
        set args [lreplace $args 0 0]
        continue
      }
      -fast {
        set args [lreplace $args 0 0]
        continue
      }
      default { break }
      
    }
  }
  
  # deux fois "eval concat" pour traiter le passage de 2 points comme
  # 4 coordonnees
  set zoneSpec [eval concat [eval concat $args]]
  
  set items [eval $c find $searchSpec $zoneSpec]

  foreach item $items {
    set oid [Obj:getOidFromItem $c $item]
    if [Obj:isEtapeOrTrans $oid] { 
       lappend oids $oid
    }
  }
  
  return [lunique -keeporder $oids]


}

########################################################################
# Obj:getGrafcetCommands --
# 
# Retourne la description du grafcet sur forme de texte directement 
# interpretable.<BR>
# L'option "-relativeCoord" permet de positionner toutes les coordonnees
# des objets relativement par rapport au point "0,0" de l'objet.<BR>
# L'option "-noName" permet de ne pas prendre en compte le nom generique
# de l'objet. Lors de l'interpretation du resultat, le nom generique par
# defaut est alors genere.<BR>
# args : options oids
# 
# A FAIRE:
# <UL>
# <LI> faire une bouche pour chaque option de la liste des options
#   autorisées pour chaque objet a creer Etape:add et Trans:add, ...
#   afin de ne pas modifier cette procedure a chaque nouvelle option 
#   ajoutée..
# <LI> analyse des option carrée (foreach, ..."--", ..)
#  </UL>
proc Obj:getGrafcetCommands {c objects} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcetArray
  set interactiveCommandsPart1 ""
  set interactiveCommandsPart2 ""
  
  foreach object $objects {
    update idletasks
    if {[Obj:getType $object] == "Etape"\
        || [Obj:getType $object] == "Trans"} {
      # traitement des etapes et des transitions
      append interactiveCommandsPart1 "\n$grafcetArray($object,command)"
    } else {
      # traitement des liaisons
      set oidDesti     [Link:getLinkDesti  $object]
      set oidSource    [Link:getLinkSource $object]
      append interactiveCommandsPart2 \
              "\n[Link:getCommandField $c $object $oidSource $oidDesti]"
    }    
  } ; # end foreach
  
  global grafcet.[gred:getGrafcetName $c]
  set interactiveCommandsPart1 [subst $interactiveCommandsPart1]
  
# puts "IC==>$interactiveCommandsPart1$interactiveCommandsPart2<=="
  return "$interactiveCommandsPart1$interactiveCommandsPart2"
}

# proc Obj:getGrafcetCommands {c args} {
#   global gred
#   upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
# 
#   # initialisation des parametres par defaut
#   # parametre -noName
#   set noName 0
#   # parametre -relativeCoord
#   set relativeCoord 0
#   set xRef 0
#   set yRef 0
#   
#   # traitement des arguments
#   while { [string match -* $args] } {
#     switch -glob -- [lindex $args 0] {
#       -- {
#         set args [lreplace $args 0 0]
#         break
#       }
#       -noName {
#         set noName 1
#         set args [lreplace $args 0 0]
#         continue
#       }
#       -relativeCoord {
#         set relativeCoord 1
#         set args [lreplace $args 0 0]
#          continue
#       }
#       default { break }
#     }
#   }
#   
#   set objects [eval concat $args]
#   
#   if $relativeCoord {
#     # si l'option "-relativeCoord" est presente :
#     # je calcule les coordonnees de reference, puis je les retire
#     # a chaque coordonnees d'objet.
#     set box [eval $c bbox $objects]
#     set xRef [lindex $box 0]
#     set yRef [lindex $box 1]
#   }
#   
#   # si l'option "-noName" est presente :
#   # je cree les objets avec un nom generique "bidon" mais intelligent !!
#   # par exemple "xXx1" a la place de "1"
#   # ceci afin de pouvoir cree les liaisons qui vont bien
#   # puis j'efface tous les noms generiques avec la procedure "ChangeParams"
#   
#   set interactiveCommands ""
#   set command ""
#   
#   # traitement des etapes et des transitions
#   foreach object $objects {
#     update
#     if { [Obj:getType $object] == "Etape" } {
#       # c'est une etape
#       # j'ajoute les coordonnees
#       set command "Etape:create -coord"
#       eval lappend command \{[expr $grafcet(${object},x) - $xRef] \
#         [expr $grafcet(${object},y) - $yRef]\}
#       # j'ajoute le nom generique
#       if $noName {
#         lappend command -name xXx$grafcet(${object},name)
#       } else {
#         lappend command -name $grafcet(${object},name)
#       }
#       # j'ajoute l'etat dynamique
#       lappend command -state $grafcet(${object},state)
#       # j'ajoute le type d'etape
#       lappend command -type $grafcet(${object},type)
#       # j'ajoute l'action associee si elle existe
#       if [info exist grafcet(${object},action)] {
#         lappend command -action $grafcet(${object},action)
#       }
#       # j'ajoute le fichier lie a l'etape macro si il existe
#       if [info exist grafcet(${object},file)] {
#         lappend command -file $grafcet(${object},file)
#       }
#       # j'ajoute le commentaire si il existe
#       if [info exist grafcet(${object},comment)] {
#         lappend command -comment $grafcet(${object},comment)      
#       }
#     } elseif { [Obj:getType $object] == "Trans" } {
#       # c'est une transition
#       # j'ajoute les coordonnees
#       set command "Trans:create -coord"
#       eval lappend command \{[expr $grafcet(${object},x) - $xRef] \
#         [expr $grafcet(${object},y) - $yRef]\}
#       # j'ajoute le nom generique
#       if $noName {
#         lappend command -name xXx$grafcet(${object},name)
#       } else {
#         lappend command -name $grafcet(${object},name)
#       }
#       # j'ajoute la receptivite si elle existe
#       if [info exist grafcet(${object},receptivity)] {
#         lappend command -receptivity $grafcet(${object},receptivity)
#       }
#       # j'ajoute le commentaire si il existe
#       if [info exist grafcet(${object},comment)] {
#         lappend command -comment $grafcet(${object},comment)      
#       }
#     } else {
#         continue
#     }
#     append interactiveCommands "\n$command"
#   } ; # end foreach
#     
#   # traitement des liaisons internes aux objets
#   # cas de l'edition manuelle des liaisons non traite
#   set links [Link:getInternalLinks $c $objects]
#   foreach link $links {
#     update
#     set command "Link:create "
#     set source [Link:getLinkSource $link]
#     set desti [Link:getLinkDesti $link]
#     if $noName {
#       set genericSource xXx$grafcet($source,name)
#       set genericDesti xXx$grafcet($desti,name)
#     } else {
#       set genericSource $grafcet($source,name)
#       set genericDesti $grafcet($desti,name)
#     }
#     if { [Obj:getType $source] == "Etape" } {
#       lappend command -source E$genericSource
#     } else {
#       lappend command -source T$genericSource
#     }
#     if { [Obj:getType $desti] == "Etape" } {
#       lappend command -desti E$genericDesti
#     } else {
#       lappend command -desti T$genericDesti
#     }
#     append interactiveCommands "\n$command"
#   }
#     
#   if $noName {
#     foreach object $objects {
#       update
#       set command ""
#       if { [Obj:getType $object] == "Etape" } {
#         lappend command Etape:modifyParams xXx$grafcet($object,name) name {}
#       } elseif ![string compare [Obj:getType $object] Trans] {
#         lappend command Trans:modifyParams xXx$grafcet($object,name) name {}
#       } else {
#         continue
#       }
#       append interactiveCommands "\n$command"
#     }
#   }
# # puts "IC==>$interactiveCommands<=="
#   return $interactiveCommands
# }


# proc Obj:getCommandsForClipboard {canvasSource canvasDest args} {
#   global gred
#   upvar #0 grafcet.[gred:getGrafcetName $canvasSource] grafcet
# 
#   # initialisation des parametres par defaut
#   # parametre -noName
#   set noName 0
#   # parametre -relativeCoord
#   set relativeCoord 0
#   set xRef 0
#   set yRef 0
#   
#   # traitement des arguments
#   while { [string match -* $args] } {
#     switch -glob -- [lindex $args 0] {
#       -- {
#         set args [lreplace $args 0 0] 
#         break
#       }
#       -noName {
#         set noName 1
#         set args [lreplace $args 0 0]
#         continue
#       }
#       -relativeCoord {
#         set relativeCoord 1
#         set args [lreplace $args 0 0]
#         continue
#       }
#       default { break }
#       
#     }
#   }
#   
#   set objects [eval concat $args]
#   
#   if $relativeCoord {
#     # si l'option "-relativeCoord" est presente :
#     # je calcule les coordonnees de reference, puis je les retire
#     # a chaque coordonnees d'objet.
#     set box [eval $c bbox $objects]
#     set xRef [lindex $box 0]
#     set yRef [lindex $box 1]
#   }
#   
#   # si l'option "-noName" est presente :
#   # je cree les objets avec un nom generique "bidon" mais intelligent !!
#   # par exemple "xXx1" a la place de "1"
#   # ceci afin de pouvoir cree les liaisons qui vont bien
#   # puis j'efface tous les noms generiques avec la procedure "ChangeParams"
#   
#   set interactiveCommands ""
#   set command ""
#   
#   # traitement des etapes et des transitions
#   foreach object $objects {
#     update
#     if { [Obj:getType $object] == "Etape" } {
#       # c'est une etape
#       # j'ajoute les coordonnees
#       set command "Etape:create $canvasDest -coord"
#       eval lappend command \{[expr $grafcet(${object},x) - $xRef] \
#         [expr $grafcet(${object},y) - $yRef]\}
#       # j'ajoute le nom generique
#       if $noName {
#         lappend command -name xXx$grafcet(${object},name)
#       } else {
#         lappend command -name $grafcet(${object},name)
#       }
#       # j'ajoute l'etat dynamique
#       lappend command -state $grafcet(${object},state)
#       # j'ajoute le type d'etape
#       lappend command -type $grafcet(${object},type)
#       # j'ajoute l'action associee si elle existe
#       if [info exist grafcet(${object},action)] {
#         lappend command -action $grafcet(${object},action)
#       }
#       # j'ajoute le fichier lie a l'etape macro si il existe
#       if [info exist grafcet(${object},file)] {
#         lappend command -file $grafcet(${object},file)
#       }
#       # j'ajoute le commentaire si il existe
#       if [info exist grafcet(${object},comment)] {
#         lappend command -comment $grafcet(${object},comment)      
#       }
#     } elseif { [Obj:getType $object] == "Trans" } {
#       # c'est une transition
#       # j'ajoute les coordonnees
#       set command "Trans:create $canvasDest -coord"
#       eval lappend command \{[expr $grafcet(${object},x) - $xRef] \
#         [expr $grafcet(${object},y) - $yRef]\}
#       # j'ajoute le nom generique
#       if $noName {
#         lappend command -name xXx$grafcet(${object},name)
#       } else {
#         lappend command -name $grafcet(${object},name)
#       }
#       # j'ajoute la receptivite si elle existe
#       if [info exist grafcet(${object},receptivity)] {
#         lappend command -file $grafcet(${object},receptivity)
#       }
#       # j'ajoute le commentaire si il existe
#       if [info exist grafcet(${object},comment)] {
#         lappend command -comment $grafcet(${object},comment)      
#       }
#     } else {
#         continue
#     }
#     append interactiveCommands "\n$command"
#   } ; # end foreach
#     
#   # traitement des liaisons internes aux objets
#   # cas de l'edition manuelle des liaisons non traite
#   set links [Link:getInternalLinks $canvasSource $objects]
#   foreach link $links {
#     update
#     set command "Link:create $canvasDest "
#     set source [Link:getLinkSource $link]
#     set desti [Link:getLinkDesti $link]
#     if $noName {
#       set genericSource xXx$grafcet($source,name)
#       set genericDesti xXx$grafcet($desti,name)
#     } else {
#       set genericSource $grafcet($source,name)
#       set genericDesti $grafcet($desti,name)
#     }
#     if { [Obj:getType $source] == "Etape" } {
#       lappend command -source E$genericSource
#     } else {
#       lappend command -source T$genericSource
#     }
#     if { [Obj:getType $desti] == "Etape" } {
#       lappend command -desti E$genericDesti
#     } else {
#       lappend command -desti T$genericDesti
#     }
#     append interactiveCommands "\n$command"
#   }
#     
#   if $noName {
#     foreach object $objects {
#       update
#       set command ""
#       if { [Obj:getType $object] == "Etape" } {
#         lappend command Etape:modifyParams $canvasDest \
#                                            xXx$grafcet($object,name) name {}
#       } elseif ![string compare [Obj:getType $object] Trans] {
#         lappend command Trans:modifyParams $canvasDest \
#                                            xXx$grafcet($object,name) name {}
#       } else {
#         continue
#       }
#       append interactiveCommands "\n$command"
#     }
#   }
# puts "IC==>$interactiveCommands<=="
#   return $interactiveCommands
# }

proc Obj:getCommandsForClipboard {canvasSource objects} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $canvasSource] grafcet
  
  
  
  # je calcule les coordonnees de reference, puis je les retire
  # a chaque coordonnees d'objet.
  set box [eval $canvasSource bbox $objects]
  set xRef [lindex $box 0]
  set yRef [lindex $box 1]
  set count 0
  update idletask
  set interactiveCommands ""
  set command ""
  set canvasDest _CANVAS_
  # traitement des etapes et des transitions
  foreach object $objects {
#     update idletask
    if { [Obj:getType $object] == "Etape" } {
      # c'est une etape
      # j'ajoute les coordonnees
      regexp "^oidEtape(\[0-9\]+)$" $object match oidId
      set command "Etape:add $canvasDest "
      eval append command \{[expr $grafcet(${object},x) - $xRef] \
        [expr $grafcet(${object},y) - $yRef]\}
        
      # j'ajoute le type d'etape
      lappend command $grafcet(${object},type)
      
      # j'ajoute le nom generique
      lappend command $grafcet(${object},name)

      # j'ajoute l'etat dynamique
      lappend command $grafcet(${object},state)
      
      # j'ajoute l'action associee si elle existe
      lappend command $grafcet(${object},action)

      # j'ajoute le fichier lie a l'etape macro si il existe
      lappend command $grafcet(${object},file)
      
      # j'ajoute le commentaire si il existe
      lappend command $grafcet(${object},comment)      
    } elseif { [Obj:getType $object] == "Trans" } {
      regexp "^oidTrans(\[0-9\]+)$" $object match oidId
      # c'est une transition
      # j'ajoute les coordonnees
      set command "Trans:add $canvasDest "
      eval append command \{[expr $grafcet(${object},x) - $xRef] \
        [expr $grafcet(${object},y) - $yRef]\}
      # j'ajoute le nom generique
      lappend command $grafcet(${object},name)      
      # j'ajoute la receptivite si elle existe
      lappend command $grafcet(${object},receptivity)
        
      # j'ajoute le commentaire si il existe
      lappend command $grafcet(${object},comment)      
    } else {
        continue
    }
    set indexOids(${object}) "\$tmp($count)"
    append interactiveCommands "\n set tmp($count) \[$command\]"
    incr count
  } ; # end foreach
    
  # traitement des liaisons internes aux objets
  # cas de l'edition manuelle des liaisons non traite
  set links [Link:getInternalLinks $canvasSource $objects]
  foreach link $links {
#     update idletask
    set command "Link:add $canvasDest "
    set source [Link:getLinkSource $link]
    set desti [Link:getLinkDesti $link]
    
    set genericSource $indexOids($source)
    set genericDesti $indexOids($desti)
    
    append command "$genericSource "
    append command "$genericDesti "
    append interactiveCommands "\n $command"
  }
  append interactiveCommands "\n Sel:new $canvasDest \[elementsImpaires \[array get tmp\]\]"
  append interactiveCommands "\n unset tmp"
  
# puts "IC==>$interactiveCommands<=="
  return $interactiveCommands
}

proc elementsImpaires {l} {
    set outputList {}
    foreach {el el2} $l {
        lappend outputList $el2
    }
    return $outputList
}

########################################################################
# Sel:move -- Déplacement de dx,dy d'une liste d'oid 
# 
# 
# 
proc moveForUndo {c args} {
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  set dx [lindex $args 0]
  set dy [lindex $args 1]
  set loid [lrange $args 2 end]
  
  # On desselectionne les liens avant déplacement de la sélection :
  set loid [Obj:filterType -not {Link} $loid]
  
  # On sépare les oids "noeuds" (Etape et Trans), les liens internes, 
  # et les liens externes a la selection.
  set noids [Obj:filterType {Etape Trans} $loid]
  set internal_loids [Link:getInternalLinks $c $loid]
  set external_loids [Link:getExternalLinks $c $loid]
      
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
  # (PAS DE REGEXP d'oid ICI -> Obj:move)
#   set regPat \
#       {^oid(Link[0-9]+)(Etape[0-9]+|Trans[0-9]+)(Etape[0-9]+|Trans[0-9]+)$}
  foreach loid $external_loids {
#     regexp $regPat $loid full link source desti
#     set idSource oid$source
#     set idDesti oid$desti
# 
#     Link:delete $c $loid
#     Link:add $c $idSource $idDesti
    Link:draw $c $loid
  }
  # mise a jour des rectangles de selection
  Sel:redraw $c
}

proc Object:FindFromName {c} {
    global tmp
    
    Prompt_Box     -title "Chercher un objet ?" \
                   -parent .find \
                   -entries [subst { 
      {-type ENTRY -variable tmp(name) \
                   -label "Nom de l'objet"} 
      {-type SEPARATOR -line down}
      {-type RADIOBUTTON -label "Type d'objet" -default Etape \
        -typearg {Etape Transition} -variable tmp(type)}}]
        
    if {$tmp(type) == "Transition"} {
        set tmp(type) "Trans"
    }
    
    $tmp(type):find $c $tmp(name)
    
    unset tmp
}