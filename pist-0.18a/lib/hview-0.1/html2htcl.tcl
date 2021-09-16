#!/bin/sh
# the next line restarts using wish \
exec wish8.0 "$0" -- ${1+"$@"}

package provide hview 0.1

source [file join [file dirname [info script]] hviewTkhtml.tcl]

########################################################################
# Genere un fichier ou plusieurs fichier htcl en fonction des parametres
# specifies dans la ligne de commande args.
# PARAMETRES : 
#     ENTREE :
#        - args : option -file <file> pour specifier le nom d'un fichier
#                 a compiler
#                 option -directory <dir> pour specifier une arborescence
#                 a compiler
# 
# Modif :
#  diam 23/03/97 : suppression du exit
########################################################################
proc html2htcl {args} {
    global argc argv
    set tmpFile [pwd]
    set argc [llength $args]
    if {$argc < 2} { 
        showHelp
        exit
    }
    while {[string match -* $args]} {
       switch -glob -- [lindex $args 0] {
          --         { 
             set args [lreplace $args 0 1]
             break
          }
          -tmpDir {
            set tmpFile [file join [lindex $args 1] tmp]
            set args [lreplace $args 0 1]
          }
          -file   {
            set file [lindex $args 1]
            set args [lreplace $args 0 1]
            if [file exists $file] {
                initialiseTextWidget
                compile $file $tmpFile
                destroyTextWidget
            } else {
                error "$file doesn't exists."
            }
          }
          -directory {
            set dir [lindex $args 1]
            set args [lreplace $args 0 1]
            if [file isdirectory $dir] {
                compileDirectory $dir $tmpFile
            } else {
                error "$dir isn't a directory."
            }
          }
          -h* {
              showHelp
              exit 0
          }
          -*         { 
              error "unknow option $argv"
              exit 1
          }
          default    { 
              break  ; # no more options
          }
       }
    }
    # exit 0
} ; # endproc main

# lempty <list>  => return 1 if <list> is empty, 0 otherwise
# one can use insteed : if ![llength $my_list]   {...}
# insteed of :          if [lempty $my_list]     {...}
proc lempty {  l  } {
    return [string match 0 [llength $l]]
} ; # endproc lempty

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
########################################################################
proc recursive_glob {dirlist globlist} {

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
} ; # endproc recursive_glob

########################################################################
# proc initialiseTextWidget --
# Permet de creer 2 widgets text qui ne seront jamais pasckes. Ainsi
# On peut utiliser les fonctionnnalites des widgets text tout en gardant
# un execution en BATCH
# PARAMETRES : Aucun
########################################################################
proc initialiseTextWidget {} {
    frame .help
    frame .help.text  -relief raised
    text .help.text.t -relief groove 
    
    # Creating the second scrollbar and the text widget
    frame .help.text2 -relief raised
    text .help.text2.t -relief groove 
} ; # endproc initialiseTextWidget

########################################################################
# proc destroyTextWidget --
# Permet de detruire les 2 widgets text.
# PARAMETRES : Aucun
########################################################################
proc destroyTextWidget {} {
    destroy .help.text.t
    destroy .help.text2.t
    destroy .help.text
    destroy .help.text2
    destroy .help
} ; # endproc destroyTextWidget

########################################################################
# proc generateHtclFile --
# Genere un fichier htcl en fonction de l'etat des widgets text ET des 
# fichiers temporaires crees lorsque l'on a parse le fichier HTML
# PARAMETRES : 
#     ENTREE :
#        - fichier : Nom du fichier htcl a generer
########################################################################
proc generateHtclFile {fichier} {
    global tkhtml_priv
    # On ecrit le fichier cache (ie le fichier htcl) !
    set temp $tkhtml_priv(tmpFile)
    set file [open $fichier w+]
    # On recopie le fichier contenant le texte du fichier HTML
    # Comme etant la premiere partie du ficheir de cache
    set f [open [file join ${temp} 1.htcl] r]
    set txt [read $f]
    puts $file $txt
    close $f
    file delete -force [file join ${temp} 1.htcl]
    # On recopie le fichier contenant le texte du fichier HTML
    # Comme etant la premiere partie du ficheir de cache
    set f [open [file join ${temp} 1bis.htcl] r]
    set txt [read $f]
    puts $file $txt
    close $f
    file delete -force [file join ${temp} 1bis.htcl]
    # On recopie le fichier contenant la definition des tags
    # a la suite du fichier de cache
    set f [open [file join ${temp} 2.htcl] r]
    set txt [read $f]
    puts $file $txt
    close $f
    file delete -force [file join ${temp} 2.htcl]
    
    puts $file "\$widget1 configure -state disabled"
    puts $file "\$widget2 configure -state disabled"
        
    # On recopie le fichier contenant l'emplacement des tags
    # a la suite du fichier de cache
    set f [open [file join ${temp} 3.htcl] r]
    set txt [read $f]
    puts $file $txt
    close $f
    file delete -force [file join ${temp} 3.htcl]
    close $file
    unset txt
} ; # endproc generateHtclFile
proc createImage {dir file} {
    image create photo -file [file join $dir $file]
}
########################################################################
# proc compile --
# Genere un fichier htcl grace au package tkhtml, on commence par
# installer les procedures utilies au package tkhtml. Puis on parse le 
# fichier d'entree.
# PARAMETRES : 
#     ENTREE :
#        - htmlFile : Nom du fichier html a parser
########################################################################
proc compile {htmlFile tmpFile} {
    set newFileGenered 0
    set f [open $htmlFile]
    set txt [read $f]
    close $f
    set slot(steps) [string length $txt]
    set slot(len) [string length $txt]
    set slot(remaining) $slot(len)

    set file [file rootname $htmlFile]
    set extension [file extension $htmlFile]
    # On genere le fichier htcl correspondant, si le fichier d'entree 
    # (a compiler) est du style :
    #     a.html ou a.htm : le fichier htcl sera a.htcl
    if [string match "*htm*" $extension] {
        if [file exists $file.htcl] {
            # On genere le fichier htcl si sa date est inferieur a celle
            # du fichier html
            set generate $file.htcl
            if {[file mtime $htmlFile] < [file mtime $file.htcl]} {
                puts "No compilation needed for $htmlFile"
                return
            }
        } else {
            set generate $file.htcl
        }
    } else {
        return
    }
    puts "COMPILING $htmlFile"
    tkhtml_set_command_href ".help.text.t follow_link"
    tkhtml_set_command_header ".help.text.t searchTag"
    tkhtml_set_tmpFile $tmpFile
    tkhtml_set_imagePath [file dirname $htmlFile] 
    tkhtml_set_image_hook "createImage "
    tkhtml_render .help.text.t .help.text2.t $txt
    
    # On genere le cache associe (ie le fichier htcl)
    generateHtclFile $generate
} ; # endproc compile

########################################################################
# proc compileDirectory --
# Genere un fichier htcl grace au package tkhtml pour chaque fichier 
# du repertoire. Il s'agit d'une copilation recursive qui compile tous
# les fichiers des sous-repertoires.
# PARAMETRES : 
#     ENTREE :
#        - htmlFile : Nom du fichier html a parser
########################################################################
proc compileDirectory {directory tmpFile} {
    initialiseTextWidget
    set listOfFile [recursive_glob $directory *]
    foreach file $listOfFile {
        set extension [file extension $file]
        # On compile le fichier que si c'est un fichier d'extension html
        if {[file isfile $file] && [string match "*htm*" $extension]} {
            compile $file $tmpFile
        }
    }
    destroyTextWidget
} ; # endproc compileDirectory

########################################################################
# proc showHelp --
# Imprime l'aide pour utiliser html2htcl.
# PARAMETRES : Aucun
########################################################################
proc showHelp {} {
    puts "html2htcl"
    puts "Permet de compiler des fichier html pour qu'ils soient directement"
    puts "lisible par la procedure affiche_html"
    puts "UTILISATION :"
    puts "    Option -file :       permet de specifier un nom de fichier a "
    puts "                         compiler,"
    puts "    Option -directory :  permet de compiler tous les fichiers "
    puts "                         d'une arborescence,"
    puts "    Option -- :          Indique que les options suivantes ne sont"
    puts "                         pas a prendre en compte,"
    puts "    Option -help ou -h : afficher cette aide."
} ; # endproc showHelp