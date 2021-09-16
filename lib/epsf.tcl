########################################################################
# Epsf_Box --
# 
# 
# 
# package provide epsf 0.1
########################################################################
# Epsf_Box -- Procédure générant un postscript à partir d'un canvas
# Cette procédure est la procédure principale d'un package permettant
# de générer un fichier postscript à partir d'un canvas. Le principe est
# d'utiliser la commande "postscript" du canvas.
# Cette procédure crée une fenêtre de dialogue permettant de faire passer
# des options comme la taille de la feuille et la zone à imprimer.
########################################################################
proc Epsf_Box {c} {
global gred tmp

  set toplevel [toplevel .print[gred:getGrafcetName $c]]
  wm transient $toplevel .[gred:getGrafcetName $c]
  wm protocol $toplevel WM_DELETE_WINDOW \
                        "EpsfCancel .[gred:getGrafcetName $c] $toplevel"
  
  
  # à déplacer dans pref ou ailleurs
  set gred(epsf,default,orient) Portrait
  set gred(epsf,default,mode) Color
  set gred(epsf,default,zone) All
  
# On crée les radiobuttons
  drawRadiobuttons [gred:getGrafcetName $c]
# On crée les boutons...
  drawButtons $toplevel
  # On établit les paramètres de la fenêtre:
  wm title $toplevel "Print box manager"
  wm withdraw $toplevel
  update idletasks
  # On centre la fenêtre
  set x [expr [winfo screenwidth $toplevel]/2 - [winfo reqwidth $toplevel]/2 \
      - [winfo vrootx [winfo parent $toplevel]]]
  set y [expr [winfo screenheight $toplevel]/2 - [winfo reqheight $toplevel]/2 \
      - [winfo vrooty [winfo parent $toplevel]]]
  wm geom $toplevel [winfo reqwidth $toplevel]x[winfo reqheight $toplevel]+$x+$y
  wm deiconify $toplevel
  grab $toplevel
  
  # ON attend que l'utilisateur click sur un des boutons de la fenêtre ou
  # close "sauvagement" la fenêtre...
  global waitButton
  vwait waitButton
  if {$waitButton == "ok"} {
    unset waitButton
  } else {
    unset waitButton
    EpsfCancel .[gred:getGrafcetName $c] $toplevel
    return
  }

  # mise a jour des variables "tmp" retournées
  set tmp(mode) [string tolower $tmp(mode)]
  
  switch -- $tmp(orient) {
    Portrait { set tmp(orient) false }
    Landscape { set tmp(orient) true }
    default { set tmp(orient) false }
  }
  
  switch -- $tmp(zone) {
    All {
      set grille_state [Grid_State $c]
      if {$tmp(printGrid) == 0 } {
        Grid_Hide $c
      }
      set scrollRegion [$c cget -scrollregion]
      set canvasWidth [lindex $scrollRegion 2]
      set canvasHeight [lindex $scrollRegion 3]
      set canvasWidth [winfo pixels $c $canvasWidth]
      set canvasHeight [winfo pixels $c $canvasHeight]
      set items [getItemFromGrafcet [gred:getGrafcetName $c] All]
      set tmp(canvasToPrint) $c
      set bbox [eval {$c bbox} $items]
      set x1 [lindex $bbox 0]
      set y1 [lindex $bbox 1]
      set x2 [lindex $bbox 2]
      set y2 [lindex $bbox 3]
      set tmp(width) [expr $x2-$x1+5]
      set tmp(height) [expr $y2-$y1+5]
      set tmp(x) [expr $x1-5]
      set tmp(y) [expr $y1-5]
    }
    Window {
      set scrollRegion [$c cget -scrollregion]
      set canvasWidth [lindex $scrollRegion 2]
      set canvasHeight [lindex $scrollRegion 3]
      set canvasWidth [winfo pixels $c $canvasWidth]
      set canvasHeight [winfo pixels $c $canvasHeight]
      set grille_state [Grid_State $c]
      if {$tmp(printGrid) == 0 } {
        Grid_Hide $c
      }
      # On récupère la bounding box qui contient tous les items a imprimer
      set items [getItemFromGrafcet [gred:getGrafcetName $c] All]
      set tmp(canvasToPrint) $c
      set geom [wm geometry .[gred:getGrafcetName $c] ]
      regsub -all {[x\+-]} $geom " " tmp(geometry)
      set tmp(width) [lindex $tmp(geometry) 0]
      set tmp(height) [lindex $tmp(geometry) 1]
      set tmp(x) [expr [lindex [$c xview] 0]*$canvasHeight]
      set tmp(y) [expr [lindex [$c yview] 0]*$canvasWidth]
    }
    Selection {
      set grille_state [Grid_State $c]
      if {$tmp(printGrid) == 0} {
          Grid_Hide $c
          set scrollRegion [$c cget -scrollregion]
          set canvasWidth [lindex $scrollRegion 2]
          set canvasHeight [lindex $scrollRegion 3]
          set canvasWidth [winfo pixels $c $canvasWidth]
          set canvasHeight [winfo pixels $c $canvasHeight]
          set tmp(canvasToPrint) [canvas $toplevel.printCanvas]
          $toplevel.printCanvas configure \
                                          -height $canvasHeight \
                                          -width $canvasWidth
          
          # On récupère la bounding box qui contient tous les items a imprimer
          set items [getItemFromGrafcet [gred:getGrafcetName $c] Selection]
          copyCanvas 0 $c $toplevel.printCanvas $items
      } else {
          # On récupère la bounding box qui contient tous les items a imprimer
          set items [getItemFromGrafcet [gred:getGrafcetName $c] Selection]
          set tmp(canvasToPrint) $c
      }
      set bbox [eval {$c bbox} $items]
      set x1 [lindex $bbox 0]
      set y1 [lindex $bbox 1]
      set x2 [lindex $bbox 2]
      set y2 [lindex $bbox 3]
      set tmp(width) [expr $x2-$x1+5]
      set tmp(height) [expr $y2-$y1+5]
      set tmp(x) [expr $x1-5]
      set tmp(y) [expr $y1-5]
    }
  }

  # Dans la mesure où une imprimante ne peut imprimer sur une page entière
  # On réduit la taille d'une page A4...
  set A4height [winfo pixels $c 283.0m]
  set A4width [winfo pixels $c 196.0m]
#   set A4height 283.0m
#   set A4width  196.0m
  if {$tmp(height) > $A4width} {
  }
  if {$tmp(orient)} {
      puts "Landscape"
      if {$tmp(height) > $A4width} {
          # On doit réduire la taille de la page en largeur pour que la figure
          # rentre sur la page
          set fit "-pageheight 196.0m"
      } else {
#           set height $A4width
#           set width  $A4height
          set fit "-pageheight $A4width -pagewidth $A4height"
      }
      set pagepos "-pagex 5m -pagey 5m -pageanchor nw"
  } else {
      puts "Portrait"
      if {$tmp(height) > $A4height} {
          # On doit réduire la taille de la page en largeur pour que la figure
          # rentre sur la page
          set fit "-pageheight 283.0m"
      } else {
#           set height $A4height
#           set width  $A4width
          set fit "-pageheight $A4height -pagewidth $A4width"
      }
      set pagepos "-pagex 3.2m -pagey 292.0m -pageanchor nw"
  }
  # Doit-on faire un fit sur la page (ici A4 ?)
  if {$tmp(fit) == 0} {
      set fit ""
      set pagepos ""
  }
  puts "fit==$fit"
  # création du postscript
  set result [eval {$tmp(canvasToPrint) postscript \
      -rotate $tmp(orient) \
      -colormode $tmp(mode) \
      -width $tmp(width) \
      -height $tmp(height) \
      -x $tmp(x) \
      -y $tmp(y) \
      -file $tmp(filename)} $fit $pagepos]
#       -pagex 0 \
#       -pagey 0 \

  unset tmp
  gred:status "Postscript file $tmp(filename) created"
  grab release $toplevel
  destroy $toplevel
  # On supprime la grille si besoin est avant d'imprimer le grafcet...
  if {$grille_state == 1} {
    Grid_Show $c
  } else {
    Grid_Hide $c
  }
  return $result
}
# getItemFromGrafcet -- Retourne la liste des items a imprimer dans le canvas...
# Retourne la liste des items a imprimer dans le canvas, dépends de
# l'implémentation de la séléction.
# C cette procédure qui empêche que le package soit globale et inclus dans pist.
proc getItemFromGrafcet {grafcet zone} {
    set c [gred:windowToCanvas .$grafcet]
    
    if { ($zone == "All") || (![Sel:exist $c])} {
        set oidsAImprimer [Obj:getAllSelectable $c]
    } else {
        set oidsAImprimer [Sel:getSelectedOids $c]
    }
    # On recupere tous les items a imprimer qui contiennent les oids de la liste
    # $oidsAImprimer
    set itemsAImprimer {}
    foreach oid $oidsAImprimer {
        foreach el [$c find withtag $oid] {
            lappend itemsAImprimer $el
        }
    }
    return $itemsAImprimer
}
# EpsfCancel -- Evénements à faire en cas de "CANCEL"
proc EpsfCancel {master toplevel} {
    destroy $toplevel.printCanvas
    destroy $toplevel
    grab release $master
}
# copyCanvas -- Copy certains éléments du canvas dans un autre canvas.
# Permet d'imprimer juste la selection.
proc copyCanvas {resize source destination litem} {
    $destination addtag toto all
    $destination delete toto
    
    foreach item $litem {
      set command "$destination create [$source type $item]\
                                       [$source coords $item]"
      set options [$source itemconfigure $item]
      foreach option $options {
          foreach value $option {
             if {($value == "-font") && $resize} {
                 set params [$source itemcget $item $value]
                 set size [lindex [$source itemcget $item $value] 1]
                 set newSize [expr int($size*double([$destination cget -width])\
                                   /double([$source cget -width]))]
                 set command "$command -font [list [list [lindex $params 0] \
                              $newSize [lindex $params 2]]]"
             } else {
                 if {[regexp -- "^-(\[^-\])+$" $value match]
                     && ([$source itemcget $item $value] != {})} {
                     set command "$command $value \
                                         [list [$source itemcget $item $value]]"
                 }
             }
          }
      }
      eval $command
    }
}

proc drawRadiobuttons {grafcetName} {
  global tmp gred
  upvar #0 grafcet.$grafcetName grafcet
  
  set f .print$grafcetName
  frame $f.orient -borderwidth 2
  set w $f.orient.label
  label $w -text "Orientation" \
          -width 20 -anchor w    
  pack $w -side left -fill x
  set w $f.orient.value1
  radiobutton $w \
            -text "Portrait" \
            -value "Portrait" \
            -variable tmp(orient)
  pack $w -side left
  set w $f.orient.value2
  radiobutton $w \
            -text "Landscape" \
            -value "Landscape" \
            -variable tmp(orient)
  pack $w -side left
  pack $f.orient -side top -fill x
  
  frame $f.colorMode -borderwidth 2
  set w $f.colorMode.label
  label $w -text "Color mode" \
          -width 20 -anchor w    
  pack $w -side left -fill x
  set w $f.colorMode.value1
  radiobutton $w \
            -text "Color" \
            -value "Color" \
            -variable tmp(mode)
  pack $w -side left
  set w $f.colorMode.value2
  radiobutton $w \
            -text "Gray" \
            -value "Gray" \
            -variable tmp(mode)
  pack $w -side left
  set w $f.colorMode.value3
  radiobutton $w \
            -text "Mono" \
            -value "Mono" \
            -variable tmp(mode)
  pack $w -side left
  pack $f.colorMode -side top -fill x

  frame $f.zone -borderwidth 2
  set w $f.zone.label
  label $w -text "Zone à imprimer" \
          -width 20 -anchor w    
  pack $w -side left -fill x
  set w $f.zone.value1
  radiobutton $w \
            -text "All" \
            -value "All" \
            -variable tmp(zone)
  pack $w -side left
  set w $f.zone.value2
  radiobutton $w \
            -text "Window" \
            -value "Window" \
            -variable tmp(zone)
  pack $w -side left
  set w $f.zone.value3
  radiobutton $w \
            -text "Selection" \
            -value "Selection" \
            -variable tmp(zone)
  pack $w -side left
  pack $f.zone -side top -fill x
  
  frame $f.fit -borderwidth 2
  set w $f.fit.label
  label $w -text "Fit on page ?" \
          -width 20 -anchor w    
  pack $w -side left -fill x
  set w $f.fit.value1
  radiobutton $w \
            -text "Yes" \
            -value 1 \
            -variable tmp(fit)
  pack $w -side left
  set w $f.fit.value2
  radiobutton $w \
            -text "No" \
            -value 0 \
            -variable tmp(fit)
  pack $w -side left
  pack $f.fit -side top -fill x
  
  frame $f.grid -borderwidth 2
  set w $f.grid.label
  label $w -text "Print grid ?" \
          -width 20 -anchor w    
  pack $w -side left -fill x
  set w $f.grid.value1
  radiobutton $w \
            -text "Yes" \
            -value 1 \
            -variable tmp(printGrid)
  pack $w -side left
  set w $f.grid.value2
  radiobutton $w \
            -text "No" \
            -value 0 \
            -variable tmp(printGrid)
  pack $w -side left
  pack $f.grid -side top -fill x
  
  frame $f.file -borderwidth 2
  set w $f.file.label
  label $w -text "Filename" \
          -width 20 -anchor w    
  pack $w -side left -fill x
  entry $f.file.ent -width 20 -textvariable tmp(filename)
  set types {{
    {{Poscript files}		{.ps}}
    {{All files}		*}
  }}
  button $f.file.but \
    -text "Browse ..." -height 1 -width 7\
    -command "fileDialog $f $f.file.ent \
              $types"
  pack $f.file.ent -side left -expand yes -fill x
  pack $f.file.but -side right
  pack  $f.file -side top -fill x
  
  # les variables utiles  
  foreach opt {orient mode zone} {
      set tmp($opt) $gred(epsf,default,$opt)
  }
  set tmp(printGrid) 0
  set tmp(fit) 0
  if {$tmp(filename) == ""} {
      if {$grafcet(filename) == ""} {
          set tmp(filename) [file join [file dirname [pwd]] Untitled.ps]
       } else {
          set tmp(filename) [file rootname $grafcet(filename)].ps
       }
  }
}

proc fileDialog {w ent types} {
# appele tk_getOpenFile ou tk_getSaveFile en fonction de operation
# et update le nom du fichier
    global tmp
    set file [tk_getSaveFile -filetypes $types -parent $w\
                             -initialdir [file dirname $tmp(filename)]\
                             -initialfile [file tail $tmp(filename)]]
    if [string compare $file ""] {
        $ent delete 0 end
        $ent insert 0 $file
        $ent xview end
    }
} ; # end proc fileDialog

proc drawButtons {f} {
  global gred
  set w $f.buttons
    
  frame $w -relief flat -borderwidth 1
  pack $w -side bottom -fill x 
  # Les bouttons ne seront pas selectionnables pas <Tab> 
  # et <Shift-Tab>
  button $w.cancel -text "Cancel" \
      -padx 5m  -pady 2m -takefocus 0 \
      -command "set waitButton cancel"
              
  frame $w.ok -borderwidth 1m -relief sunken
  button $w.ok.b -text "Ok" \
      -padx 5m  -pady 2m -takefocus 0 \
      -command "set waitButton ok"
  
  pack $w.ok.b
  pack $w.ok $w.cancel -side right 
    
  # Some bindings
  # La commande suivante :
  # bind Prompt <$Prompt(Meta)-c> "PromptInvokeButton $w.cancel"
  # ne permet pas de faire fonctionner la touche Escape si par exemple on est
  # dans une entry... C ennuyeux. Mais les bindings suivant fonctionnent
  # pour une telle que $f!=. 
  bind $f <$gred(Meta)-c> "set Prompt(button) cancel"
  bind $f <Escape> "set Prompt(button) cancel"
  bind $f <$gred(Meta)-o> "set Prompt(button) ok"
  bind $f <Return> "set Prompt(button) ok"
  
  # On selectionne la valeur d'une entry lors que l'entry est selectionnee
  bind PromptEntry <FocusIn> \
             "%W select clear
              %W select range 0 end"
  pack $f.buttons
}