package provide shell 0.1


########################################################################
# shell:edit -- 
# 
# 
# Lance stead en for�ant l'option "-cdf <dir>" qui  permet
# se se positionner dans le r�pertoire du fichier �dit�.
# Ceci permet de rester dans le r�pertoire si l'on souhaite ouvrir
# un autre fichier depuis l'�diteur.
# 
# Les autres options des la proc�dure sont retransmis � l'�diteur.
# 
# Utilise la variable d'environement EDITOR
# 
# Exemple : shell:edit ~/doc/unix/exemple/exemple1.txt
# 
# modif :
#   09/09/99 (diam) : cr�ation.
#   22/11/99 (diam) : transmission de l'ensemble des parametres.
# 
proc shell:edit {args} {
    
    global env
    if ![info exist env(EDITOR)] {set env(EDITOR) stead}
    
    set dir [file dirname [lindex $args 0]]
    
    # exec /bin/sh -c "cd $dir\;  xterm -e vi $args " & 

    eval {exec /bin/sh -c "cd $dir\;  $env(EDITOR) $args " &  }

}

