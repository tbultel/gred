

package provide xtcl 0.1


########################################################################
# procedure report 
#   syntaxe : report ?options? ?--? args
#   affiche le reste des arguments, suivi �ventuellement d'informations 
#   sur le niveau d'appel de cette proc�dure.
#   Peut utiliser un tableau global report() pour m�moris�s des parametres.
#   Utilise la variable globale report(verboseLevel) 
#     1 = valeur par d�faut (�quivaut � puts stderr), 
#     0 = silence, 2 = plus d'info, 3 � 5 pour debuggage)
#   le tableau report() pourra �tre utilis� pour m�moris�s des parametres.
#     (fichier de log, ...)
# 
#   Options possibles :
#     -0 � -5 : le message n'est affich� que si ce parametre 
#        est sup�rieur ou �gal � la globale report(verboseLevel).
#        Si la globale report(verboseLevel) n'existe pas, alors le message est 
#        toujours affich�.
#     -l 0 � -l 5 : modifie la globale report(verboseLevel) � cette valeur de L
#        (cette option est � utiliser seule)
#     -v : alors ce qui suit est consid�r� comme une suite de variable, et
#        le message � afficher est une suite de lignes (VARIABLE)
#            variable = "valeur1"
#     -t : ins�re en premier le groupe date/heure "01/09/95 08h37m50s : "
#     -f : affectuer un flush du fichier (pour assurer l'�criture imm�diate)
#     -c : affiche le contexte : proc�dures appelantes (invalide
#        par d�faut) (CONTEXTE)
#     -nn : ne pas rajouter de <return> final (LASTRETURN),
#     -- : indique la fin des options.
# 
#   exemple :
#      report -3 -v TOTO     affiche (si report(verboseLevel)>=3):  
#            TOTO = "toto_value"
#      report bonjour        affiche :  "bonjour"
# 
#   A faire : option -log ou -f : ecriture dans un fichier log
#             cr�er proc report:init pour valeur des options, nom du fichier
#             log, ... ces globales sont m�moris�es dans le tableau report()
#   maj : 04/06/97 : Les variables pass�es par -v peuvent �tre des tableaux 
#                    (utilise array exists => >= tcl7.6). 
#   maj : 19/07/96 : option -t utilisation de clock (>= tcl7.5)
#   maj : 11/09/95 : option -f ; flush
#   maj : 08/09/95 : option -l pour changer le niveau d;info en interactif
#   maj : 05/09/95 : option -t ; stderr au lieu de stdout
########################################################################
proc report {args} {
  
    # Si la globale report(verboseLevel) n'existe : on la cr�e � 1.
    global report
    if {![info exists report(verboseLevel)]} {set report(verboseLevel) 1}
    
    # Si commande du style "report -l 3"  on traite et on retourne
    if [string match -l [lindex $args 0]] {
        set NewLevel [lindex $args 1]
        
        # On s'assure de la validit� de report(verboseLevel) :
        if ![string match {[0-5]} $NewLevel] {
            puts stderr "Niveau d'information incorrect "\
                             : doit etre comprise entre 0 et 5"
            puts stderr "\$report(verboseLevel) maintenu �\
                                                $report(verboseLevel)"
        }
        set report(verboseLevel) $NewLevel
        return
    }
    # On s'assure de la validit� de report(verboseLevel) :
    if ![string match {[0-5]} $report(verboseLevel)] {
        puts stderr "\$report(verboseLevel) = \"$report(verboseLevel)\"\
                    : doit etre comprise entre 0 et 5"
        puts stderr "\$report(verboseLevel) forc� � \"1\""
        set report(verboseLevel) 1
    }
    if $report(verboseLevel)==0 return

    ####################################################################
    # Exctraction des parametres :
    
    # Valeurs par d�faut des parametres :
    set LEVEL     0
    set VARIABLE  0
    set CONTEXTE  0
    set TIME      0
    set FLUSH      0
    set LASTRETURN \n
    while 1 {
        set arg1 [lindex $args 0]
        if {$arg1 == "--"} break
        if [string match -\[0-5\] $arg1] {
            set LEVEL [expr -1*$arg1]
            set args [lreplace $args 0 0 ]
            # on abondonne si report(verboseLevel) n'est pas suffisent
            if {$LEVEL > $report(verboseLevel)} {return}
            continue
        }
        if [string match -c $arg1] {
            set CONTEXTE 1
            set args [lreplace $args 0 0 ]
            continue
        }
        if [string match -v $arg1] {
            set VARIABLE 1
            set args [lreplace $args 0 0 ]
            continue
        }
        if [string match -nn $arg1] {
            set LASTRETURN ""
            set args [lreplace $args 0 0 ]
            continue
        }
        if [string match -t $arg1] {
            set TIME 1
            set args [lreplace $args 0 0 ]
            continue
        }
        if [string match -f $arg1] {
            set FLUSH 1
            set args [lreplace $args 0 0 ]
            continue
        }
        break  ;# il n'y a plus d'option parmi les arguments.
    } ;# endwhile

    # construction du message proprememet dit :
    set txt ""
    if {$VARIABLE} {
    
        # on va construire les lignes <variable="valeur">
        foreach varname $args {
            upvar $varname var
            if {![info exists var]} {
                append txt "\n    la variable \"$varname\" n'existe pas..."
            } elseif {[array exists var]} {
                # C'est un tableau
                set keys [lsort [array names var]]
                foreach key $keys {
                   append txt "\n    ${varname}($key) = \"$var($key)\""
                }
            } else {
                # C'est une variable simple
                append txt "\n    $varname = \"$var\""
            }
        } ;# endforeach
        # On vire le premier <return> :
        set txt [string trimleft $txt \n]
        
    } else {
    
        # join permet d'afficher une chaine plutot qu'une liste
        set txt "[join $args]"
    }
    

    # On rajoute au message la date si option -t
    if {$TIME} {
        set txt "[clock format [clock seconds] \
               -format {%d/%m/%y-%Hh%Mmn%Ss}] : $txt"
#         set txt "[exec date "+%d/%m/%y %Hh%Mm%Ss"] : $txt"
    }
    
    # On rajoute au message les infos sur le niveau appelant (contexte)
    if {$CONTEXTE} {
        set level [expr [info level] - 1]
        switch -exact -- $level {
            0 {
                append txt "\n    depuis le top level."
            }
            1 {
                append txt "\n    depuis \"[info level -1]\""
            }
            2 {
                append txt "\n    depuis      \"[info level -1]\""
                append txt "\n    appel�e par \"[info level -2]\""
            }
            default {
                append txt "\n    depuis      \"[info level -1]\""
                append txt "\n    appel�e par \"[info level -2]\""
                append txt "\n    appel�e par \"[info level -3]\""
            }
        }
    }
    
    puts -nonewline stderr $txt$LASTRETURN
    if $FLUSH {flush stderr}
} ;# endproc report

