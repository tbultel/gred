

########################################################################
# MODIFICATIONS : $Id: main.tcl,v 1.2 1997/10/14 06:42:51 diam Exp $
# 
# le 14/10/97 (diam) : bug dans nom du gredrc généré "gredrc["
# le 10 Feb 1997 par CARQUEIJAL David : ajout d'une variable 
#  gred(grafcets) contenant la liste des grafcets en cours d'édition,
#  chaque élement de la liste contient le nom d'un tableau visible au
#  niveau #0. Le premier élement de la liste correspond au grafcet
#  courant (ie celui en cours d'édition).
# le 11 Feb 1997 par CARQUEIJAL David : ajout d'une procédure 
#  gred:traceDirty permettant de lier la variable globale gred(isDirty)
#  avec la variable isDirty du grafcet courant. C utile pour 
#  gérer facilement le checkbutton indiquant si le grafcet courant à
#  été modifié.
# le 11 Feb 1997 par CARQUEIJAL David : Mise en place et utilisation
#  cohérente du flag indiquant si le fichier à été modifié.
# 
########################################################################

########################################################################
# gred:init -- initialisation des constantes, préférences ...
# 
# N'est normalement exécuté qu'une seule fois
# Par rapport a la procedure grep:setup : complete les variable de 
# configuration de la forme :
#   - gred(setup,localfilerc) : fichier de personnalisation au niveau site
#   - gred(setup,userlibs) : répertoire utilisateur 
# 
proc gred:init {args} {
global gred auto_path env tcl_platform


    # # # report -t "début de gred:init"   
    
    set gred(date) [clock format [clock seconds] -format {%d/%m/%y}]

    ####################################################################
    # on termine le positionnement des globales d'environnement

    set gred(setup,localfilerc)  \
                [file join $gred(setup) local localgredrc]

    # On ajoute la librairie  éventuelle local au site, par exemple
    # définissant les outils vhdl utilisés pour la compilation....
    set auto_path   [linsert $auto_path 0 [file join $gred(setup) local]]


    # On définit le répertoire utilisateur 
    # gred(setup,userlibs) est de la forme ~/pist/ ; chaque appli
    # (gred,...) créera son propre sous-répertoire ~/pist/gred/...
    switch $tcl_platform(platform) {
        macintosh  { set pref_root_folder $env(PREF_FOLDER)  }
        windows    { set pref_root_folder $env(WINDIR)       }
        default    { set pref_root_folder $env(HOME)         }
    }

    # On ajoute éventuellement la librairie personnelle de l'utilisateur :
    # Ceci permet d'écraser ou de personnaliser de comportement de l'appli.
    set gred(setup,userlibs) [file join $pref_root_folder pist]
    setup:insertLib -sourceindex $gred(setup,userlibs)
    set gred(setup,userfilerc) \
               [file join $gred(setup,userlibs) gred gredrc]
    ####################################################################
    

    # liste des fenetres d'edition (windows) en cours : 
    # idem que listes de grafcet (pour l'instant)
    set gred(grafcets) {}
    # identificateur unique de grafcet/window
    set gred(grafcetUID) 0
    # Identification unique utilisable pour la creation des widgets... :
    set gred(uid) 0
    
    gred:initPrefs
    
    Grid_Setup -pixel $gred(grid) -color $gred(grid,color)

    set gred(initialised) 1
    
    Clipboard:clear
    
    ###################################################################
    # DAVID: PROVISOIRE !!!!!!!! A CHANGER !!!!!!!!!!!
    auto_load Etape:create
    auto_load Trans:create
    auto_load Link:create
    ###################################################################
}

# gred:delete --
# argument : liste de nom de windows
# 
# Appelée quand on veut fermer une fenetre 
#   => faire confirmer si pas clean 
# 
proc gred:delete {grafcet} {
    set w .$grafcet
#     MenuDestroyInFrame $w.menubar
# puts "Closing windows: $w !"
    destroy $w
}

## gred:setCurrentGrafcet --
# argument : liste de noms de windows
# 
proc gred:setCurrentGrafcet {newgrafcet} {
global gred    

   if {[lsearch $gred(grafcets) $newgrafcet] != -1} {
      set gred(grafcetCourant) $newgrafcet
   }
   return $gred(grafcetCourant)
}

## gred:getCurrentGrafcet -- return le grafcet courant
# argument : liste de nom de windows
# 
proc gred:getCurrentGrafcet {} {
global gred    

   return $gred(grafcetCourant)
}
## g -- alias à gred:getCurrentGrafcet (TODO : en faire le "document courant")
# 
# 
proc g {args} {
    uplevel 1 gred:getCurrentGrafcet $args
}
########################################################################
# gred:new --
# 
# 
# 
proc gred:new {args} {
global gred auto_path env

    # Si premiere execution : on initialise l'éditeur
    if ![info exists gred(initialised)] {gred:init}

    # name induira aussi le nom de la toplevel (.grafcet1, .grafcet2)
    set name grafcet[incr gred(grafcetUID)]
    
    lappend gred(grafcets) $name
    
    gred:setCurrentGrafcet    $name
    upvar #0 grafcet.$name grafcet
    
    # Analyse des arguments :
    set gred(mode)     AUTO
    set gred(eval)     ""
    set gred(source)   ""
    set grafcet(filename) ""
    
    while {[llength $args]} {
       switch -glob -- [lindex $args 0] {
           --      {
                    set args [lreplace $args 0 0]
                    break
           }
           -mode   {
                    set gred(mode) [lindex $args 1]
                    set args [lreplace $args 0 1]
                    continue
           }
           -e       -
           -eval   {
                    set gred(eval) [lindex $args 1]
                    set args [lreplace $args 0 1]
                    continue
           }
           -s       -
           -source { 
                    set gred(source) [lindex $args 1]
                    set args [lreplace $args 0 1]
                    continue
           }
           -*      { puts stdout "unknow option [lindex $args 0]"
                     gred:usage
                     exit 1
           }
           default { break  ;# no more options}
        }
    }
    if {[llength $args] >= 1 } {
       set grafcet(filename) [lvarpop args]
       # create another interpreter for any more file to edit
       foreach arg $args {
          set cmd [list gred:new -mode $gred(mode) \
                    -eval $gred(eval) \
                    -source $gred(source) \
                    --  $arg]
          # report $cmd
          eval $cmd
       }
    }

    ####################################################################
    # on source le fichier utilisateur du répertoire courant s'il existe
    set pwdfile [file join [pwd] [file tail $gred(setup,userfilerc)]]
    if [string length [glob -nocomplain $pwdfile]] {
      if {[file readable [glob -nocomplain $pwdfile]]} {
        uplevel #0 source [glob -nocomplain $pwdfile]
      }
    } 

    ####################################################################
    # on définit la toplevel correspondant a cette instance d'éditeur 
    # de grafcet :
    
    set w .$name
    gred:buildAppli $w

    # etat "sauvegardé" ou non du fichier en cours d'édition :
    # On lie la variable $gred(grafcetCourant) avec grafcet(isDirty)
#     gred:traceDirty
    gred:markClean $w
    
    # Ligne suivante a changer ?
    set grafcet(untitled) $gred(untitled)
    
    # execution de la procédure gred:userhook si elle existe.
    if [string match [info proc gred:userhook] "gred:userhook"] {
        if [catch gred:userhook err] {
           gred:status $w "Error: $err"
        }
    }
    
    # post execution des options -eval et -source
    if {![string match "" $gred(eval)]} {
        if [catch {eval $gred(eval)} err] {
           gred:status $w "Error: $err"
        }
    }
    if {![string match "" $gred(source)]} {
        if [catch {source $gred(eval)} err] {
           gred:status $w "Error: $err"
        }
    }
    # Chargement d'un fichier Oui/Non ?
    if {$grafcet(filename) != ""} {
        # Le fichier est-il lisible ?
        if {![file readable $grafcet(filename)]} {
            gred:status $w "File $grafcet(filename) is unreadable !"
            set grafcet(filename) ""
        } else {
            # On charge le fichier passé en paramètre
            gred:file:load [gred:windowToCanvas $w] $grafcet(filename)
        }
    }
    
    # On mémorise les infos du undo/redo
    undo_Save $w
    
    # binding de la classe "Grafcet" "LinkEdit" all 
    gred:initBindings $w
    
    gred:updateTitle $w
    
    # # report -t "Fin de : gred:start"
    return $w
} ;#endproc gred:new

###################################################################
      
########################################################################
# gred:usage --
# 
# 
# 
proc gred:usage {} {
    set usage {\
    syntaxe :
        gred [-option optVal ...] [--] [fileName [fileName..]]
        options autorisées :
           -setup <GRED_SETUP>
               répertoire d'installation de l'application gred
           -pist_setup <PIST_SETUP>
               répertoire d'installation de la librairie pist
           -mode   : <MODE> (defaut : "AUTO" pour automatique)
           -e      : <TCL_CODE>
           -eval   : <TCL_CODE>
           -s      : <TCL_FILE>
           -source : <TCL_FILE>
           --      : fin des options
    exemples :
           >gred <file1>
           >gred -gred_setup ../.. -pist_setup ~/mypist2.4 \
                 -defaultexportformat vhdl  <file1> <file2> ...
    }
    puts stderr $usage
}

########################################################################
# gred:buildAppli --
# 
# 
# 
proc gred:buildAppli {w} {
  # set font "-*-courier-bold-r-normal-*-12-*-*-*-*-*-iso8859-*"
  global gred
  upvar #0 grafcet.[gred:getGrafcetName $w] grafcet
  
  toplevel $w -class Gred
  wm protocol $w WM_DELETE_WINDOW "gred:cmd:close $w"
  
  wm minsize $w 1 1
  
  # Construction des menus :
  grid [gred:mkmenus $w] -column 0  -row 0 \
       -sticky we  -padx 1  -pady 1 
  grid columnconfigure $w 0 -weight 1

  # Regle de separation :
  grid [frame $w.rule0  -borderwidth 2 -relief raised]\
       -sticky we -column 0 -row 1

  # La ligne d'information (messages) :
  entry $w.message   \
             -relief flat \
             -state disabled \
             -textvariable gred.[gred:getGrafcetName $w](status)

  grid $w.message   -column 0  -row 2  -sticky we


  # La ligne de commande :
  tk_CmdEntrySetResultProc "\{gred:status $w\}"
  set entry [tk_CmdEntry $w.cmd]
  grid $w.cmd      -column 0 -row 3 -sticky we
  
  
  # create canvas widget with scrollbars
  set canvas [tkCanvasScrolledCanvas $w.draw]
    
  # On rend le canvas créé sensible à l'étiquette de binding "Grafcet"
  bindtags $canvas [list $canvas Grafcet Canvas $w all]
  grid $w.draw -column 0 -row 4 -sticky nsew  -padx 1  -pady 1
  grid  rowconfigure $w 4 -weight 1

  # create buttons frame number of lines, clean gred, ...
  frame $w.buttons
  grid $w.buttons -column 0  -row 5 -sticky we
  
  # have an indicator of modified status using tkText($txt,modified)
  image create bitmap modflag -data {
    #define modflag_width 15
    #define modflag_height 15
    static char modflag_bits[] = {
      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF}; 
  }
  # checkbutton .buttons.modflag -state disabled -borderwidth 0 \
  #   -selectimage modflag -image modflag -indicatoron 0 \
  #   -width 5m  -variable gred(isDirty)
  checkbutton $w.buttons.modflag -state disabled -borderwidth 0 \
    -relief sunken \
    -width 2  -variable gred${w}(isDirty)


  grid $w.buttons.modflag   \
       -sticky w  -padx 1  -pady 1
  grid columnconfigure $w.buttons 0 -weight 1
    
  # quelques bindings SPECIFIQUES a cette fenetre :

  # Gestion du changement de focus entre le canvas et la ligne 
  # de commande par Tabulation
  bind $canvas <Tab> "focus $entry ;break"
  bind $entry  <Tab> "focus $canvas;break"
  
  grafcet:init [gred:getGrafcetName $w]
  
  $canvas configure -scrollregion \
            [ list 0 0  $gred(canvas,width) $gred(canvas,height) ]
  Grid_Show [gred:windowToCanvas $w]
  
  selection handle $canvas [list Sel:getX11 $canvas] 
}

# Affiche le curseur "tcross" quand on quitte la selection (:-)
# proc settcrossCursor {W x y} {
#     set oid [Obj:getPointedOid $W $x $y]
#     set items [$W find closest $x $y 10 select]
#                                # [expr $x+5] [expr $y+5]]
#     puts $items
#     foreach item $items {
#       set tags [$W gettags $item]
#       if {[lsearch $tags "selectBox"] >= 1} {
#         set oid $item
#         puts "$oid \[$tags\]"
#         break
#       }
#     }
#     set coords [$W coords $oid]
#     set x1 [lindex $coords 0]
#     set y1 [lindex $coords 1]
#     set x2 [lindex $coords 2]
#     set y2 [lindex $coords 3]
#     if {$x >= $x1
#         && $x <=$x2
#         && $y >= $y1
#         && $y <= $y2} {
#       puts AAA
#     } else {
#       puts BBB
#       $W config -cursor tcross
#     }
# }

########################################################################
# gred:markDirty --
# 
proc gred:markDirty {w} {
    global gred$w
    set gred${w}(isDirty) 1
    gred:updateTitle $w
}

########################################################################
# gred:markClean --
# 
proc gred:markClean {w} {
    global gred$w
    set gred${w}(isDirty) 0
    gred:updateTitle $w
}

########################################################################
# gred:isClean --
# 
proc gred:isClean {w} {
    upvar #0 gred$w gred
    return [expr !$gred(isDirty)]
}   



########################################################################
# gred:updateTitle --
# 
# 
# 
proc gred:updateTitle {w} {
    global gred
    upvar #0 grafcet${w} grafcet

    regexp "^grafcet(\[0-9\]+)$" [gred:getGrafcetName $w] match Id
    set title "Gred #$Id"
    
    if {"x$grafcet(filename)" == "x"} {
        set file $gred(untitled)
    } else {
        set file $grafcet(filename)
    }
    
    if ![gred:isClean $w] {
        set title "$title $file !"
    } else {
        set title "$title $file"
    }
    
    # On update le nom que si nécessaire... Pour éviter les flashs désagréables
    # et inutiles du windows manager.
    set realTitle [wm title $w]
    if [string compare $realTitle $title] {
        wm title $w $title
        wm iconname $w $title
    }
} ;# endproc gred:updateTitle

########################################################################
# gred:updateCanvasSize --
# 
# 
# 
proc gred:updateCanvasSize {w} {
    global gred
    upvar #0 grafcet${w} grafcet

    set c [gred:windowToCanvas $w]

    $c configure -scrollregion \
            [ list 0 0  $gred(canvas,width) $gred(canvas,height) ]
    Grid_ToggleShow $c
    Grid_ToggleShow $c

} ;# endproc gred:updateCanvasSize

########################################################################
# gred:status --
# 
# 
# 
proc gred:status {c args} {

    if {$c != "all"} {
        upvar #0 gred.[gred:getGrafcetName $c] gred
        # a faire : gérer fichier log...
        set args [join $args]
    
        set gred(status) $args
        append gred(statusLog) $args\n
    } else {
        global gred
        set grafcets [lsort $gred(grafcets)]
        foreach grafcet $grafcets {
            eval gred:status [gred:windowToCanvas .$grafcet] $args
        }
    }
    
#     if {![catch {
#         # Le widget text gred(status,text) peut ne pas etre encore crÈÈ !
#         $gred(status,text) configure -state normal
#         update idletask
#         $gred(status,text) delete 0.0 end
#         $gred(status,text) insert 0.0 $args
#         $gred(status,text) configure -state disabled
#         update idletask
#     }]
#     } then {
#        puts stdout $args
#     }
}
#./
