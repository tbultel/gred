#!/bin/sh
# the next line restarts using wish \
exec tclsh "$0" ${1+"$@"}

########################################################################
# Fichier permettant de parser un ou plusieurs fichiers TCL en vue de 
# générer automatiquement une documentation HTML sur ces fichiers.
# La méthode consiste à utiliser plusieurs fichiers temporaires puis de
# concaténer ces fichiers pour genérer un fichier HTML.
# <DL>
# <DT>Description des fichiers temporaires :
# <DD><I>$pistMkDoc(tmpDir)/lof.tmp</I> : Contient la liste des fichiers
#  dont on veut genérer une documentation. Ce channel est mémorisé dans
#  pistMkDoc(lof) (lof comme Liste Of File)
# <DT>La procédure parseTCLFile utilise 2 fichiers temporaires :
# <DD><I>$pistMkDoc(tmpDir)/lop.tmp</I> : Contiendra la liste des
#  procédures dans fichier TCL parsées par parseTCLFile (lop comme 
#  Liste Of Proc)
# <DD><I>$pistMkDoc(tmpDir)/dop.tmp</I> : Contient la description HTML 
#  des procédures du fichier TCL parsées par parseTCLFile 
#  (dop comme Description Of Proc)
# <DT>Enfin un dernier fichier est nécessaire comme accumulateur :
# <DD><I>$pistMkDoc(tmpDir)/ldop.tmp</I> : Contient la description
#  des fichiers TCL déjà parsée par la procédure parseTCLFile. Ce 
#  channel est mémorisé dans pistMkDoc(ldop) (ldop comme Liste and
#  Description Of Proc)
# </DL>
########################################################################

global pistMkDoc

########################################################################
# lempty -- Return 1 if it argument is empty
# lempty <i>list</i>  => return 1 if <i>list</i> is empty, 0 otherwise
# one can use insteed : if ![llength $my_list]   {...}
# insteed of :          if [lempty $my_list]     {...}
########################################################################
proc lempty {  l  } {
    return [string match 0 [llength $l]]
} ; # endproc lempty

########################################################################
# recursive_glob -- Retourne une liste récursive d'éléments d'un répertoire
# Retourne une liste récursive de fichiers ou répertoires
# sous la forme <i>dir</i>/<i>relativeFilePath</i>.
# Attention la liste optenue peut contenir des répertoires ou des 
# doublons (de la meme façon que la commande UNIX "ls * *)"<p>
# 
# Arguments:
#  dirlist - Répertoire de base où va s'effectuer la recherche
#  globlist - Pattern permettant de selectionner les fichiers 
# Exemple:
#  recursive_glob . * 
#  retourne {./rep1 ./fich1 ./fich2 ./rep1/fic11 ./rep1/fic12 ....}
# Remarque:
#  Attention si globlist contient ".*" alors les répertoires
#  de la forme ".../." et .../.." font partie du résultat !!
# Exemple d'utilisation:
#  <CODE>set ABS [recursive_glob [pwd] $listOfPatterns]</CODE> : liste
#   de noms absolus<br>
#  <CODE>set REL [lcutleft $ABS [expr [string length [pwd]] + 1]]</CODE>
#   : liste de noms relatifs
# Modif 10/06/96:
#  compatibilité Mac et Windows (utilisation de la commande file join...).<BR>
#  Problemes potentiels 
#  avec les fichiers invisibles pour unix (* et .*)
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
# showHelp -- Imprime l'aide pour utiliser html2htcl.
########################################################################
proc showHelp {} {
    puts "pistMkDoc"
    puts "Permet de générer une documentation html à partir de fichier"
    puts "source tcl"
    puts "UTILISATION :"
    puts "    Option -files \"Liste de fichier\" :"
    puts "           permet de spécifier un liste de fichier à"
    puts "           dont on veut générer la documentation,"
    puts "    Option -f :"
    puts "           force l'effacement des fichiers"
    puts "    Option -out FileName :"
    puts "           Nom du fichier HTML de sortie, si cette"
    puts "           option n'est pas spécifiée le nom du fichier"
    puts "           de sortie est \"a.html.\""
    puts "    Option -tmp Directory :"
    puts "           Si cette option n'est pas précisée, les fichiers"
    puts "           temporaires seront placés dans les répertoire"
    puts "           courant, ou bien dans le même répertoire que le"
    puts "           fichier HTML de sortie si l'option -out est précisée."
    puts "    Option -- :"
    puts "           Indique que les options suivantes ne sont"
    puts "           pas a prendre en compte,"
    puts "    Option -help ou -h :"
    puts "           affiche cette aide."
} ; # endproc showHelp

proc pistMkDocInit {} {
    global pistMkDoc
    set pistMkDoc(fileCounter) 0
    set pistMkDoc(procCounter) 0
    # list of file
    file delete [file join $pistMkDoc(tmpDir) lof.tmp]
    # list of proc
    file delete [file join $pistMkDoc(tmpDir) ldop.tmp]
    # On cree un canal pour chaque fichier temporaire
    set pistMkDoc(lof) [open [file join $pistMkDoc(tmpDir) lof.tmp] w+]
    set pistMkDoc(ldop) [open [file join $pistMkDoc(tmpDir) ldop.tmp] w+]
    
    puts $pistMkDoc(lof) "<H1>LIST OF FILES</H1>\n<OL TYPE=1>"
} ; # end proc pistMkDocInit

proc pistMkDocClose {} {
    global pistMkDoc
    
    puts $pistMkDoc(lof) "</OL>\n<P>\n<HR SIZE=5 WIDTH=\"100%\">"
    # On recolle le fichiers temporaire pour faire
    # le joli fichier HTML de documentation...
    seek $pistMkDoc(lof) 0 start
    seek $pistMkDoc(ldop) 0 start
    
    if {[file exists $pistMkDoc(outputFile)] 
        &&  !$pistMkDoc(deleteExistingFile)} {
        error "file : $pistMkDoc(outputFile) already exists." 
        exit 1
    }
    set output [open $pistMkDoc(outputFile) w]
    set txt [read $pistMkDoc(lof)]
    puts $output $txt
    set txt [read $pistMkDoc(ldop)]
    puts $output $txt
    close $pistMkDoc(lof)
    close $pistMkDoc(ldop)
    close $output
    puts "$pistMkDoc(outputFile) generate"
    file delete [file join $pistMkDoc(tmpDir) lof.tmp]
    file delete [file join $pistMkDoc(tmpDir) ldop.tmp]
} ; # end proc pistMkDocClose

########################################################################
# addLine -- Parse une chaîne TCL, pour en extraire les commentaires
# Cette fonction supprime les "#" en début de ligne
# Arguments:
#  dop - Nom du fichier où les infos en HTML doivent être sauvées
#  comment - Contenu du commentaire
# Effets de bord:
# Calls:
# Outputs:
# Ajoute des informations dans le fichier pointé par <I>dop</I>
# Returns:
########################################################################
proc addLine {dop comment} {
    while {[regexp -indices "#\[ \t\]+(\[^\n\]+)\n" $comment \
                                                match line]} {
       # On rajoute le commentaire dans dop
       puts $dop [string range $comment [lindex $line 0]\
                                                 [lindex $line 1]]
       set comment [string range $comment \
                                         [lindex $line 1] end]
    } ; # end while
} ; # end proc addLine

########################################################################
# insereInfo -- Parse une chaîne TCL, pour en extraire les commentaires
# Procédure permettant de parser une chaîne Tcl, pour en extraire des
# données HTML en vue de générer une documentation automatique.
# Si <I>categorie</I> vaut "Arguments" parse une chaine du type
# <PRE>"# arg1 - Infos sur l'argument 1
#           Complément d'information sur l'argument 1
#        # arg2 - Infos sur l'argument 2
#        etc..."</PRE> pour générer une liste en HTML.
# Sinon renvoie le simplement le texte en supprimant les "#" en tête de ligne
# Arguments:
#  dop - Nom du fichier où les infos en HTML doivent être sauvées
#  categorie - Catégorie du commentaire
#  categorieComment - Contenu du commentaire
# Effets de bord:
# Calls:
#  addLine
# Outputs:
# Ajoute des informations dans le fichier pointé par <I>dop</I>
# Returns:
########################################################################
proc insereInfo {dop categorie categorieComment} {
    set s "\[ \t\]"
    puts $dop "      <LI><B>$categorie</B><br>"
    switch -- $categorie {
        Arguments {
            # On stocke les commentaires concernant la procédure 
            # dans le fichier dop
            puts $dop "<OL TYPE=a>"
            while {[regexp -indices "$s+-$s+" $categorieComment match]} {
               # début du commentaire
               regexp -indices "#" $categorieComment diez
               # prochaine fin de ligne
               regexp -indices "\n" $categorieComment eol
               # On rajoute le commentaire dans dop
               set arg [string range $categorieComment \
                                     [expr [lindex $diez 1]+1] \
                                     [lindex $match 0]]
               set com [string range $categorieComment [lindex $match 1] \
                                                     [expr [lindex $eol 0]-1]]
               puts $dop "        <LI><I><B>$arg</I></B> $com<BR>"
               set categorieComment [string range $categorieComment \
                                                 [expr [lindex $eol 1]+1] end]
               # On insère les commentaires jusqu'au prochain argument
               if [regexp -indices "$s+-$s+" \
                           $categorieComment match] {
                    set last# [string last # [string range $categorieComment \
                                                 0 [lindex $match 0]]]
                    addLine $dop [string range $categorieComment \
                                                 0 [lindex $match 0]]
                    set categorieComment [string range $categorieComment \
                                                 ${last#} end]
               } else {
                    addLine $dop $categorieComment
               } ; # end if
            } ; # end while

            puts $dop "</OL>"
        }
        default    {
            # On stocke les commentaires concernant la procédure 
            # dans le fichier dop
            addLine $dop $categorieComment
        }
    } ; # end switch
} ; # end proc insereInfo

########################################################################
# parseTCLFile -- Parse un fichier TCL, pour en extraire les commentaires
# Procédure permettant de parser un fichier Tcl, pour en extraire des
# données HTML en vue de générer une documentation automatique.
# Arguments:
#  fileName - Nom du fichier HTML à parser
# Effets de bord:
# Crée 2 fichier temporaire dans le repertoire temporaire pointé par
# <I>pistMkDoc(tmpDir)</I>
# Calls:
#  insereInfo
# Outputs:
#  remplit les fichiers dont les noms sont contenus dans les variables : <I>
#  pistMkDoc(ldop)</I> et <I>pistMkDoc(lof)</I>
# Returns:
########################################################################
proc parseTCLFile {fileName} {
    global pistMkDoc
    set s "\[ \t\]"
    incr pistMkDoc(fileCounter)
    # list of proc
    file delete [file join $pistMkDoc(tmpDir) lop.tmp]
    # description of each procedure
    file delete [file join $pistMkDoc(tmpDir) dop.tmp]
    
    set lop [open [file join $pistMkDoc(tmpDir) lop.tmp] w+]
    set dop [open [file join $pistMkDoc(tmpDir) dop.tmp] w+]
    
    if [file exists $fileName] {
        set tmp [open $fileName r]
        set txt [read $tmp]
        close $tmp
    } else {
        return
    }
    puts $pistMkDoc(lof) \
         "  <LI><A HREF=\"#F$pistMkDoc(fileCounter)\">$fileName</A>"
    
    puts $lop "<A NAME=\"#F$pistMkDoc(fileCounter)\">\n<H2>LIST OF PROCS in $fileName</H2>\n</A>\n"
    
    # On cherche les commentaires de debut de fichier et on les ajoute au
    # fichier lop
    # On recupère les lignes de commentaires en tête, on recherche la première
    # ligne qui se trouve avant la première déclaration de procédure
    if {![regexp -indices "\n#$s+(\[^\n#\]+)$s+--$s*(\[^\n\]*)\n"\
                            $txt firstProc]} {
        set firstProc [list end end]
    }
    set commentEnTete [string range $txt 0 [lindex $firstProc 0]]
    set txt [string range $txt [lindex $firstProc 0] end]
    # Si la première ligne du fichier commence par "#!", on passe
    # les 3 premières lignes
    if {[string compare [string range $commentEnTete 0 1] #!] == 0} {
        regexp -indices "\[^\n\]+\n\[^\n\]+\n\[^\n\]+\n" $commentEnTete match
        addLine $lop [string range $commentEnTete [lindex $match 1] end]
    } else {
        addLine $lop [string range $commentEnTete 0 end]
    }
    puts $lop "<OL>" 
    
    # Pour chaque procédure du fichier
    # On cherche le premier commentaire du style :
    #          "# procName -- Line of info " 
    #          ou "# procName --Line of info" en début de ligne
    while {[regexp -indices "\n#$s+(\[^\n#\]+)$s+--$s*(\[^\n\]*)\n"\
                            $txt match procNamei shortProcInfoi]} {
        set procName [string range $txt [lindex $procNamei 0] \
                                        [lindex $procNamei 1]]
        set shortProcInfo [string range $txt [lindex $shortProcInfoi 0] \
                                        [lindex $shortProcInfoi 1]]
        set txt [string range $txt [lindex $procNamei 1] end]
        incr pistMkDoc(procCounter)
        # On rajoute le nom de la procedure dans lop et dop
        puts $lop "    <LI><A HREF=\"#P$pistMkDoc(procCounter)\">$procName</A> $shortProcInfo"
        puts $dop "    <LI><A NAME=\"#P$pistMkDoc(procCounter)\"><H3>$procName</H3></A><p>\n$shortProcInfo<p>"
        # On cherche les informations sur la procédure, pour cela on cherche la
        # chaîne "proc $procName" en début de ligne qui indique la fin 
        # des commentaires associés à la procédure
        regexp -indices "proc $procName" $txt match
        set procComment [string range $txt 0 [lindex $match 0]]
        # "txt" contient le reste du fichier à parser
        set txt [string range $txt [lindex $match 1] end]
        # On range les commentaires concernant la procédure dans la variable
        # "comment"
        if [regexp -indices "#$s+(\[^:\n\]+):$s*\n" $procComment match indice] {
            set comment [string range $procComment 0 [lindex $indice 0]]
            set procComment [string range $procComment [lindex $match 0] end]
            set avecArguments 0
        } else {
            # Il n'y a pas d'info du stryle "# Arguments:"
            set comment $procComment
            set avecArguments 1
        }
        # On stocke les commentaires concernant la procédure dans le fichier dop
        addLine $dop $comment
        # On recupére les informations du style "# Arguments:" si il y en a
        if {!$avecArguments} {
           puts $dop "<OL>"
           while {[regexp -indices "#$s+(\[^:\n\]+):$s*\n" $procComment \
                                   match line]} {
               set categorie [string range $procComment [lindex $line 0]\
                                                [lindex $line 1]]
               set procComment [string range $procComment [lindex $match 1] end]
               # On recupere l'info "# Arguments:" suivante
               if {[regexp -indices "#$s+(\[^:\n\]+):$s*\n" \
                           $procComment match line]} {
                   set categorieComment [string range $procComment 1 \
                                                  [expr [lindex $match 0]-1]]
               } else  {
                   # Il n'y a plus d'autre info "# Arguments:"
                   set categorieComment [string range $procComment 1 end]
               }
               insereInfo $dop $categorie $categorieComment
           }
           puts $dop "</OL>"
        }
        puts $dop "<P>\n<HR WIDTH=\"50%\">"
    }
    
    # On sauvegarde les informations collectées dans le fichier ldop
    puts $lop "</OL>\n<OL>"
    puts $dop "</OL>\n<P>\n<HR SIZE=5 WIDTH=\"100%\">\n"
    seek $lop 0 start
    seek $dop 0 start
    set txt [read $lop]
    puts $pistMkDoc(ldop) $txt
    close $lop
    set txt [read $dop]
    puts $pistMkDoc(ldop) $txt
    close $dop
    file delete [file join $pistMkDoc(tmpDir) lop.tmp]
    file delete [file join $pistMkDoc(tmpDir) dop.tmp]
} ; # end proc parseTCLFile

########################################################################
# pistMkDoc -- Permet de tester les arguments passes au package pistMkDoc
# Arguments:
#  -files "Liste de fichier" - Specifier une liste de fichier+un pattern
#   Permet de specifier une liste de fichier+un pattern<BR>
#   <B>Exemple :</B> "-files ./*.tcl ./*.tk"
#  -f a - force l'effacement des fichiers
#  -out FileName - Nom du fichier HTML de sortie
#  -tmp Directory - Emplacement des fichiers temporaires
#   Si cette option n'est pas précisée, les fichiers temporaires seront
#   placés dans les répertoire courant, ou bien dans le même répretoire
#   que le fichier HTML de sortie si l'option -out est précisée.
#  -h - Affiche l'aide concernant l'utilisation de pistMkDoc
# Effets de bord:
#  remplit le tableau global "pistMkDoc" avec les paramètres passés 
#  au programme
# Calls:
#  pistMkDocInit, recursive_glob, showHelp, parseTCLFile, pistMkDocClose.
# Outputs:
#  
# Returns:
########################################################################
proc pistMkDoc {} {
    global argc argv pistMkDoc
    
    if {$argc < 2} {
        showHelp
        exit 1
    }
    
    set pistMkDoc(deleteExistingFile) 0
    set pistMkDoc(listOfPattern) ""
    set pistMkDoc(outputFile) a.html
    set pistMkDoc(tmpDir) ""
    while {[string match -* $argv]} {
       switch -- [lindex $argv 0] {
          --         { 
             set argv [lreplace $argv 0 1]
             break
          }
          -f {
            set pistMkDoc(deleteExistingFile) 1
            set argv [lreplace $argv 0 0]
          }
          -tmp {
            set pistMkDoc(tmpDir) [lindex $argv 1]
            set argv [lreplace $argv 0 1]
          }
          -o -
          -out {
            set pistMkDoc(outputFile) [lindex $argv 1]
            if {$pistMkDoc(tmpDir) == ""} {
                set pistMkDoc(tmpDir) [file dirname $pistMkDoc(outputFile)]
            }
            set argv [lreplace $argv 0 1]
          }
          -file -
          -files {
            set pistMkDoc(listOfPattern) [lindex $argv 1]
            set argv [lreplace $argv 0 1]
          }
          -h {
              showHelp
              exit 0
          }
          default    { 
              error "unknow option $argv"
              exit 1
          }
       }
    }
    if {$pistMkDoc(listOfPattern) == ""} {
        error "You must specifie a \"-files\" option"
    }
    if {$pistMkDoc(tmpDir) == ""} {
        set pistMkDoc(tmpDir) [pwd]
    }
    
    pistMkDocInit
    
    # listOfFile contiendra la liste des fichiers dont on veut générer la
    # documentation
    set listOfFile {}
    
    foreach pattern $pistMkDoc(listOfPattern) {
        set pistMkDoc(listOfFile) [concat $listOfFile \
                               [recursive_glob [file dirname $pattern] \
                                               [file tail $pattern]]]
    }
    if {![lempty $pistMkDoc(listOfFile)]} {
        set pistMkDoc(listOfFile) [lsort $pistMkDoc(listOfFile)]
        foreach file $pistMkDoc(listOfFile) {
            puts "PARSING Tcl file : $file"
            parseTCLFile $file
        }
        pistMkDocClose
    } else {
        puts "No file generated ! Can't find matching file in \"$pistMkDoc(listOfPattern)\""
    }
    exit 0
} ; # endproc pistMkDoc

pistMkDoc