package provide shell 0.1


########################################################################
# shell:edit -- 
# 
# 
# Lance stead en forçant l'option "-cdf <dir>" qui  permet
# se se positionner dans le répertoire du fichier édité.
# Ceci permet de rester dans le répertoire si l'on souhaite ouvrir
# un autre fichier depuis l'éditeur.
# 
# Les autres options des la procédure sont retransmis à l'éditeur.
# 
# Utilise la variable d'environement EDITOR
# 
# Exemple : shell:edit ~/doc/unix/exemple/exemple1.txt
# 
# modif :
#   09/09/99 (diam) : création.
#   22/11/99 (diam) : transmission de l'ensemble des parametres.
# 
proc shell:edit {args} {
    
    global env
    if ![info exist env(EDITOR)] {set env(EDITOR) stead}
    
    set dir [file dirname [lindex $args 0]]
    
    # exec /bin/sh -c "cd $dir\;  xterm -e vi $args " & 

    eval {exec /bin/sh -c "cd $dir\;  $env(EDITOR) $args " &  }

}

