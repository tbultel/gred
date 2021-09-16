package provide file 0.1

# File_IsMoreRecent --
#    return 1 si un fichier est strictement plus récent que d'autres
# 
# param :
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
#   if [mkindex_File_IsMoreRecent $index [glob *.tcl]] {..}
# 
# a faire : une procedure du package File (quand elle sear mure !)
# 
proc File_IsMoreRecent {fileRef files} {
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
