package provide tclx 0.1


#
# globrecur.tcl --
#
#  Build or process a directory list recursively.
#------------------------------------------------------------------------------
# Copyright 1992-1994 Karl Lehenbauer and Mark Diekhans.
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose and without fee is hereby granted, provided
# that the above copyright notice appear in all copies.  Karl Lehenbauer and
# Mark Diekhans make no representations about the suitability of this
# software for any purpose.  It is provided "as is" without express or
# implied warranty.
#------------------------------------------------------------------------------
# $Id: globrecur.tcl,v 1.1.1.1 1997/03/28 14:49:22 diam Exp $
#------------------------------------------------------------------------------
#

########################################################################
# recursive_glob : retourne une liste rªcursive de fichiers ou rªpertoires
# sous la forme <dir>/<relativeFilePath>
# Attention la liste optenue peut contenir des rªpertoires ou des 
# doublons (de la meme fa°on que la commande UNIX "ls * *)"
# exemple : recursive_glob . * 
#    retourne {./rep1 ./fich1 ./fich2 ./rep1/fic11 ./rep1/fic12 ....)
#   
# REMARQUE : Attention si globlist contient ".*" alors les rªpertoires
# de la forme ".../." et .../.." font partie du rªsultat !!
# exemple d'utilisation :
#  set ABS [recursive_glob [pwd] $listOfPatterns]
#      liste de noms absolus
#  set REL [lcutleft $ABS [expr [string length [pwd]] + 1]]
#      liste de noms relatifs
# Modif 10/06/96 : compatibiltit» Mac et Windows (utilisation de la commande
#                  file join...) : Problemes potenciel avec fichier invisibles 
#                  pour unix (* et .*)
proc recursive_glob {dirlist globlist} {
    # # global tcl_platteform
    # # switch $tcl_platform(platform) {
    # #     macintosh {recursive_globMac $dirlist $globlist}
    # #     windows   {}
    # #     unix      {}
    # # }

    set result {}
    set recurse {}
    foreach dir $dirlist {
        if ![file isdirectory $dir] {
            error "\"$dir\" is not a directory"
        }
        foreach pattern $globlist {
            set result [concat $result \
                [glob -nocomplain -- [file join $dir $pattern]]]
        }
        foreach file [glob -nocomplain -- [file join $dir *]  \
                                          [file join $dir .*] ] {
            if [file isdirectory $file] {
                # should not process special cases of "." and ".." on Mac ?
                set fileTail [file tail $file]
                if {!(($fileTail == ".") || ($fileTail == ".."))} {
                    lappend recurse $file
                }
            }
        }
    }
    if ![lempty $recurse] {
        set result [concat $result [recursive_glob $recurse $globlist]]
    }
    return $result
}

# Exemple (sous tclsh)
# proc frg  args {uplevel  for_recursive_glob $args}
# frg file . {*[~%]} {ls -al $file}
proc for_recursive_glob {var dirlist globlist code {depth 1}} {
    # # global tcl_platteform
    # # switch $tcl_platform(platform) {
    # #     macintosh {recursive_globMac $dirlist $globlist}
    # #     windows   {}
    # #     unix      {}
    # # }
    upvar $depth $var myVar
    set recurse {}
    foreach dir $dirlist {
        if ![file isdirectory $dir] {
            error "\"$dir\" is not a directory"
        }
        foreach pattern $globlist {
            foreach file [glob -nocomplain -- [file join $dir $pattern]] {
                set myVar $file
                uplevel $depth $code
            }
        }
        foreach file [glob -nocomplain -- [file join $dir *]  \
                                          [file join $dir .*] ] {
            if [file isdirectory $file] {
                # should not process special cases of "." and ".." on Mac ?
                set fileTail [file tail $file]
                if {!(($fileTail == ".") || ($fileTail == ".."))} {
                    lappend recurse $file
                }
            }
        }
    }
    if ![lempty $recurse] {
        for_recursive_glob $var $recurse $globlist $code [expr {$depth + 1}]
    }
    return {}
}
