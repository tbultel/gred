package provide xtcl 0.1


# 12/05/97 (diam) : rajout des proc ladd, lsub et lmult



# lunique ?-options? <list>
# Return a list where all duplicated element are removed
# make use of an array with an empty name!
# 
# option:
#    -sort (default): the returned list is sorted
#    -nosort: result is in arbitrared order
#    -keeporder: keep the same order than the original list
#
# For critical cases: you can use the shortest names without using
# procedure call:
#      set b [foreach x $a {set u($x) 1};array names u]

proc lunique {args} {
   set MODE  -sort
   set i 0
   while "\$i < [string length $args]" {
       set arg [lindex $args $i]
       switch -glob -- $arg {
          --       {incr i ; break}
          -nosort    -
          -sort      -
          -keeporder {set MODE $arg; incr i; continue}
          -*         {error "unknow option $arg"}
          default    {break  ;# no more options}
       }
   }
   # i point on the next unread argument
   set list    [lindex $args $i]

   switch -exact -- $MODE {
     -nosort {
        foreach e $list   {set ($e) 1}
        return [array names ""]
     }
     -sort {
        foreach e $list   {set ($e) 1}
        return [lsort [array names ""]]
     }
     -keeporder {
        set result {}
        foreach e $list {
            if [info exists ($e)] continue
            set ($e) ""
            lappend result $e
        }
        return $result
     }
   }
}


# # procedure de gestion de liste (Tom Phelps (phelps@cs.Berkeley.EDU) )
# #
# proc lfirst   {l} {return [lindex $l 0]}
# proc lsecond  {l} {return [lindex $l 1]}
# proc lthird   {l} {return [lindex $l 2]}
# proc lfourth  {l} {return [lindex $l 3]}
# proc lfifth   {l} {return [lindex $l 4]}
# # five is enough to get all pieces of `configure' records
# proc lsixth   {l} {return [lindex $l 5]}
# proc lseventh {l} {return [lindex $l 6]}
# proc llast    {l} {return [lindex $l end]}

########################################################################
# lreverse <list> => return return a reversed ordered list
proc lreverse {l} {
   set l2 ""
   for {set i [expr [llength $l]-1]} {$i>=0} {incr i -1} {
      lappend l2 [lindex $l $i]
   }
   return $l2
}


########################################################################
# lfound ?-mode? list pattern
# return 1 if there is one matched element 0 otherwise
# option could be one of -glob, -exact or -regexp (as for lsearch)
# A FAIRE : REMPLACER <pattern> par <patternList> 
# en CONCATENANT les arguments residuels.
# exemple if {[lfound <biglist> <elemListToSearchFor>]} {...}
proc lfound args {
    return [expr [eval lsearch $args] != -1]
}

###########################################################################
# lmatch ?-first? ?-mode? list pattern
# 
# Search the elements of list, returning a list of all elements
# matching pattern.  If none match, an empty list is returned.
# mode is one of: -exact, -glob, -regexp (-glob is default)
# option: -first for include only the first matched element
# 
# Example :
#  set subList [lmatch -first -regexp -- $myList $myPattern]
# 
# diam@ensta.fr 24/05/96
# 
# A FAIRE : 
# 1 - REMPLACER <pattern> par <patternList> <patternList> ...
#     en CONCATENANT les arguments residuels.
# 2 - rajouter options (exclusives) -and et -or permettant de choisir entre 
#     l'intersection et la reunion des patterns a satisfaire
#     TOUT EN CONCERVANT L'ORDRE !
# 
proc lmatch {args} {
   set FIRST 0
   set MODE  -glob
   set i 0
   while "\$i < [string length $args]" {
       set arg [lindex $args $i]
       switch -glob -- $arg {
          --       {incr i ; break}
          -first   {set FIRST 1; incr i; continue}
          -exact   -
          -glob    -
          -regexp  {set MODE $arg; incr i; continue}
          -*       {error "unknow option $arg"}
          default  {break  ;# no more options}
       }
   }
   # i point on the next unread argument
   set list    [lindex args $i]
   set pattern [lindex args [incr i]]

   set result {}
   foreach e $list {
     switch $MODE -- $e $pattern {
         lappend result $e
         if $FIRST "return $e"
     }
   }
   return $result
}
###########################################################################
# lexclude ?-first? ?-mode? list pattern
# Search the elements of list, returning a list of all elements
# not matching pattern.  If none match, an empty list is returned.
# mode is one of: -exact, -glob, -regexp
# if option -first then excluding only the first matched element
# diam@ensta.fr 24/05/96
# A FAIRE
# 1 - REMPLACER <pattern> par <patternList> <patternList> ...
# en CONCATENANT les arguments residuels.
# proc lexclude {args} {
#    set FIRST 0
#    set MODE  -glob
#    set i 0
#    while "\$i < [string length $args]" {
#        set arg [lindex $args $i]
#        switch -glob -- $arg {
#           --       {incr i ; break}
#           -first   {set FIRST 1; incr i; continue}
#           -exact   -
#           -glob    -
#           -regexp  {set MODE $arg; incr i; continue}
#           -*       {error "unknow option $arg"}
#           default  {break  ;# no more options}
#        }
#    }
#    # i point on the next unread argument
#    set list    [lindex $args $i]
#    set pattern [lindex $args [incr i]]
#    if $FIRST {
#       set idx [lsearch $MODE $list $pattern]
#       return [lreplace $list $idx $idx]
#    } else {
#       set result {}
#       foreach e $list {
#         switch $MODE -- $e $pattern {} default {
#             lappend result $e
#         }
#       }
#       return $result
#    }
# }

###########################################################################
# lexclude ?-first? ?-mode? list patterns patterns ...
# Search the elements of list, returning a list by removing all elements
# in the patterns lists (which are concatained).  
#  
# principe :
# 
#  on peut eviter d'utiliser cette procedure :
# 
#      while {[set ndx [lsearch -exact $list $element]] != -1} {
#         set list [lreplace $list $ndx $ndx]
#      }
# 
# options: 
# 
# -mode:  -exact | -glob | -regexp : (default to glob: id lsearch)
# -first: then excluding only the first matched element.
#         The first pattern is match first against the wall list
#         before looking for other patterns.
# 
# examples :
# 
#    set L {popo popi {pi pi} pipi pkpk lolo lili popi}
#       popo popi {pi pi} pipi pkpk lolo lili popi
#    lexclude -exact $L {popo pipi} popi {pi pi}
#       {pi pi} pkpk lolo lili
#    lexclude -exact $L {popo pipi} popi {pi\ pi}
#       pkpk lolo lili
#    lexclude -first $L pi*
#       popo popi pipi pkpk lolo lili popi
# 
# diam@ensta.fr 26/07/96 : list of patterns instead of only one pattern
proc lexclude {args} {
   set FIRST 0
   set MODE  -glob
   set i 0
   while "\$i < [string length $args]" {
       set arg [lindex $args $i]
       switch -glob -- $arg {
          --       {incr i ; break}
          -first   {set FIRST 1; incr i; continue}
          -exact   -
          -glob    -
          -regexp  {set MODE $arg; incr i; continue}
          -*       {error "unknow option $arg"}
          default  {break  ;# no more options}
       }
   }
   # i point on the next unread argument
   set list    [lindex $args $i]
   set patterns [join [lreplace $args 0 $i]]
   foreach p $patterns {
      if {[set ndx [lsearch $MODE $list $p]] == -1} continue
      set list [lreplace $list $ndx $ndx]
      if !$FIRST {
         while {[set ndx [lsearch $MODE $list $p]] != -1} {
            set list [lreplace $list $ndx $ndx]
         }
      }
   }
   return $list
   
}


########################################################################
# llongest <list> retourne la taille du plus long element de la liste
proc llongest list {
    set max 0
    foreach e $list {
        if {[set len [string length $e]] > $max} {set max $len}
    }
    return $max
}
########################################################################
# lcutleft <liste> <N>
# retourne la liste <liste>, mais dont les »l»ments sont tronqu»s ›
# gauche de N caractÀres.
proc lcutleft {list N} {
    set result ""
    foreach e $list {
        lappend result [string range $e $N end]
    }
    return $result
} ;#endproc lcutleft

########################################################################
# laddleft <liste> <string>
# retourne la liste <liste>, mais dont les »l»ments sont pr»fix»s ›
# gauche par la chaine <string>.
proc laddleft {list str} {
    set result ""
    foreach e $list {
        lappend result "$str$e"
    }
    return $result
} ;#endproc laddleft


# PREVOIR AUSSI lsub smult.

########################################################################
# lsum -- addition de listes : list = list1 + list2
# 
# Retourne une liste formée de la somme de chaque éléments des 
# deux listes <list1> et <list2>
# Les deux parametres <list[12]> doivent etre de meme longueur
# 
proc lsum {list1 list2} {
   if {[llength $list1]!=[llength $list2] || ![llength $list1]} {
      error "lsum requests the two lists are not empty \
            and of the same length"
   }
   set list {}
   foreach e1 $list1 e2 $list2 {
      lappend list [expr {$e1 + $e2}]
   }
   return $list
}

########################################################################
# lsub --  soustraction de listes : list = list1 - list2
# 
# Retourne une liste (ou un vecteur) formée de la différence 
# de chaque éléments des deux listes <list1> et <list2>
# Les deux parametres <list[12]> doivent etre de meme longueur
# 
proc lsub {list1 list2} {
   if {[llength $list1]!=[llength $list2] || ![llength $list1]} {
      error "lsub requests the two lists are not empty \
            and of the same length"
   }
   set list {}
   foreach e1 $list1 e2 $list2 {
      lappend list [expr {$e1 - $e2}]
   }
   return $list
}

########################################################################
# lmult --  multiplication de listes : list = list1 x list2
# 
# Retourne une liste (ou un vecteur) formée de la différence 
# de chaque éléments des deux listes <list1> et <list2>
# Les deux parametres <list[12]> doivent etre de meme longueur
# 
proc lmult {list1 list2} {
   if {[llength $list1]!=[llength $list2] || ![llength $list1]} {
      error "lmult requests the two lists are not empty \
            and of the same length"
   }
   set list {}
   foreach e1 $list1 e2 $list2 {
      lappend list [expr {$e1 * $e2}]
   }
   return $list
}


# ########################################################################
# # re_split <regpatterne> <string>
# # Then ``re_split { +} {A B  C   D}'' would return [list A B C D].
# #
# # N'est utile que si on ne peut pas trouver de caractere non utilis» dans
# # la chaine › couper (i.e \n)
# # Utiliser de pr»f»rence les deux commandes suivantes :
# #     regsub -all $regp $str "\n" result
# #     set result [split $result "\n"]
# #
# proc re_split {re str} {
#   set result {}
#   set match {}
#
#   if {$str == ""} { return {} }
#
#   while {[regexp -indices $re $str match]} {
#     set L [lindex $match 0]
#     set R [lindex $match 1]
#
#     # stop if we see a zero length match, since we can't step over
#     # it easily.
#     if {$R < $L} { break }
#
#     # left is 0..L-1; match is L..R; right is R+1..end
#
#     set result [concat $result [list [string range $str 0 [incr L -1]]]]
#     set str [string range $str [incr R 1] end]
#   }
#   return [concat $result [list $str]]
# }
