package provide shell 0.1

# mkindexUsage -- retourne aide de la commande mkindex
# 
# à mettre a jour par copie-colle de la doc de mkindex
# 
proc mkindexUsage {} {
    set txt [subst {
    mkindex ?options? args

# mkindex -- updates pkgIndex.tcl or tclIndex in directories 
# 
# parametres:
#  -tclindex = -idx : generate tclIndex files instead of pkg_index files
#  -p = -pat : list of pattern 
#    defaults to :
#         *.tcl    *[info sharedlibextension] 
#         */*.tcl   */*[info sharedlibextension]
#  -f : boolean force to rebuild index (even if it is up to date)
#  -h ou -help  : puts the help message
#  args: - directories to autoindex (defaults to pwd)
# 
# used external procedures : 
#   - none.
# 
# Outputs: 
#   - pkgIndex.tcl or tclIndex file to each directory
#   - there is some "puts..." commands
# 
# description :
# 
# Creates the pkgIndex.tcl or tclIndex file in each of the directories 
# but not if the index is up to date.
# An index is "up to date" iff :
#   - index exist,
#   - TCL file list is not empty,
#   - index is more recent than the directory containing it,
#   - index is **stricly** more recent than each file.
# If no TCL files are present in a directory to scan, any existing 
# index files is deleted
# 
# The default pattern is "*.tcl" and "*/*.tcl" so that it allows to create a
# global index in a top library from all sub-libraries.
# 
# principe :
# 
#   commande TCL de base pour la mise à jour de l'index des package :
#      pkg_mkIndex . *.tcl *.tk
#      pkg_mkIndex . */*.tcl */*.tk
#   commande TCL de base pour la mise à jour d'un fichier d'index :
#      auto_mkindex . *.tcl *.tk
#   Create the tclIndex file from dir parameter1 and patterns parameters2, ..
# 
# samples:
# 
#   mkindex
#     generate pkgIndex.tcl in current directory from all tcl file in 
#     this directory or its sub-directories
#   mkindex  . *
#     generate pkgIndex.tcl in current and all first-level subdirectories
#   mkindex -tclindex -p {* .*} ../lib/*
#     generate tclIndex with all files in subdirectories of ../lib
#     (thanks to the -p pattern)
#   mkindex ~diam/local/lib/pist ~diam/local/lib/pist/* 
#     generate pkgIndex.tcl files in top-lib and in all sub-libs from
#     pist library.
# 
# bug: 
#  - forcer la création de l'index si répertoire plus récent
#    que l'index (car plus a jour si on a supprimer un fichier TCL 
# 
# to do: 
# rajouter des options (mais creuser la cohérence avant !)
#  -v : verbose (option déja créée mais non utilisée...) 
#  -r ou -recursive : recursif (le fichier tclindex etant 
#       creer seulemenet dans le top répertoire)
#  -topDir : permet de specifier l'unique répertoire ou l'index doit etre 
#       créé 
# 
# modif :
#  05/06/97 (diam) 
#   modif displayed messages 
#  02/01/96 (diam)
#   generate pkgIndex.tcl instead of tclIndex 
#


    }]
}


proc mkindex args {

  set PATTERNS {}
  set INDEXTYPE        pkgIndex.tcl
  set OTHERINDEXTYPE   tclIndex
  set FORCE 0
  set VERBOSE 0  ; # VERBOSE n'est pas encore utilisé
  while {[llength $args]} {
      switch -glob -- [lindex $args 0] {
         --         { set args [lreplace $args 0 0] ; break}
         -p         -
         -pat       -
         -pattern   { set PATTERNS   [lindex $args 1 ]
                      set args  [lreplace $args 0 1]
                      continue}
         -idx         -
         -tclindex  { set INDEXTYPE  tclIndex
                      set OTHERINDEXTYPE  pkgIndex.tcl
                      set args  [lreplace $args 0 0]
                      continue}
         -f         -
         -force     { set FORCE  1
                      set args  [lreplace $args 0 0]
                      continue}
         -v         -
         -verbose   { set VERBOSE  1
                      set args  [lreplace $args 0 0]
                      continue}
         -h         -
         -help      { puts [mkindexUsage]; exit}
         -*         { error "unknow option $arg"}
         default    { break ;# no more options }
      }
  }
  
  
  
  # Default extension depends on the type of index file to generate
  # if [string match {} $PATTERNS] {
  #   if {$INDEXTYPE == "pkgIndex.tcl"} {
  #     set PATTERNS [list *.tcl *.tk *[info sharedlibextension]]
  #   } else {
  #     set PATTERNS [list *.tcl *.tk]
  #   }
  # }
  if [string match {} $PATTERNS] {
    if {$INDEXTYPE == "pkgIndex.tcl"} {
      set PATTERNS [list \
            *.tcl    *[info sharedlibextension]     \
            */*.tcl  */*[info sharedlibextension]   \
      ]
    } else {
      set PATTERNS [list *.tcl */*.tcl]
    }
  }
  
  # args contains the list of directories patterns
  if [string match {} $args] {
    set args [list [pwd]]
  } else {  
    set args [eval glob -nocomplain $args]
  }
  set dirs {}
  foreach fd $args {  
    if {[file isdir $fd] && [file writable $fd]} {
      lappend dirs $fd
    }
  }
  set dirs [lsort $dirs]
  if {![llength $dirs]} {
    error "No writable directory to scan : $args"
  }
  # dirs contains the non empty list of directories to scan
  
  set olddir [pwd]
  
  puts "dirs to process :"
  puts "    [join $dirs \n\ \ \ \ ]"
  puts ""
  
  foreach dir [lsort $dirs] {
    cd $dir
    if [file isfile $OTHERINDEXTYPE] {
       file delete $OTHERINDEXTYPE
       puts "[file tail $dir] : bad index type $OTHERINDEXTYPE removed"
    }
    set files [eval glob -nocomplain  $PATTERNS]
        
    # il faut supprimer "pkgIndex.tcl" de la liste des fichiers TCL a examiner !
    while {[set ndx [lsearch -exact $files $INDEXTYPE]] != -1} {
       set files [lreplace $files $ndx $ndx]
    }
    
    if {![llength $files]} {
       if [file isfile $INDEXTYPE] {
          file delete $INDEXTYPE
          puts "[file tail $dir] : no files found; $INDEXTYPE removed"
       } else {
          
          set str [mkindex:stringFillTo  20  "[file tail $dir] : " ]
          puts "${str} no files found"
       }
       continue
    }
    if {!$FORCE && [mkindexFileIsMoreRecent $INDEXTYPE $files] } {
       set str [mkindex:stringFillTo  20  "[file tail $dir] : " ]
       puts "$str--- $INDEXTYPE already up to date."
       continue
    }
    puts -nonewline "[file tail $dir] : creating $INDEXTYPE... "
    flush stdout
    switch $INDEXTYPE {
      pkgIndex.tcl {  
        set cmd "[list pkg_mkIndex $dir] $PATTERNS"
      }
      tclIndex {
        set cmd "[list auto_mkindex $dir] $PATTERNS"
      }
    }
    
    if {[catch {eval $cmd} msg]} {
        puts \n$msg
    } else {
        puts "done."
    }
    cd $olddir
  } ;# foreach
  cd $olddir
}

########################################################################
# mkindexFileIsMoreRecent --
#    return 1 si un fichier est strictement plus récent que d'autres
# 
# param 
#   fileRef : nom du fichier a tester 
#   files : liste de fichiers à comparer
# 
# sortie :
#   retourne 1 si l'ensemble de ces conditions est satisfait :
#        - fileRef existe,
#        - la liste des fichiers à comparer est non vide,
#        - fileRef est strictement plus récent que chaque fichiers
# 
# exemple :
#   if [mkindexFileIsMoreRecent $index [glob *.tcl]] {..}
# 
# Cette procédure est également disponible dans le package file.
# 
proc mkindexFileIsMoreRecent {fileRef files} {
  if {![file isfile $fileRef] || ![llength $files]} {
    return 0
  }
  set moreRecent 1
  foreach file $files {
      if {[file mtime $fileRef] < [file mtime $file]} {
        set moreRecent 0
        break
      }
  } ;# endforeach
  return $moreRecent
}


## mkindex:stringFillTo -- complete une chaine jusqu'à une taille donnée
# 
# PROCEDURE ORIGINALE de pist : string_FillTo
# 
# parametres
# 
# N :       taille finale de la chaine
# str :     chaine à compléter
# fillCar : caractère de remplissage
# 
# sortie : retourne une chaine complété
# 
proc mkindex:stringFillTo {N str {fillCar -}} {
    
          while {[string length $str] < $N} {
              append str $fillCar
          } ;# endwhile
          return $str
} ;# endproc mkindex:stringFillTo
