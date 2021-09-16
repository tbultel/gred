

package provide xtcl 0.1


########################################################################
# procedure report 
#   syntaxe : report ?options? ?--? args
#   affiche le reste des arguments, suivi éventuellement d'informations 
#   sur le niveau d'appel de cette procédure.
#   Peut utiliser un tableau global report() pour mémorisés des parametres.
#   Utilise la variable globale report(verboseLevel) 
#     1 = valeur par défaut (équivaut à puts stderr), 
#     0 = silence, 2 = plus d'info, 3 à 5 pour debuggage)
#   le tableau report() pourra être utilisé pour mémorisés des parametres.
#     (fichier de log, ...)
# 
#   Options possibles :
#     -0 à -5 : le message n'est affiché que si ce parametre 
#        est supérieur ou égal à la globale report(verboseLevel).
#        Si la globale report(verboseLevel) n'existe pas, alors le message est 
#        toujours affiché.
#     -l 0 à -l 5 : modifie la globale report(verboseLevel) à cette valeur de L
#        (cette option est à utiliser seule)
#     -v : alors ce qui suit est considéré comme une suite de variable, et
#        le message à afficher est une suite de lignes (VARIABLE)
#            variable = "valeur1"
#     -t : insère en premier le groupe date/heure "01/09/95 08h37m50s : "
#     -f : affectuer un flush du fichier (pour assurer l'écriture immédiate)
#     -c : affiche le contexte : procédures appelantes (invalide
#        par défaut) (CONTEXTE)
#     -nn : ne pas rajouter de <return> final (LASTRETURN),
#     -- : indique la fin des options.
# 
#   exemple :
#      report -3 -v TOTO     affiche (si report(verboseLevel)>=3):  
#            TOTO = "toto_value"
#      report bonjour        affiche :  "bonjour"
# 
#   A faire : option -log ou -f : ecriture dans un fichier log
#             créer proc report:init pour valeur des options, nom du fichier
#             log, ... ces globales sont mémorisées dans le tableau report()
#   maj : 04/06/97 : Les variables passées par -v peuvent être des tableaux 
#                    (utilise array exists => >= tcl7.6). 
#   maj : 19/07/96 : option -t utilisation de clock (>= tcl7.5)
#   maj : 11/09/95 : option -f ; flush
#   maj : 08/09/95 : option -l pour changer le niveau d;info en interactif
#   maj : 05/09/95 : option -t ; stderr au lieu de stdout
########################################################################
proc report {args} {
  
    # Si la globale report(verboseLevel) n'existe : on la crée à 1.
    global report
    if {![info exists report(verboseLevel)]} {set report(verboseLevel) 1}
    
    # Si commande du style "report -l 3"  on traite et on retourne
    if [string match -l [lindex $args 0]] {
        set NewLevel [lindex $args 1]
        
        # On s'assure de la validité de report(verboseLevel) :
        if ![string match {[0-5]} $NewLevel] {
            puts stderr "Niveau d'information incorrect "\
                             : doit etre comprise entre 0 et 5"
            puts stderr "\$report(verboseLevel) maintenu à\
                                                $report(verboseLevel)"
        }
        set report(verboseLevel) $NewLevel
        return
    }
    # On s'assure de la validité de report(verboseLevel) :
    if ![string match {[0-5]} $report(verboseLevel)] {
        puts stderr "\$report(verboseLevel) = \"$report(verboseLevel)\"\
                    : doit etre comprise entre 0 et 5"
        puts stderr "\$report(verboseLevel) forcé à \"1\""
        set report(verboseLevel) 1
    }
    if $report(verboseLevel)==0 return

    ####################################################################
    # Exctraction des parametres :
    
    # Valeurs par défaut des parametres :
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
                append txt "\n    appelée par \"[info level -2]\""
            }
            default {
                append txt "\n    depuis      \"[info level -1]\""
                append txt "\n    appelée par \"[info level -2]\""
                append txt "\n    appelée par \"[info level -3]\""
            }
        }
    }
    
    puts -nonewline stderr $txt$LASTRETURN
    if $FLUSH {flush stderr}
} ;# endproc report

