# Fichier menu.tcl de gred
# $Id: menu.tcl,v 1.3 1997/10/14 06:42:52 diam Exp $

########################################################################
# gred:mkmenus --
# 
# 
# 
proc gred:mkmenus {{w ".menubar"}} {
global gred
    # definition de la barre de menus liee a l'application
    frame $w.menubar
    
    foreach menu {file edit objects windows config extra help} {
        gred:mkmenu:${menu} $w
    }

    if {$gred(admin)} {gred:mkmenu:admin $w}
    
    # definition des menus "popup" lies a l'application
    # i.e liés à des cliques sur sur des types d'objet (Etapes, 
    # Transitions, ...)
    foreach menu {etape1 trans1 grafcet1} {
        gred:mkpopupmenu:${menu}
    }

    return $w.menubar
    
}

########################################################################
# gred:mkmenu:file --
# 
# InFrame $frame
# 
proc gred:mkmenu:file {w} {
global gred

    set frame $w.menubar

    set name $frame.file
    set menuName $name.menu
    set mb [menubutton $name -text Fichier -menu $menuName]
    pack $mb -side left
    set menu [menu $menuName -tearoff 0]
    
    $menu add command -label "Nouveau grafcet" -command {gred:cmd:new} \
                      -accelerator <$gred(Meta)-n>
    bind $w <$gred(Meta)-n> {gred:cmd:new}
    
    $menu add command -label "Nouveau processus" \
                      -command {gred:cmd:newProcess}
    
    $menu add separator

    # Open
    $menu add command -label "Ouvrir..." \
              -command {gred:file:open [gred:windowToCanvas [gred:cmd:new]]} \
              -accelerator <$gred(Meta)-o>
    bind $w <$gred(Meta)-o> \
              {gred:file:open [gred:windowToCanvas [gred:cmd:new]]}
     
    # load...
    $menu add command -label "Charger..." \
              -command "gred:file:open [gred:windowToCanvas $w]" \
              -accelerator <$gred(Meta)-l>
    bind $w <$gred(Meta)-l> "gred:file:open [gred:windowToCanvas $w]"
    
    $menu add command -label "Réouvrir le même fichier" \
              -command "gred:cmd:reopen [gred:windowToCanvas $w]" \
              -accelerator <$gred(Meta)-O>
    bind $w <$gred(Meta)-O> "gred:cmd:reopen [gred:windowToCanvas $w]"
    
    $menu add command -label "Sauvegarder" \
              -command "gred:file:save [gred:windowToCanvas $w]" \
              -accelerator <$gred(Meta)-s>
    bind $w <$gred(Meta)-s> "gred:file:save [gred:windowToCanvas $w]"
    
    $menu add command -label "Sauvegarder sous..." \
              -command "gred:file:saveas [gred:windowToCanvas $w]" \
              -accelerator <$gred(Meta)-S>
    bind $w <$gred(Meta)-S> "gred:file:saveas [gred:windowToCanvas $w]"
    
    $menu add separator
    
    $menu add command -label "Exporter..." \
              -command {gred:cmd:export} \
              -state disabled
    
    $menu add command -label "Importer..." \
              -command "gred:cmd:import [gred:windowToCanvas $w]"
    
    $menu add separator
    
    $menu add command -label "Imprimer..." \
              -command "gred:cmd:print [gred:windowToCanvas $w]" \
              -accelerator <$gred(Meta)-p>
    bind $w <$gred(Meta)-p> "gred:cmd:print [gred:windowToCanvas $w]"
    
    $menu add separator

    $menu add command -label "Fermer la fenêtre" \
              -command "gred:cmd:close $w" \
              -accelerator <$gred(Meta)-w>
    bind $w <$gred(Meta)-w> "gred:cmd:close $w"
    
    $menu add command -label "Quitter" \
              -command {gred:cmd:quit} \
              -accelerator <$gred(Meta)-q>
    bind $w <$gred(Meta)-q> {gred:cmd:quit}
}

########################################################################
# gred:mkmenu:edit --
# 
# 
# 
proc gred:mkmenu:edit {w} {
global gred

    set frame $w.menubar
    
    set name $frame.edit
    set menuName $name.menu
    set mb [menubutton $name -text Edition -menu $menuName]
    pack $mb -side left
    set menu [menu $menuName -tearoff 0]
    
    $menu add command -label "Undo" -command "gred:cmd:undo $w" \
                      -accelerator <$gred(Meta)-z>
    bind $w <$gred(Meta)-z> "gred:cmd:undo $w"
    
    $menu add command -label "Redo" -command "gred:cmd:redo $w" \
                      -accelerator <$gred(Meta)-Z>
    bind $w <$gred(Meta)-Z> "gred:cmd:redo $w"
    
    $menu add separator

    $menu add command -label "Couper" \
                      -command "gred:cmd:cut [gred:windowToCanvas $w]" \
                      -accelerator <$gred(Meta)-x>
    bind $w <$gred(Meta)-x> "gred:cmd:cut [gred:windowToCanvas $w]"
    
    $menu add command -label "Copier" \
                      -command "gred:cmd:copy [gred:windowToCanvas $w]" \
                      -accelerator <$gred(Meta)-c>
    bind $w <$gred(Meta)-c> "gred:cmd:copy [gred:windowToCanvas $w]"
    
    $menu add command -label "Coller" \
                      -command "gred:cmd:paste [gred:windowToCanvas $w]" \
                      -accelerator <$gred(Meta)-v>
    bind $w <$gred(Meta)-v> "gred:cmd:paste [gred:windowToCanvas $w]"
    
    $menu add separator

    $menu add command -label "Selectionner tous les objets" \
                      -command "gred:cmd:selectAll [gred:windowToCanvas $w]" \
                      -accelerator <$gred(Meta)-a>
    bind $w <$gred(Meta)-a> "gred:cmd:selectAll [gred:windowToCanvas $w]"
    $menu add command -label "Effacer la sélection" \
                      -command "Sel:clear [gred:windowToCanvas $w]" \
                      -accelerator <Escape>
    bind $w <Escape> "Sel:clear [gred:windowToCanvas $w]"
}

########################################################################
# gred:mkmenu:objects --
# 
# 
# 
proc gred:mkmenu:objects {w} {
global gred
    set frame $w.menubar
    set name $frame.object
    set menuName $name.menu
    set mb [menubutton $name -text Objets -menu $menuName]
    pack $mb -side left
    set menu [menu $menuName -tearoff 0]
    $menu add command -label "Find..." \
                      -command "Object:FindFromName [gred:windowToCanvas $w]" \
                      -accelerator <$gred(Meta)-f>
    bind $w <$gred(Meta)-f> "Object:FindFromName [gred:windowToCanvas $w]"
    
    # MenuCommandInFrame $frame  Objects "Add Etape..."      {gred:cmd:addetape}
    # MenuCommandInFrame $frame  Objects "Add Transition..." {gred:cmd:addtrans}
    # MenuCommandInFrame $frame  Objects "Link..."           {gred:cmd:link}
    # MenuBindInFrame $frame $w <$gred(Meta)-e>    Objects "Add Etape..."
    # MenuBindInFrame $frame $w <$gred(Meta)-t>    Objects "Add Transition..."
    # MenuBindInFrame $frame $w <$gred(Meta)-l>    Objects "Link..."
    
}

########################################################################
# gred:mkmenu:windows --
# 
# 
# 
proc gred:mkmenu:windows {w} {
    set frame $w.menubar
    menubutton $frame.win -text {Fenêtres} -menu $frame.win.m
    pack $frame.win -side left
    
    menu $frame.win.m  -postcommand "gred:fillWinMenu $w" -tearoff 0
}

proc gred:fillWinMenu {w} {
global gred
    set frame $w.menubar
    catch {$frame.win.m delete 0 last}
    
    foreach grafcetName $gred(grafcets) {
        upvar #0 grafcet.$grafcetName grafcet
        regexp "^grafcet(\[0-9\]+)$" $grafcetName match Id
        set name "Gred #$Id"
        if {$grafcet(filename) != ""} {
            set name "$name [file tail $grafcet(filename)]"
        } else {
            set name "$name Untitled"
        }
        $frame.win.m add command -label $name \
                                 -command "wm deiconify .$grafcetName ;\
                                           raise .$grafcetName ; \
                                           focus .$grafcetName"
    }
}


########################################################################
# gred:mkmenu:config --
# 
# 
# 
proc gred:mkmenu:config {w} {
global gred
    set frame $w.menubar
    set name $frame.config
    set menuName $name.menu
    set mb [menubutton $name -text Configurer -menu $menuName]
    pack $mb -side left
    set menu [menu $menuName -tearoff 0]
    
    $menu add command -label "Editer les préférences..." -command {Pref_Dialog}
        
    $menu add command -label "Montrer/Cacher la grille" \
                      -command "Grid_ToggleShow [gred:windowToCanvas $w]"
                                            
    $menu add separator
                      
    $menu add command -label "Taille A4v" \
                      -command "gred:setCanvasSize A4v"
                                            
    $menu add command -label "Taille A4h" \
                      -command "gred:setCanvasSize A4h"
                                            
    $menu add command -label "Taille A3v" \
                      -command "gred:setCanvasSize A3v"
                                            
    $menu add command -label "Taille A3h" \
                      -command "gred:setCanvasSize A3h"
                                            
    $menu add command -label "Taille A2v" \
                      -command "gred:setCanvasSize A2v"
                                            
    $menu add command -label "Taille A2h" \
                      -command "gred:setCanvasSize A2h"
                                            
    $menu add command -label "Taille A1v" \
                      -command "gred:setCanvasSize A1v"
                                            
    $menu add command -label "Taille A1h" \
                      -command "gred:setCanvasSize A1h"
                                            

    $menu add separator
                      
    $menu add command -label "Enregister les préférences courantes" \
                      -command "Pref_Save "
}

########################################################################
# gred:mkmenu:extra --
# 
# 
# 
proc gred:mkmenu:extra {w} {
global gred
    set frame $w.menubar
    
    set name $frame.extra
    set menuName $name.menu
    set mb [menubutton $name -text Extra -menu $menuName]
    pack $mb -side left
    set menu [menu $menuName -tearoff 0]
    
    $menu add command -label "Evaluer la selection" -command {gred:evalSel} \
                      -accelerator <$gred(Meta)-L>
    bind $w <$gred(Meta)-L> {gred:evalSel}
    
    # # $menu add command -label "Issue Tcl Command..." \
    # #                   -command {gred:prompt_tcl} \
    # #                   -accelerator <$gred(Meta)-U>
    # # bind $w <$gred(Meta)-U> {gred:prompt_tcl}
    
    $menu add separator

    $menu add command -label "TCL Shell..." \
                      -command {Shell} \
                      -accelerator <$gred(Meta)-y>
    bind $w <$gred(Meta)-y> {Shell .gredconsole}
}

########################################################################
# gred:mkmenu:help --
# 
# 
# 
proc gred:mkmenu:help {w} {
global gred
    set frame $w.menubar

    set name $frame.help
    set menuName $name.menu
    set mb [menubutton $name -text Help -menu $menuName]
    pack $mb -side right
    set menu [menu $menuName -tearoff 0]
    
    $menu add command -label "Reporter un bug / commentaire..."\
                      -command "gred:cmd:mailto $w"
                      
    $menu add separator
    
    # Informations sur la version
    $menu add command -label "Informations sur la version..." \
                      -command {showVersion}                 
    $menu add separator
    
    # La ligne suivante est est mettre au point pour utiliser la future 
    # boite de dialogue standard et multiplateforme de tk :
    $menu add command -label "A propos (index.html)..." \
                      -command {gred:helpShow index.html}
    
        
    $menu add separator
    $menu add command -label "Documentation maintenance" \
                      -command {gred:helpShow docMaintenance.html}
                      
    $menu add separator
    
    # Informations sur la version
    $menu add command -label "Exemple mini..." \
                      -command {gred:new $gred(setup)/exemples/miniExemple.gra}                 
    $menu add command -label "Exemple réel..." \
                      -command {gred:new  $gred(setup)/exemples/realExemple.gra}
}


########################################################################
# gred:mkpopupmenu:etape1 --
# 
# Définition du popup menu associé à l'appui d'un bouton de la souris
# sur une étape
# 
proc gred:mkpopupmenu:etape1 {} {
  global gred
  # On ne cree le menu popup qu'UNE fois...
  if [winfo exists .menupopupEtape] {
     return
  }
  set gred(Etape,popup1) [set menu [menu .menupopupEtape -tearoff 0]]
  # Creation d'un item de menu pour chaque type d'étape :
  # Faire appel à une global du genr gred(Etape,types)
  set i 0
  foreach EtapeType $gred(etape,name) {
     # ATTENTION DAVID : UTILISE "set command [list ...]"
     set command "gred:cmd:changeEtapeType  \
          \[gred:windowToCanvas .\[gred:getGrafcetName \[focus\]\]\]\
          [lindex $gred(etape,type) $i]"
     $menu add command -label "$EtapeType" -command $command
     incr i
  }
  $menu add separator
  $menu add command -label "Changer tous les paramètres..." \
        -command {gred:cmd:changeParamsBox \
         [gred:windowToCanvas .[gred:getGrafcetName [focus]]]}

}

########################################################################
# gred:mkpopupmenu:trans1 --
# 
# Définition du popup menu associé à l'appui d'un bouton de la souris
# sur une transition
# 
proc gred:mkpopupmenu:trans1 {} {
  global gred
  # On ne cree le menu popup qu'UNE fois...
  if [winfo exists .menupopupTrans] {
     return
  }
  set gred(Trans,popup1) [set menu [menu .menupopupTrans -tearoff 0]]
  $menu add command -label "Changer tous les paramètres..." \
        -command {gred:cmd:changeParamsBox\
                 [gred:windowToCanvas .[gred:getGrafcetName [focus]]]}
}

########################################################################
# gred:mkpopupmenu:grafcet1 --
# 
# Définition du popup menu associé à l'appui d'un bouton de la souris
# sur le canvas
# 
proc gred:mkpopupmenu:grafcet1 {} {
global gred
  # On ne cree le menu popup qu'UNE fois...
  if [winfo exists .menupopupGrafcet] {
     return
  }
  set gred(Grafcet,popup1) [set menu [menu .menupopupGrafcet -tearoff 0]]
  $menu add command \
    -label "Couper" \
    -command {gred:cmd:cut [gred:windowToCanvas .[gred:getGrafcetName [focus]]]}
  $menu add command \
    -label "Copier" \
    -command \
     {gred:cmd:copy [gred:windowToCanvas .[gred:getGrafcetName [focus]]]}
  $menu add command \
    -label "Coller"  \
    -command \
     {gred:cmd:paste [gred:windowToCanvas .[gred:getGrafcetName [focus]]]}
  $menu add command \
    -label "Seléctionner tous les objets"  \
    -command \
     {gred:cmd:selectAll [gred:windowToCanvas .[gred:getGrafcetName [focus]]]}

  $menu add separator
    
  # Creation d'un item de menu pour chaque type d'étape :
  # Faire appel à une global du genr gred(Etape,types)
  set i 0
  foreach EtapeType $gred(etape,name) {
     set command "Etape:addFromPopup  \
           \[gred:windowToCanvas .\[gred:getGrafcetName \[focus\]\]\] \
           [lindex $gred(etape,type) $i]"
     $menu add command -label "$EtapeType"\
                       -command $command
     incr i
  }
  
  $menu add separator
  
  $menu add command \
   -label "Ajouter une transition"  \
   -command \
    {Trans:addFromPopup [gred:windowToCanvas .[gred:getGrafcetName [focus]]]}
  $menu add command \
   -label "Ajouter un cartouche"  \
   -command \
    {Cart:addFromPopup [gred:windowToCanvas .[gred:getGrafcetName [focus]]]}\
   -state disabled
   
  $menu add separator
  
  $menu add command \
   -label "Sauvegarder"  \
   -command \
    {gred:file:save [gred:windowToCanvas .[gred:getGrafcetName [focus]]]}
  $menu add command \
   -label "Imprimer..."  \
   -command \
    {gred:cmd:print [gred:windowToCanvas .[gred:getGrafcetName [focus]]]}
      
#     MenuCommand    grafcet1 "Save as..." \
#        {gred:file:saveas [gred:windowToCanvas .[gred:getGrafcetName [focus]]]}
#     MenuCommand    grafcet1 "Export..."  {gred:cmd:export}
#     MenuCommand    grafcet1 "Import..."  {gred:cmd:import}
}

# ########################################################################
# # a deplacer dans libs/packages/menuPackage.tk
# ########################################################################
# 
# ########################################################################
# # MenuPopup --
# # 
# # 
# # 
# proc MenuPopup { label } {
# global Menu
# 
#   if [info exists Menu(menu,$label)] {
#     error "Menu $label already defined."
#   }
#   
#   set Menu(menu,$label) [menu .menupopup$label -tearoff 0]
#   
#   return $Menu(menu,$label)
# }

