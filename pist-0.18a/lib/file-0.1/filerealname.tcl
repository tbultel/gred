package provide file 0.1

########################################################################
# file:realName <fileOrDir>
#    retourne le nom absolu physique › partir d'un nom relatif 
#    ou absolu, et en suivant les liens éventuels.
#    "name" peut etre un nom de fichier ou de répertoire QUI DOIT EXISTER
#    exemple :  file:realName /usr/local/bin/stead
#    retourne : /usr/vb/amd/lib/STEAD-0.36-alpha/stead
# 
# A FAIRE : envisager constantes global : 
#     file(parent) ("..",  ou "::")
#     file(...)
#     global file
#     if ![info exist file(separator)] {
#        initialiser les contantes file(..)
#     }
# A FAIRE traiter differemenet le cas unix des cas windows et Macintosh
#         pour lesquel c'est plus simple (pas d'automontage)
# 
# 16/07/96 : refonte complete suppression recursives des liens dans le path
#            fiable m‘ème si automontages car ne suit pas les lien /tmp_mnt 
#            ou /auto/...
#            Le résultat ne contient ni "." ni ".."
#            On peut donc utiliser [file dirname [file dirname ..]]
#            sur le résultat de cette procédure.
#            En principe multiplatteforme (non testé à font pour l'instant
#            
########################################################################

proc file:realName {name} {

    # # glob make the tilda substitution like "~/bin/appli" :
    # set name [glob $name]
    
    # If the name is relative: one make it absolute
    if {[file pathtype $name] == "relative"} {
       set name [file join [pwd] $name]
    }
    # /usr/local/bin/../../amd/bin/./te
    # One follow all possible links in the path
    set name [file:followLinks $name]
    # could be "/usr/local/bin/../../m2b/lei/bin/../lib/./stead_v036a/stead"
    
    # remove directory nodes like "." or ".." from the path
    set lpath [file split $name]    ;# full path list {/ usr local ...}
    set finalPath [lindex $lpath 0] ;# root could be "/" or "MacOS:"
    set lpath [lreplace $lpath 0 0] ;# rest of lpath {usr local ...}
    foreach node $lpath {
        switch -exact -- $node {
          .  continue
          .. {
             set finalPath [file dirname $finalPath]
             continue
          }
          default {
             set finalPath [file join $finalPath $node]
          }
        }
    }
    return $finalPath
    
} ;# endproc file:realName

# file:followLink <absoluteName> : 
# Return an absolute name without any link in the path.
# But could return something like :
#    "/usr/local/bin/../../m2b/lei/bin/../lib/./stead_v036a/stead"
# Principe:
# One follow a possible link (which can be absolute or relative)
# for the tail node, then recurse for all parents directories.
# One don't follow links starting with /tmp_mnt/ ou /auto/
# to avoid problems with auto"un"mount directories under unix NFS
proc file:followLinks {name} {
  while {[string match "link" [file type $name] ]} {
    set followName [file readlink $name]
    if {[regexp {^(/tmp_mnt/)|(/auto/)} $followName]} {break}
    if {[file pathtype $followName] == "relative"} {
      set followName [file join  [file dirname $name] $followName]
    }
    set name $followName
  }
  set dir [file dirname $name]
  if {"x$dir" == "x$name"} {
     return $name
  } else {
     return [file join [file:followLinks $dir] [file tail $name]]
  }    
} ;# endproc file:followLinks
