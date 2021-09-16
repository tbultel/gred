########################################################################
# programme de test des actions sur la souris 
# nom du programme : grbindings.tcl
# crée le 02/09/96 par commeau@ensta.fr
########################################################################


########################################################################
# gred:initBindings -- Initialisation des bindings
# 
# Définition des évènements symboliques de bas niveau en fonction 
# des évènement physiques.
# Sera déplacer au meme niveau que la redéfinition des touches 
# &lt;Command&gt;, &lt;Meta&gt;, ...<BR>
# 
# A COMPLETER: METTRE FICHIER "macintosh.tcl"(proc macintosh), ..
# 
proc gred:initBindings {w} {
   global gred gred${w}

   ### A VIRE SI OK
   # # #    upvar #0 $gred(grafcetCourant) grafcet
   
   # # # A VIRER SI OK (21/02/96)
   # # # set c $gred(canvas)
   #####################################################################  
   # Définition des évènements symboliques de bas niveau en fonction 
   # des évènement physiques
   # Sera déplacer au meme niveau que la redéfinition des touches 
   # <Command>, Meta>, ...

   event add <<B1Press>>    <Button-1>
   event add <<B1Motion>>   <Button1-Motion>
   event add <<B1Release>>  <ButtonRelease-1>
   event add <<B1Double>>   <Double-1><ButtonRelease-1>
   
   event add <<B2Press>>    <Button-2>
   event add <<B2Motion>>   <Button2-Motion>
   event add <<B2Release>>  <ButtonRelease-2>
   event add <<B2Double>>   <Double-2><ButtonRelease-2>
 
   event add <<B3Press>>    <Button-3>
   event add <<B3Motion>>   <Button3-Motion>
   event add <<B3Release>>  <ButtonRelease-3>
   event add <<B3Double>>   <Double-3><ButtonRelease-3>
 
   event add <<Delete>>     <Delete>
   event add <<Delete>>     <BackSpace>
   
   event add <<ShiftPress>>   <Shift_L>
   event add <<ShiftPress>>   <Shift_R>
   event add <<ShiftRelease>> <KeyRelease-Shift_L>
   event add <<ShiftRelease>> <KeyRelease-Shift_R>
   
   # A COMPLETER OU METTRE FICHIER "macintosh.tcl"(proc macintosh), ..
   global tcl_platform
   switch -exact -- $tcl_platform(platform) {
     macintosh {
        event add <<B2Press>>   <Control-Option-Button-1>
        event add <<B2Motion>>  <Control-Option-Button1-Motion>
        event add <<B2Release>> <Control-Option-ButtonRelease-1>
        event add <<B2Double>>  <Control-Option-Double-1><ButtonRelease-1>
        
        event add <<B3Press>>   <Control-Button-1>
        event add <<B3Motion>>  <Control-Button1-Motion>
        event add <<B3Release>> <Control-ButtonRelease-1>
        event add <<B3Double>>  <Control-Double-1><ButtonRelease-1>
        
        # Les ligne commentées suivantes ne sont pas au point :
        # elles ne sont pas fiable au (release au movaix moment...)
        event add <<ShiftPress>>   <Shift-KeyPress>
        event add <<ShiftPress>>   <Shift-Button>
        event add <<ShiftRelease>> <Shift-KeyRelease>
        event add <<ShiftRelease>> <Shift-ButtonRelease>
     } 
     windows {
        event add <<B2Press>>   <Control-Button-1>
        event add <<B2Motion>>  <Control-Button1-Motion>
        event add <<B2Release>> <Control-ButtonRelease-1>
        event add <<B2Double>>  <Control-Double-1><ButtonRelease-1>
     } 
     unix {
     } 
   } 

   #####################################################################  
   # initialisation a ne pas oublier
   gred:setShiftModeActive $w 0
   
   set gred${w}(oidSource) {}
   set gred${w}(oidDesti)  {}
   
   # On installe les modes de fonctionnement...
   installcommentEditMode
   installGrafcetMode
   
   ########################################################################
   ##### PREVOIR bind sur un bintag "ModeNormal" "ModeSelected"
   bind LinkEdit <<B1Press>>   {LinkEditB1Press   %W  %x %y}
   bind LinkEdit <<B1Motion>>  {LinkEditB1Motion  %W  %x %y}
   bind LinkEdit <<B1Release>> {LinkEditB1Release %W  %x %y}

   bind all <<ShiftPress>>   {gred:setShiftModeActive .[gred:getGrafcetName %W] 1}
   bind all <<ShiftRelease>> {gred:setShiftModeActive .[gred:getGrafcetName %W] 0}   
   
} ;# endproc gred:initBindings

# installcommentEditMode -- Mode de fonctionnement "commentEdit"
# Procédure installant le mode de fonctionnement "commentEdit".
# Installe les procédure nécessaire au bon fonctionnement du mode.
proc installcommentEditMode {} {
   bind commentEdit <<B1Press>> {CommentEditB1Press %W  %x %y ; break}
   bind commentEdit <<B1Motion>> {CommentEditB1Motion %W  %x %y ; break}
   bind commentEdit <<B1Release>> {CommentEditB1Release %W  %x %y ; break}
   bind commentEdit <<B1Double>> {break}
   bind commentEdit <<B2Press>> {LeaveModeCommentEdit %W ; break}
   bind commentEdit <<B2Motion>> {break}
   bind commentEdit <<B2Release>> {break}
   bind commentEdit <<B2Double>> {break}
   bind commentEdit <<B3Press>> {LeaveModeCommentEdit %W ; break}
   bind commentEdit <<B3Motion>> {break}
   bind commentEdit <<B3Release>> {break}
   bind commentEdit <<B3Double>> {break}
   
#    bind selectBox <Enter> {puts AAAA ; %W config -cursor draped_box}
#    bind selectBox <Leave> {%W config -cursor tcross}
}

# installGrafcetMode -- Mode de fonctionnement en mode "GrafcetMode"
# Procédure installant le mode de fonctionnement "GrafcetMode".
# Installe les procédure nécessaire au bon fonctionnement du mode.
proc installGrafcetMode {} {
   global gred
   
   bind Grafcet <Right>        {rightPress  %W}
   bind Grafcet <Left>         {leftPress   %W}
   bind Grafcet <Up>           {upPress     %W}
   bind Grafcet <Down>         {downPress   %W}
   
   bind Grafcet <Prior>        {pageUp      %W}
   bind Grafcet <Next>         {pageDown    %W}
   
   bind Grafcet <Home>         {homePress   %W}
   bind Grafcet <End>          {endPress    %W}
   bind Grafcet <$gred(Meta)-Right>\
                               {toRight   %W}
   bind Grafcet <$gred(Meta)-Left>\
                               {toLeft    %W}
#    bind Gred <Right>             {rightPress %W}
#    bind Gred <Left>              {leftPress  %W}
#    bind Gred <Up>                {upPress    %W}
#    bind Gred <Down>              {downPress  %W}

   bind Grafcet <<B1Press>>   {Mouse:B1Press   %W  %x %y}
   bind Grafcet <<B1Motion>>  {Mouse:B1Motion  %W  %x %y}
   bind Grafcet <<B1Release>> {Mouse:B1Release %W  %x %y}
   bind Grafcet <<B1Double>>  {Mouse:B1Double  %W  %x %y}
   
   bind Grafcet <<B2Press>>   {Mouse:B2Press   %W %x %y}
   bind Grafcet <<B2Motion>>  {Mouse:B2Motion  %W %x %y}
   bind Grafcet <<B2Release>> {Mouse:B2Release %W %x %y}
   
   bind Grafcet <<B3Press>>   {Mouse:B3Press   %W %x %y}
   bind Grafcet <<Delete>> {Sel:delete %W}
}

# Les procédures suivantes permettent de gérer des déplacements de
# la fenêtre de visualisation sur le canvas affichant le grafcet.
proc toLeft {w} {
    set c [gred:windowToCanvas .[gred:getGrafcetName $w]]
    
    $c xview moveto 0
}
proc toRight {w} {
    set c [gred:windowToCanvas .[gred:getGrafcetName $w]]
    
    $c xview moveto 1
}
proc homePress {w} {
    set c [gred:windowToCanvas .[gred:getGrafcetName $w]]
    
    $c yview moveto 0
}
proc endPress {w} {
    set c [gred:windowToCanvas .[gred:getGrafcetName $w]]
    
    $c yview moveto 1
}
proc pageUp {w} {
    set c [gred:windowToCanvas .[gred:getGrafcetName $w]]

    $c yview scroll -1 pages
}
proc pageDown {w} {
    set c [gred:windowToCanvas .[gred:getGrafcetName $w]]

    $c yview scroll 1 pages
}
proc upPress {w} {
    global gred
    set c [gred:windowToCanvas .[gred:getGrafcetName $w]]

    if [Sel:exist $c] {
        MoveSel  $c 0  -1
    } else {
        $c yview scroll -1 $gred(arrowScroll)
    }
}
proc downPress {w} {
    global gred
    set c [gred:windowToCanvas .[gred:getGrafcetName $w]]

    if [Sel:exist $c] {
        MoveSel  $c 0  1
    } else {
        $c yview scroll 1 $gred(arrowScroll)
    }
}
proc leftPress {w} {
    global gred
    set c [gred:windowToCanvas .[gred:getGrafcetName $w]]

    if [Sel:exist $c] {
        MoveSel  $c -1  0
    } else {
        $c xview scroll -1 $gred(arrowScroll)
    }
}
proc rightPress {w} {
    global gred
    set c [gred:windowToCanvas .[gred:getGrafcetName $w]]

    if [Sel:exist $c] {
        MoveSel  $c 1  0
    } else {
        $c xview scroll 1 $gred(arrowScroll)
    }
}


########################################################################
# gred:setShiftModeActive --
# 
# Gestion (mémorisation et lecture) de l'état appuis sur &lt;Shift&gt;
# 
proc gred:setShiftModeActive {w bool} {
    upvar #0 gred${w} gred
    set gred(shiftActif) $bool
}

########################################################################
# gred:isShiftModeActive -- Teste si la touche shift est active 
# 
# 
# 
proc gred:isShiftModeActive {w} {
    upvar #0 gred${w} gred
    return $gred(shiftActif)
}

########################################################################
# Traitement du Bouton 1
########################################################################

########################################################################
# Mouse:B1Press -- Appui sur le bouton 1 de la souris
# 
# 
# 
proc Mouse:B1Press {c x y} {
  upvar #0 gred.[gred:getGrafcetName $c] gred
  focus $c
  
  # memorisation des coordonnees initiales apres conversion en coord canvas
  set gred(mouse,xPress) [set x [$c canvasx $x]]
  set gred(mouse,yPress) [set y [$c canvasy $y]]
  set gred(mouse,xgPress) [Grid $gred(mouse,xPress)]
  set gred(mouse,ygPress) [Grid $gred(mouse,yPress)]
    
  # On mémorise l'oid éventuellement présent sous le clique souris 
  # set gred(oidSource) [Obj:getPointedOid [Grid $x] [Grid $y]]
  # puts [Obj:getPointedOid $x $y]
  set gred(oidSource) [Obj:getPointedOid $c $x $y]
    
}

########################################################################
# scrollCanvas -- Permet de scroller le canvas
# Si direction vaut :
# <OL>
# <LI> <I>xview</I>: On scrolle dans la direction horizontale vers
#     <OL>
#         <LI> la droite si <I>sens</I> vaut 1
#         <LI> la gauche si <I>sens</I> vaut -1
#     </OL>
# <LI> <I>yview</I>: On scrolle dans la direction verticale vers
#     <OL>
#         <LI> la bas si <I>sens</I> vaut 1
#         <LI> le haut si <I>sens</I> vaut -1
#     </OL>
proc scrollCanvas {c direction sens} {
    upvar #0 gred.[gred:getGrafcetName $c] gred
    if $gred(scrolling$direction$sens) {
        $c $direction moveto [expr [lindex [$c $direction] 0]+ $sens * 0.004]
        update idletasks
        after 150 scrollCanvas $c $direction $sens
    }
}
########################################################################
# autoScrollCanvas -- Permet de d'autoScroller un canvas
# Permet de scroller le canvas <I>c</I> passé en paramètre
proc autoScrollCanvas {c} {
  upvar #0 gred.[gred:getGrafcetName $c] gred
  # On récuprère la position de la souris
  set x $gred(mouse,xCurrent)
  set y $gred(mouse,yCurrent)
  
  # On récupère la taille du canvas
  set scrollRegion [$c cget -scrollregion]
  set canvasWidth  [winfo pixels $c [lindex $scrollRegion 2]]
  set canvasHeight [winfo pixels $c [lindex $scrollRegion 3]]

  # On récupère la taille de la fenêtre
  set canvasLeft  [expr [lindex [$c xview] 0]*$canvasWidth]
  set canvasRight [expr [lindex [$c xview] 1]*$canvasWidth]
  set canvasUp    [expr [lindex [$c yview] 0]*$canvasHeight]
  set canvasDown  [expr [lindex [$c yview] 1]*$canvasHeight]
  
  # Il faut déplacer la vue vers la gauche
  if {$canvasLeft > $x} {
    set gred(scrollingxview-1) 1
    scrollCanvas $c xview -1
  } else {
    set gred(scrollingxview-1) 0
  }
  # Il faut déplacer la vue vers la droite
  if {$canvasRight < $x} {
    set gred(scrollingxview1) 1
    scrollCanvas $c xview 1
  } else {
    set gred(scrollingxview1) 0
  }
  
  # Il faut déplacer la vue vers le haut
  if {$canvasUp > $y} {
    set gred(scrollingyview-1) 1
    scrollCanvas $c yview -1
  } else {
    set gred(scrollingyview-1) 0
  }
  # Il faut déplacer la vue vers le bas
  if {$canvasDown < $y} {
    set gred(scrollingyview1) 1
    scrollCanvas $c yview 1
  } else {
    set gred(scrollingyview1) 0
  }
}

proc stopScrollCanvas {c} {
  upvar #0 gred.[gred:getGrafcetName $c] gred
  
  set gred(scrollingxview1)  0
  set gred(scrollingxview-1) 0
  set gred(scrollingyview1)  0
  set gred(scrollingyview-1) 0
}
########################################################################
# Mouse:B1Motion -- Le bouton 1 de la souris reste appuye
# 
# 
# 
proc Mouse:B1Motion {c x y} {
  upvar #0 gred.[gred:getGrafcetName $c] gred

  # mémorisation des coordonnées courantes après conversion en coord canvas
  set gred(mouse,xCurrent) [set x [$c canvasx $x]]
  set gred(mouse,yCurrent) [set y [$c canvasy $y]]
  
  # On mémorise l'oid éventuellement présent sous le drag souris 
  set gred(oidDesti) [Obj:getPointedOid $c [Grid $x] [Grid $y]]
      
  if [Sel:exist $c] {
     Mouse:B1MotionWithSelection $c
  } else {
     Mouse:B1MotionWithNoSelection $c
  }
  
  autoScrollCanvas $c
}

# Mouse:B1MotionWithSelection --
# 
# Si on draque en aillant cliqué sur un objet sélectionné on déplace, 
# sinon on dessine un rectangle de sélection.
proc Mouse:B1MotionWithSelection {c} {
  global gred
  upvar #0 gred.[gred:getGrafcetName $c] gredWindow
    
  # choix et création de l'objet virtuel a dessiner
  $c delete withtag virtualObject
  
  if [Sel:isOidSelected $c $gredWindow(oidSource)] {
    
    # Dessin du bloc virtuel pour le déplacement de la sélection.
    lassign [Sel:bbox $c] x1 y1 x2 y2
    set dx [expr $gredWindow(mouse,xCurrent) - $gredWindow(mouse,xPress)]
    set dy [expr $gredWindow(mouse,yCurrent) - $gredWindow(mouse,yPress)]
    
    eval $c create rectangle \
               [lsum "$x1 $y1 $x2 $y2" "$dx $dy $dx $dy" ] \
               -outline $gred(virtualColor) -tag virtualObject
  
  } else {
  
    # rectangle for selection
    $c create rectangle \
           $gredWindow(mouse,xPress) $gredWindow(mouse,yPress) \
           $gredWindow(mouse,xCurrent) $gredWindow(mouse,yCurrent) \
           -outline $gred(virtualColor) -tag virtualObject
      
  };# end if
}

# Mouse:B1MotionWithNoSelection --
# 
proc Mouse:B1MotionWithNoSelection {c} {
  global gred
  upvar #0 gred.[gred:getGrafcetName $c] gredWindow
  # Dans la procédure suivante supprimer la ligne suivante...
  # i.e. se debrouiller pour supprimer la ligne suivante...
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  set SourceExist [Obj:isEtapeOrTrans $gredWindow(oidSource)]
  set DestiExist  [Obj:isEtapeOrTrans $gredWindow(oidDesti)]

  # choix et création de l'objet virtuel a dessiner
  $c delete withtag virtualObject
  
  switch -exact -- $SourceExist.$DestiExist {
  
    0.0 {
      # rectangle for selection
      $c create rectangle \
             $gredWindow(mouse,xPress) $gredWindow(mouse,yPress) \
             $gredWindow(mouse,xCurrent) $gredWindow(mouse,yCurrent) \
             -outline $gred(virtualColor) -tag virtualObject
    }
    
    0.1 {
      # link from nothing to Destination
      $c create line \
              $gredWindow(mouse,xPress) $gredWindow(mouse,yPress) \
              $grafcet([set gredWindow(oidDesti)],x) \
              $grafcet([set gredWindow(oidDesti)],y) \
              -fill $gred(virtualColor) -tag virtualObject
    }
    
    1.0 {
      # link from Source to nothing
      $c create line \
              $grafcet([set gredWindow(oidSource)],x) \
              $grafcet([set gredWindow(oidSource)],y) \
              $gredWindow(mouse,xCurrent) \
              $gredWindow(mouse,yCurrent) \
              -fill $gred(virtualColor) -tag virtualObject
    }
    
    1.1 {
      # link from Source to Destination
      $c create line \
              $grafcet([set gredWindow(oidSource)],x) \
              $grafcet([set gredWindow(oidSource)],y) \
              $grafcet([set gredWindow(oidDesti)],x) \
              $grafcet([set gredWindow(oidDesti)],y) \
              -fill $gred(virtualColor) -tag virtualObject
    }
  
  };# end switch
}

########################################################################
# Mouse:B1Release -- Le bouton 1 de la souris est relache
# 
# 
# 
proc Mouse:B1Release {c x y} {
  upvar #0 gred.[gred:getGrafcetName $c] gred
  
  stopScrollCanvas $c

  # On mémorise l'oid éventuellement présent sous le release souris 
  set gred(mouse,xRelease) [$c canvasx $x]
  set gred(mouse,yRelease) [$c canvasy $y]
  set gred(mouse,xgRelease) [Grid $gred(mouse,xRelease)]
  set gred(mouse,ygRelease) [Grid $gred(mouse,yRelease)]
  
  # destruction de l'objet virtuel
  $c delete withtag virtualObject
  
  if [Sel:exist $c] {
     Mouse:B1ReleaseWithSelection $c
  } else {
     Mouse:B1ReleaseWithNoSelection $c
  }
  
}

# Mouse:B1ReleaseWithSelection --
# 
# FONCTIONNEMENT DE LA SELECTION (modif en cours)<BR>
# <B>Si ShiftActif</B><BR><UL>
#   <LI> récupérer le ou les oids (suivant simple clique ou drag)
#   <LI> complémenter la sélection du ou des objets trouvés.
# </UL><BR>
# <B>Si pas ShiftActif</B><BR><UL>
#   <LI> simple click
#    <UL>
#       <LI> sur un goid
#           <UL>
#              <LI> if source selected      => ne rien faire.
#              <LI> if source not selected  => Sel:new $oid
#           </UL>
#       <LI> sur rien                     => tout déselectionner
#    </UL>
#   <LI> drag
#     <UL>
#         <LI> sur un goid selectionné      => Sel:move $goid
#         <LI> sur rien                     => Sel:new $oids
#     </UL>
# </UL>   
proc Mouse:B1ReleaseWithSelection {c} {
  upvar #0 gred.[gred:getGrafcetName $c] gred

  
  if [gred:isShiftModeActive .[gred:getGrafcetName $c]] {
      
     # We have press the Shift key
     if {[Canvas_AreNeighbour $c \
             $gred(mouse,xPress)   $gred(mouse,yPress) \
             $gred(mouse,xRelease) $gred(mouse,yRelease)] } {
                  
        # simple click
        set oids $gred(oidSource)
        
     } else { 
     
        # drag click : get enclosed oids in the sel rectangle
        set oids [Obj:find $c\
             $gred(mouse,xPress)   $gred(mouse,yPress) \
             $gred(mouse,xRelease) $gred(mouse,yRelease)]
             
     }
     
     # "oids" contiens zero or more oids 
     Sel:complement $c $oids

  } else {
      
     # We have not press the Shift key
     if {[Canvas_AreNeighbour $c) \
             $gred(mouse,xPress)   $gred(mouse,yPress) \
             $gred(mouse,xRelease) $gred(mouse,yRelease)] } {
                  
                  
        # Simple click (LES DEUX IF SUIVANTS PEUVENT ETRE "&&")
        if [Obj:isSelectable $gred(oidSource)] {
           # Simple click on an object 
           if ![Sel:isOidSelected $c $gred(oidSource)] {
              # Simple click on a selectable but non selected object 
              Sel:new $c $gred(oidSource)
           } 
        } else {
           # Simple click on nothing 
           Sel:clear $c
        }
        
     } else { 
     
        # Drag Click
        if [Sel:isOidSelected $c $gred(oidSource)] {
           # move selected oid or oids
           set dx [expr $gred(mouse,xRelease) - $gred(mouse,xPress)]
           set dy [expr $gred(mouse,yRelease) - $gred(mouse,yPress)]
           Sel:move $c $dx $dy
        } else {
           # Drag click from nothing 
           Sel:new $c [Obj:find $c\
                $gred(mouse,xPress) $gred(mouse,yPress) \
                $gred(mouse,xRelease) $gred(mouse,yRelease) \
           ]
        }
     }
  }

}

# Mouse:B1ReleaseWithNoSelection --
# 
proc Mouse:B1ReleaseWithNoSelection {c} {
  global gred
  upvar #0 gred.[gred:getGrafcetName $c] grafcet
    
  # les coordonnees a l'appui sont-elles les memes qu'au lache' ?
  if [Canvas_AreNeighbour $c \
           $grafcet(mouse,xPress)   $grafcet(mouse,yPress)  \
           $grafcet(mouse,xRelease) $grafcet(mouse,yRelease)] {

    # Simple Click : on sélectionne un oid ou on crée un objet (Etape)
    if [Obj:isSelectable $grafcet(oidSource)] {
    
      # Si on a cliqué sur un lien => mode édition de lien
      switch [Obj:getType $grafcet(oidSource)] {
        Link {
          set btag [bindtags $c]
          set idx [lsearch -exact $btag $c]
          bindtags $c [lreplace $btag $idx $idx LinkEdit]
          report " On passe en LinkEdit "
        }
        # On regarde si on a cliqué sur un commentaire d'une étape ou d'une
        # transition. Si c le cas, on passe en mode commentEdit !
        Etape -
        Trans {
          set items [Canvas_GetPointedItems $c $grafcet(mouse,xRelease)\
                                          $grafcet(mouse,yRelease)]
          foreach item $items {
            if {[lsearch -exact [$c gettags $item] "Comment"] >= 0} {
              set btag [bindtags $c]
              set idx [lsearch -exact $btag $c]
              bindtags $c [lreplace $btag $idx $idx commentEdit]
# puts " On passe en commentEdit "
              Sel:new $c $item
              return
              # On positionne le nom de l'oid dont on va bouger le commentaire
              # set grafcet(
              # break
            }
          }
        }
        
      }
      
      # Selection de la source VERIFIER UNICITE DES OBJETS SELECTIONN'ES
      Sel:new $c $grafcet(oidSource)
    } else {
      # Creation d'un objet en X,Y
      $gred(defaultSourceObjectType):add $c \
              $grafcet(mouse,xRelease) $grafcet(mouse,yRelease)
    }
  } else { 
    
    # Drag click : la souris a effectivement été déplacée.
    # création d'un lien + objet ou bien sélection d'un rrectangle

    set SourceExist [Obj:isEtapeOrTrans $grafcet(oidSource) ]
    set DestiExist  [Obj:isEtapeOrTrans $grafcet(oidDesti)  ]

    switch -exact -- $SourceExist.$DestiExist {
    
      0.0 {
        # selection du contenu du rectangle de sélection
        Sel:new $c [Obj:find $c\
             $grafcet(mouse,xPress) $grafcet(mouse,yPress) \
             $grafcet(mouse,xRelease) $grafcet(mouse,yRelease)]
       }
      
      0.1 {
        # link from nothing to Destination
        # creation d'un objet complementaire en amont de la destination
        set Type [Obj:getComplementaryType  $grafcet(oidDesti)]
        undo_mark .[gred:getGrafcetName $c]
        set grafcet(oidSource) \
           [$Type:add $c $grafcet(mouse,xPress) $grafcet(mouse,yPress)]
        # creation d'un lien
        Link:add $c $grafcet(oidSource) $grafcet(oidDesti)
        undo_unMark .[gred:getGrafcetName $c]
      }
      
      1.0 {
        # link from Source to nothing
        # creation d'un objet complementaire en aval de la source
        set Type [Obj:getComplementaryType  $grafcet(oidSource)]
        undo_mark .[gred:getGrafcetName $c]
        set grafcet(oidDesti) \
             [$Type:add $c $grafcet(mouse,xRelease) $grafcet(mouse,yRelease)]
        # creation d'un lien
        Link:add $c $grafcet(oidSource) $grafcet(oidDesti)
        undo_unMark .[gred:getGrafcetName $c]
       }
      
      1.1 {
        # link from Source to Destination
        if [Obj:areComplementary $grafcet(oidSource) $grafcet(oidDesti)] {
          # Rajout d'un lien aux objets existants
          Link:add $c $grafcet(oidSource) $grafcet(oidDesti)
        } else {
          gred:status "Gred: Un lien relie une transition vers\
               une étape ou l'inverse."
          bell
          return
        }
      }
    };# end switch
  }
}
########################################################################
# Mouse:B1Double -- Double clic sur le bouton 1 de la souris
# 
# 
# 
proc Mouse:B1Double {c x y} {
  upvar #0 gred.[gred:getGrafcetName $c] gred
  
  # Les coordonnée de la source ont déja été mémorisée par Mouse:B1Press
  
  # Le seul type d'objet dont on veux afficher une boite d'information 
  # sont (pour l'instant) l'etape la  transition.
  # J'ai garder cette structure pour pouvoir facilement en rajouter 
  # d'autres : link, cartouch, ...))
  
  # # if [Sel:exist]  {return}

  set Type [Obj:getType $gred(oidSource)]
  switch -exact -- $Type {
    Etape - 
    Trans {
      # appel de la procedure de modification des parametres de 
      # l'objet source gred(oidSource)
      $Type:changeParams $c $gred(oidSource) all
    }
  }
}

########################################################################
# Traitement du Bouton 2
########################################################################

########################################################################
# Mouse:B2Press -- Appui sur le bouton 2 de la souris
# 
# 
# 
proc Mouse:B2Press {c x y} {
  upvar #0 gred.[gred:getGrafcetName $c] gred

  # Marquage pour le drag : besoin des coordonnée Windows (%x %y)
  # $c scan mark [expr int($x)] [expr int($y)]
  $c scan mark $x $y

  # Memorisation des coordonnees initiales
  set gred(mouse,xPress) [$c canvasx $x]
  set gred(mouse,yPress) [$c canvasy $y]
  # # set gred(mouse,xgPress) [Grid $gred(mouse,xPress)]
  # # set gred(mouse,ygPress) [Grid $gred(mouse,yPress)]
  
}

########################################################################
# Mouse:B2Motion -- Le bouton 2 de la souris reste appuye
# 
# 
# 
proc Mouse:B2Motion {c x y} {
  upvar #0 gred.[gred:getGrafcetName $c] gred

  # le drag du canvas est effectue
  # $c scan dragto [expr int($x)] [expr int($y)]
  $c scan dragto $x $y

}

########################################################################
# Mouse:B2Release -- Le bouton 2 de la souris est relache
# 
# 
# 
proc Mouse:B2Release {c x y} {
  upvar #0 gred gredPref
  upvar #0 gred.[gred:getGrafcetName $c] gredWindow
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet

  # On mémorise l'oid éventuellement présent sous le release souris 
  set gredWindow(mouse,xRelease) [set x [$c canvasx $x]]
  set gredWindow(mouse,yRelease) [set y [$c canvasy $y]]
  set gredWindow(mouse,xgRelease) [Grid $gredWindow(mouse,xRelease)]
  set gredWindow(mouse,ygRelease) [Grid $gredWindow(mouse,yRelease)]

    
  # Si la souris s'est déplacée : on n'a rien a faire !
  if ![Canvas_AreNeighbour $c \
              $gredWindow(mouse,xPress)   $gredWindow(mouse,yPress)   \
              $gredWindow(mouse,xRelease) $gredWindow(mouse,yRelease)] {
     return
  }
  
  # Bien que la création d'objet ne se fasse que sur la grille, il 
  # vaut mieux "grider" les coordonnées car elles sont utilisées 
  # pour le calcul de longueurs...
  set xg $gredWindow(mouse,xgRelease)
  set yg $gredWindow(mouse,ygRelease)
  set gredPref(sequence,yStep) [Grid $gredPref(sequence,yStep)]
  
  # Création une sequence ou création une transition
  
  # y-a-t-il un objet en X,Y
  set gredWindow(oidSource) [Obj:getPointedOid $c $xg $yg]

  if {![Obj:isEtapeOrTrans $gredWindow(oidSource)]} {
     # creation d'une transition (i.e debut d'une nouvelle sequence)
     # Création d'un nouvel objet (i.e debut d'une nouvelle sequence)
     # Par défaut le type crée est le compléments de celui créé par 
     # Mouse:B1Press, donc une transition 
     set Type [Obj:getComplementaryType $gredPref(defaultSourceObjectType)]
     # $Type:add $c $grafcet(mouse,xRelease) $grafcet(mouse,yRelease)
     $Type:add $c $xg $yg
     
     return
  }

  # Creation d'un objet en aval de la sequence existante :
  set oidUp $gredWindow(oidSource)
  set yNew [expr $grafcet($oidUp,y) + $gredPref(sequence,yStep)]
  set oidNew [Obj:getPointedOid $c $xg $yNew]
  while {[Obj:isEtapeOrTrans $oidNew] } {
    set oidUp $oidNew
    set yNew [expr $grafcet($oidUp,y) + $gredPref(sequence,yStep)]
    set oidNew [Obj:getPointedOid $c $xg $yNew]
    if ![Link:exist  $c $oidUp $oidNew ] {
        bell
        
        return
    }
  }
  set Type [Obj:getComplementaryType $oidUp]
  
  undo_mark .[gred:getGrafcetName $c]
  set oidNew [$Type:add $c $grafcet($oidUp,x) $yNew]
  Link:add $c $oidUp $oidNew
  undo_unMark .[gred:getGrafcetName $c]
  
}

########################################################################
# Traitement du Bouton 3
########################################################################

########################################################################
# Mouse:B3Press -- Appui sur le bouton 3 de la souris
# 
# 
# 
proc Mouse:B3Press {c x y} {
  upvar #0 gred.[gred:getGrafcetName $c] gredGrafcet
  global gred
  set x [$c canvasx $x]
  set y [$c canvasy $y]
  set xRoot [expr int([winfo pointerx $c])]
  set yRoot [expr int([winfo pointery $c])]
  
  # memorisation des coordonnees initiales
  set gredGrafcet(mouse,xPress) $x
  set gredGrafcet(mouse,yPress) $y
  
  # y-a-t-il un objet en X,Y
  set oid [Obj:getPointedOid $c $x $y]
  switch -exact -- [Obj:getType $oid] {
    Etape   {tk_popup $gred(Etape,popup1)   $xRoot $yRoot}
    Trans   {tk_popup $gred(Trans,popup1)   $xRoot $yRoot}
    default {tk_popup $gred(Grafcet,popup1) $xRoot $yRoot}
  }
  
}

# CommentEditB1Press -- En mode "commentEdit" gére l'appuie sur le bouton 1.
# On clique sur le commentaire (déjà selectionné)
# pour le déplacer. On mémorise la position du click (variable
# <I>gred(mouse,xPress)</I> et <I>gred(mouse,yPress)</I>), la valeur
# du commentaire avant déplacement dans la variable 
# <I>gred(commentFieldBeforeMove)</I>, ainsi que la valeur de l'item
# (représentant le commentaire) à déplacer (dans <I>gred(commentItem)</I>).
proc CommentEditB1Press {c x y} {
  upvar #0 gred.[gred:getGrafcetName $c] gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  focus $c
  
  # memorisation des coordonnees initiales apres conversion en coord canvas
  set gred(mouse,xPress) [set x [$c canvasx $x]]
  set gred(mouse,yPress) [set y [$c canvasy $y]]
  set gred(mouse,xMove) $gred(mouse,xPress)
  set gred(mouse,yMove) $gred(mouse,yPress)
  set gred(commentFieldBeforeMove) $grafcet($gred(oidSource),comment)
  
  # On mémorise l'oid éventuellement présent sous le clique souris 
  set gred(oidSource) [Obj:getPointedOid $c $x $y]
  set items [Canvas_GetPointedItems $c $gred(mouse,xPress)\
                                       $gred(mouse,yPress)]
  # As t-on clique sur le commentaire ?
  foreach item $items {
    if {[lsearch -exact [$c gettags $item] "Comment"] >= 0} {
      Sel:clear $c
      set gred(commentItem) $item
# puts $gred(commentItem)
      return
    }
  }
  # On a pas clique sur un commentaire ==> On quitte le mode commentEdit
  Sel:clear $c
  set btag [bindtags $c]
  set idx [lsearch -exact $btag commentEdit]
  bindtags $c [lreplace $btag $idx $idx $c]
# puts "Je quitte commentEdit !"
}

# CommentEditB1Motion -- En mode "commentEdit" gére le déplacement de la souris.
# On déplace le commentaire (on n'a pas encore
# encore relaché le bouton1). On utilise les variables
# <I>gred(mouse,xMove)</I> et <I>gred(mouse,yMove)</I> pour mémoriser la
# dernière position de la souris.
proc CommentEditB1Motion {c x y} {
  upvar #0 gred.[gred:getGrafcetName $c] gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  
  set x [$c canvasx $x]
  set y [$c canvasy $y]
  set dx [expr -$gred(mouse,xMove)+ [$c canvasx $x]]
  set dy [expr -$gred(mouse,yMove)+ [$c canvasy $y]]
  set gred(mouse,yMove) $y
  set gred(mouse,xMove) $x
  $c move $gred(commentItem) $dx $dy
  $c delete reperLine
  $c create line $grafcet($gred(oidSource),x) $grafcet($gred(oidSource),y)\
                 $x $y -tags "reperLine"
}

# CommentEditB1Release --
# En mode "commentEdit" gére le relachement du bouton de la souris.
# On relache le bouton1. On update le
# champs comment de l'oid (étape ou transition). On quitte le mode
# "commentEdit". On efface la selection (à voir...).
proc CommentEditB1Release {c x y} {
  upvar #0 gred.[gred:getGrafcetName $c] gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  $c delete reperLine
  
  set comment $grafcet($gred(oidSource),comment)
  set pos [$c coords $gred(commentItem)]
  set x [lindex $pos 0]
  set y [lindex $pos 1]
  [Obj:getType $gred(oidSource)]:changeParams \
             $c $gred(oidSource) comment\
             [list [expr $x-$grafcet($gred(oidSource),x)]\
                   [expr $y-$grafcet($gred(oidSource),y)]\
                   [lindex $comment 2]]
  # set grafcet($gred(oidSource),comment) [list $x $y [lindex $comment 2]]
# puts $grafcet($gred(oidSource),comment)
  # On quitte le mode commentEdit
  Sel:clear $c
  set btag [bindtags $c]
  set idx [lsearch -exact $btag commentEdit]
  bindtags $c [lreplace $btag $idx $idx $c]
puts "Je quitte CommentEditB1Release !"  
}

# LeaveModeCommentEdit -- Quitte le mode "commentEdit" et annule le déplacement.
proc LeaveModeCommentEdit {c} {
  upvar #0 gred.[gred:getGrafcetName $c] gred
  upvar #0 grafcet.[gred:getGrafcetName $c] grafcet
  
  # On annule déplacement du commentaire...
  $c coords $gred(commentItem)\
   [expr $grafcet($gred(oidSource),x)+[lindex $gred(commentFieldBeforeMove) 0]]\
   [expr $grafcet($gred(oidSource),y)+[lindex $gred(commentFieldBeforeMove) 1]]

  # On efface la ligne qui relie le commentaire à l'objet
  $c delete reperLine
  
  # On quitte le mode commentEdit
  Sel:clear $c
  set btag [bindtags $c]
  set idx [lsearch -exact $btag commentEdit]
  bindtags $c [lreplace $btag $idx $idx $c]
puts "Je quitte LeaveModeCommentEdit !"   
}

# Les procédures suivantes sont liées à l'édition des liaison.
# Elle seront profondemenet modifiée (nom et fonction)

########################################################################
# LinkEditB1Press --
# 
# 
# 
proc LinkEditB1Press {c x y} {
  upvar #0 gred.[gred:getGrafcetName $c] gred

  set x [$c canvasx $x]
  set y [$c canvasy $y]
  
  report "je suis dans le mode handle : start"
}

########################################################################
# LinkEditB1Motion --
# 
# 
# 
proc LinkEditB1Motion {c x y} {
  upvar #0 gred.[gred:getGrafcetName $c] gred

  set x [$c canvasx $x]
  set y [$c canvasy $y]
  
  # memorisation des coordonnees courantes
  set gred(mouse,xCurrent) $x
  set gred(mouse,yCurrent) $y
  
}

########################################################################
# LinkEditB1Release --
# 
# 
# 
proc LinkEditB1Release {c x y} {
  upvar #0 gred.[gred:getGrafcetName $c] gred

  set x [$c canvasx $x]
  set y [$c canvasy $y]
  
  # remise a zero de la selection
  Sel:clear $c

  # memorisation des coordonnées au moment du laché
  set gred(mouse,xRelease) $x
  set gred(mouse,yRelease) $y

  # a-t-on-detecte une poignee d'edition de liaison ?  
  set oid [Obj:getPointedOid $c $x $y]
  
  
  switch -exact [Obj:getType $oid] {
  
    Link {
      Link:hideLinkHandle $c
      Link:showLinkHandle $c $oid
    }
    
    Etape -
    Trans -
    "" {
      set btag [bindtags $c]
      set idx [lsearch -exact $btag LinkEdit]
      bindtags $c [lreplace $btag $idx $idx $c]
      Link:hideLinkHandle $c
    }
    
    default {
      $c itemconfigure LinkHandle -fill red
      $c itemconfigure LinkHandle -outline red
      $c itemconfigure $oid -fill green
      $c itemconfigure $oid -outline green
    }
    
  }
  
# #   if [regexp "^(|Etape|Trans)$" "[Obj:getType $oid]"] {
# #     set btag [bindtags $c]
# #     bell
# #     set idx [lsearch -exact $btag LinkEdit]
# #     bindtags $c [lreplace $btag $idx $idx $c]
# #     
# #     Link:hideLinkHandle $c
# #   } elseif ![string compare [Obj:getType $oid] Link] {
# #     Link:hideLinkHandle $c
# #     Link:showLinkHandle $c $oid
# #   } else {    
# #     $c itemconfigure LinkHandle -fill red
# #     $c itemconfigure LinkHandle -outline red
# #     $c itemconfigure $oid -fill green
# #     $c itemconfigure $oid -outline green
# #   }
  
}

########################################################################
########################################################################
# procedures a trier
# # LA SUITE EST ICI PROVOIREMENT :
########################################################################
########################################################################
 
########################################################################
# MoveSel --
# 
# 
# 
proc MoveSel {c xGridStep yGridStep} { 
  global gred
  Sel:move $c [expr $xGridStep * $gred(grid)] [expr $yGridStep * $gred(grid)] 
  # # update idletask
}


########################################################################
# Canvas_GetPointedItems --
# 
# Retourne, pour le canvas $c, la liste des items au voisinage du point
# passés en argument 
# Les parametres peuvent etre passe sous une des formes suivantes : <PRE>
#     c x  y 
#     c {x y} </PRE>
# Utilise la globale canvas(overlappingDelta)
# 
# Prévoire changement de nom en "Canvas_FindItems" ??
# 
proc Canvas_GetPointedItems {c args} {
global canvas
  # Détermination des coordonnées des deux points suivant la façon dont 
  # les parametres sont passés
  if {[llength $args]==1}  {
       # args est une liste de 1 seul éléments double (le point)
       set args [lindex $args 0]
  }
  # args est une liste de 2 éléments (les coordonnées du point)
  set x [lindex $args 0]
  set y [lindex $args 1]
  upvar 0 canvas(overlappingDelta) D
  return [$c find overlapping \
                 [expr $x - $D] [expr $y - $D] \
                 [expr $x + $D] [expr $y + $D] ]
}

########################################################################
# Canvas_AreNeighbour --
# 
# Canvas_AreNeighbour retourne 1 si les deux points du canvas $c passés en 
# parametres sont suffisament proches
# Les parametres peuvent etre passe sous une des formes suivantes : <PRE>
#     c x1  y1  x2  y2
#     c {x1 y1} {x2 y2}
#     c {x1 y1 x2 y2} </PRE>
# Utilise une prréférence canvas(dragDelta)
# 
proc Canvas_AreNeighbour {c args} {
global canvas

  lassign [join $args] x1 y1 x2 y2
  set NoMove [expr (abs($x2 - $x1) <= $canvas(dragDelta)) \
              &&   (abs($y2 - $y1) <= $canvas(dragDelta)) ]
  return $NoMove
  
}

