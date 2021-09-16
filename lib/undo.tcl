########################################################################
# Package gérant le undo 
# le 14 Feb 1997 par CARQUEIJAL David : Création du fichier grundo.tcl
########################################################################

########################################################################
# undo_init -- Procédure (re)initialisant une pile d'undo
# Procédure permettant d'initialiser une pile de undo. On doir passer
# à la procédure un identificateur qui permettra reconnaître de façon
# unique chaque pile. 
########################################################################
proc undo_init {undoUid} {
    upvar #0 undo$undoUid undo
    
    if [info exists undo] {
        unset undo
    }
    
    set undo(recordInfo) 0
    set undo(mark) 0

    set undo(uid) 0
    set undo(reference) 0
    return $undoUid
}

########################################################################
# undo_referenceSet -- Permet de poser l'état de la pile comme référence
# Permet de poser l'état de la pile comme référence. Cela est utile
# pour gérer les sauvegardes. Par exemple lors de la sauvegarde, on
# indique au package undo que la référence est l'état courant. 
########################################################################
proc undo_referenceSet {undoUid} {
    upvar #0 undo$undoUid undo
    set undo(reference) $undo(uid)
}
########################################################################
# undo_isReference -- Renvoie 1 si l'état courant est la référence
# Permet d'interroger le package undo pour savoir si la pile identifier
# par l'identificateur undoUid est dans un état déclarée comme référence
# par la commande <I>undo_referenceSet</I>.
########################################################################
proc undo_isReference {undoUid} {
    upvar #0 undo$undoUid undo
    return [expr $undo(reference) == $undo(uid)]
}

########################################################################
# undo_mark -- Indique le début du groupement de commande
# Toutes les commandes qui seront mémorisées à l'aide de la procédure
# <I>undo_saveInfos</I> entre un <I>undo_mark</I> et un <I>undo_unMark</I> 
# seront ré-exécutées ensemble lors d'un undo/redo.
########################################################################
proc undo_mark {undoUid} {
    upvar #0 undo$undoUid undo
    set undo(mark) 1
    
    if [info exists undo(redo,$undo(uid))] {
        unset undo(redo,$undo(uid))
    }
    if [info exists undo(undo,[expr $undo(uid)+1])] {
        unset undo(undo,[expr $undo(uid)+1])
    }
}

########################################################################
# undo_unMark -- Indique la fin du groupement de commande
# Toutes les commandes qui seront mémorisées à l'aide de la procédure
# <I>undo_saveInfos</I> entre un <I>undo_mark</I> et un <I>undo_unMark</I> 
# seront ré-exécutées ensemble lors d'un undo/redo.
########################################################################
proc undo_unMark {undoUid} {
    upvar #0 undo$undoUid undo
    
    if {$undo(mark)} {
        incr undo(uid)
        set undo(mark) 0
        # On efface les infos au dessus dans la pile
        undoCleanPile $undoUid
    }
#     undoPutsRedoInfo $undoUid
#     undoPutsUndoInfo $undoUid
}

########################################################################
# undo_notSave -- Empéche la sauvegarde de commande dans la pile
# Parfois il est utile de ne pas sauvegarder de commandes dans la
# pile. C'est possible grâce à cette procédure. La sauvegarde de
# commandes par la procédure <I>undo_saveInfos</I> devient inopérante à
# la suite d'un <I>undo_notSave</I>.
########################################################################
proc undo_notSave {undoUid} {
    upvar #0 undo$undoUid undo
    
    set undo(recordInfo) 0
}

########################################################################
# undo_Save -- Réautorise la sauvegarde de commande dans la pile
# Parfois il est utile de réactivé la sauvegarde de commandes dans la
# pile. C'est possible grâce à cette procédure. La sauvegarde de
# commandes par la procédure <I>undo_saveInfos</I> redevient active.
########################################################################
proc undo_Save {undoUid} {
    upvar #0 undo$undoUid undo
    
    set undo(recordInfo) 1
}

proc undoCleanPile {undoUid} {
    upvar #0 undo$undoUid undo
    
    set i [expr $undo(uid)+1]
    while {[info exists undo(undo,$i)]} {
        unset undo(undo,$i)
        incr i
    }
    set i $undo(uid)
    while {[info exists undo(redo,$i)]} {
        unset undo(redo,$i)
        incr i
    }
}

########################################################################
# undo_saveInfos -- Permet de sauvegarder des commandes dans la pile des undos
# Permet de sauvegarder une commande pour le undo et une autre pour le redo.
########################################################################
proc undo_saveInfos {undoUid undoI redoI} {
    upvar #0 undo$undoUid undo

    if [set undo(recordInfo)] {
        if [set undo(mark)] {
            # Sauvegarde de multiple commande : Il faut prendre garde des 
            # précautions :
            # On empile les commandes dans l'ordre de création pour le redo
            # On empile les commandes dans l'ordre inverse de leur création
            # pour le undo (logique !)
            if ![info exists undo(redo,$undo(uid))] {
                set undo(redo,$undo(uid)) "$redoI ;"
                set undo(undo,[expr $undo(uid)+1]) "; $undoI"
            } else {
                set undo(redo,$undo(uid)) "$undo(redo,$undo(uid)) $redoI ;"
                set undo(undo,[expr $undo(uid)+1]) \
                                     "; $undoI $undo(undo,[expr $undo(uid)+1])"
            }
        } else {
            # Pas de sauvegarde de multiple commande, cas facile !
            set undo(redo,$undo(uid)) $redoI
            set undo(undo,[incr undo(uid)]) $undoI
            # On efface les infos au dessus dans la pile
            undoCleanPile $undoUid
            
#             undoPutsRedoInfo $undoUid
#             undoPutsUndoInfo $undoUid
        }
    }
}

########################################################################
# undo_undo -- Excécute une commande de undo
# Excécute le undo courant, ie celui pointé par undo$undoUid(uid)
########################################################################
proc undo_undo {undoUid} {
    upvar #0 undo$undoUid undo
    
    if {$undo(uid) <= 0} {
      gred:status $undoUid "Sorry, no undo informations available !"
      return
    } else {
        gred:status $undoUid "Undoing level $undo(uid)."
        
        set undo(recordInfo) 0
        uplevel #0 $undo(undo,$undo(uid))
        set undo(recordInfo) 1
        incr undo(uid) -1
        Sel:clear [gred:windowToCanvas $undoUid]
        update idletasks
    }
}

########################################################################
# undo_redo -- Excécute une commande de redo
# Excécute le redo courant, ie celui pointé par undo$undoUid(uid)+1
########################################################################
proc undo_redo {undoUid} {
    upvar #0 undo$undoUid undo
    
    if {![info exists undo(redo,$undo(uid))]} {
      gred:status $undoUid "Sorry, no redo informations available !"
      return
    } else {
        gred:status $undoUid "Redoing level [expr $undo(uid)+1]."
        
        set undo(recordInfo) 0
        uplevel #0 $undo(redo,$undo(uid))
        incr undo(uid)
        set undo(recordInfo) 1
        Sel:clear [gred:windowToCanvas $undoUid]
        update idletasks
    }
}

proc undoPutsRedoInfo {undoUid} {
    upvar #0 undo$undoUid undo
    puts $undo(uid)
    set i 0
    while {[info exists undo(redo,$i)]} {
        puts "redo($i) == $undo(redo,$i)"
        incr i
    }
    puts "-----------------------------------------------"
}

proc undoPutsUndoInfo {undoUid} {
    upvar #0 undo$undoUid undo
    set i 1
    while {[info exists undo(undo,$i)]} {
        puts "undo($i) == $undo(undo,$i)"
        incr i
    }
    puts "-----------------------------------------------"
}