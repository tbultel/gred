# fichier grhelp.tcl

#

########################################################################
# tkAboutDialog --
# Affiche des informations sur <B>gred</B>... A FAIRE :-) ...
# 
proc tkAboutDialog {} {
  global gred
}


########################################################################
# gred:helpInit --
# Initialise l'aide en créant un browser capable de charger des fichiers
# HTML et HTCL (issue de la compilation de fichiers HTML.
proc gred:helpInit {} {
    global gred
    
    set docDirectory [file join $gred(setup) doc]
    # On déclare la liste des fichiers HTML à afficher.
    set topics { 
         index.html 
         docMaintenance.html 
    }
    set topic [lindex $topics 0]
    
    hView_Box .help \
        -topics $topics\
        -helpdir $docDirectory\
        -cacheDir [file join $docDirectory CACHE]\
        -tmpFile [file join $docDirectory TMP]\
        -feedBar off
    
    .help follow_link $topic
}

# gred:helpShow --
# Affiche l'aide. Dé-iconifie l'aide si elle est déjà affiché, l'ouvre
# réellement sinon...
proc gred:helpShow {file} {
    if ![winfo exists .help] {
        gred:helpInit
    } else {
         wm deiconify .help
        raise .help
    }
    .help follow_link $file
}
########################################################################
