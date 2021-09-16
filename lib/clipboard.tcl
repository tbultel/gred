########################################################################
# programmes et procédures de traitement du presse papier<BR>
# nom du programme : grclipboard.tcl<BR>
# crée le 11/10/96 par commeau@ensta.fr<BR>
# MOFICICATIONS:
# le 10 Feb 1997 par CARQUEIJAL David : Rajout d'un tableau graphPP
#  contenant le clipboard (ie le grafcet obtenu après &lt;&lt;Copy&gt;&gt;
#  ou &lt;&lt;Paste&gt;&gt;).<BR>
#  Faut-il séparer Record de Clipboard ? A quoi sert Record ????
########################################################################

########################################################################
# Record:clear --
# 
# RAZ de la variable "record" (objets précédemment crées à partir d'une
# commande "Cut" , "Copy" , ou "Save")
# 
proc Record:clear {c} {
    global graphPP

    set graphPP(record,oids) {}
}

########################################################################
# Record:add -- Ajoute le ou les objets "oids" dans la variable "record"
# 
# 
# 
proc Record:add {oids} {
    global graphPP

    # on suppose que les oids ne sont pas deja presents dans la liste
  
    set graphPP(record,oids) [concat $graphPP(record,oids) $oids]
}

########################################################################
# Record:SelectRecordedOids -- Sélectionne tous les objets de la variable 
# "record"
# 
# 
proc Record:SelectRecordedOids {c} {
    global graphPP

    Sel:clear $c
    Sel:new $c $graphPP(record,oids)
}

########################################################################
# Clipboard:clear -- RAZ de la variable "clipboard"
# 
# 
# 
proc Clipboard:clear {} {
    global graphPP

#     set graphPP(clipboard,commands) {}
    set graphPP(commands) {}
    set graphPP(oids) {}
    set graphPP(canvasSource) {}
}

########################################################################
# Clipboard:add --
# 
# Ajoute les commandes passe en arguments dans la variable "clipboard"
# 
# proc Clipboard:add {c oids} {
#     global graphPP
# 
#     # on suppose que les oids ne sont pas deja presents dans la liste
#   
# #     set graphPP(clipboard,commands) $commands
#     set graphPP(oids) $oids
#     set graphPP(canvasSource) $c
# }


# Clipboard:setCommands --
# Génére des commandes permettant de regénérer une partie de Grafcet à partir
# du contenue du clipboard.
# 
proc Clipboard:setCommands {c objs} {
    global graphPP
    set grafcetSource [gred:getGrafcetName $c]
    return [set graphPP(commands) [Obj:getCommandsForClipboard \
                               [gred:windowToCanvas .$grafcetSource]\
                                 $objs]]
}
########################################################################
# Clipboard:get -- Retourne le contenu du presse papier sous forme de texte
# 
# 
# 
proc Clipboard:get {} {
    global graphPP

    return $graphPP(commands)
}
