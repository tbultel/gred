########################################################################
# Ce fichier contient des procédures facilitant la maintenance de cette
# application (réservée à l'administrateur de celle-ci)
# $Id: admin.tcl,v 1.2 1997/10/14 06:18:06 diam Exp $
########################################################################

########################################################################
# gred:edit -- edite de fichier passé en parametre
# 
# Ne marche que sous UNIX pour l'instant !!
# 
proc gred:edit {fileName} {
    global env
    if {[info exists env(EDITOR)]} {
       exec $env(EDITOR) $fileName &
    } else {
       exec stead $fileName &
    }
}

proc findProc {} {
    global auto_index
    set procName [selection get]
    gred:status all "Recherche de la procédure $procName..."
    catch {set file [lindex $auto_index($procName) 1]}
    if ![info exists file] {
         gred:status all "Impossible de trouver $procName..."
         return
    }
    exec stead $file -command "te:tcl:cmd:go_to_proc $procName" &
}

########################################################################
# gred:mkmenu:admin --
# 
# 
# 
proc gred:mkmenu:admin {w} {
global gred

    set frame $w.menubar

    set name $frame.admin
    set menuName $name.menu
    set mb [menubutton $name -text Administrator -menu $menuName]
    pack $mb -side left
    set menu [menu $menuName -tearoff 0]
    
    $menu add command -label "Trouver la procédure..."\
                   -command {findProc}
    
    $menu add separator
    
    $menu add command -label "Afficher la version..."\
                   -command {showVersion}
    
    $menu add separator

    $menu add command -label "Réindexer l'index de gred" \
              -command [list auto_mkindex [file join $gred(setup) lib]]
    
    $menu add command -label "Editer le fichier tclIndex de gred" \
              -command {gred:edit [file join $gred(setup) lib tclIndex ]}
    
    $menu add separator
    
    $menu add command -label "Regénérer les fichiers htcl" \
                    -command {gred:updateDoc}
                      
    $menu add separator
    
    $menu add command -label "Réindexer les packages de pist"\
                   -command [list mkindex [file join $gred(pistsetup) lib *]]
    
    $menu add separator
    
    $menu add command -label "Editer gred" \
              -command {gred:edit $gred(exe)}
    
    $menu add separator
    
    # On édite les fichiers accessibles par l'auto_path (dans l'ordre)
    global auto_path
    set i 0
    foreach dir $auto_path {
        catch {MakeMenuCascadeFromDirectory $menu $menu.sub[incr i]\
                                                  [file join $dir *]}
    }
    
    $menu add separator
    
    set dirsListToEdit [list $gred(setup) \
                             [file join $gred(setup) bin] \
                             [file join $gred(setup) lib] \
                             [file join $gred(setup) samples] \
                             [file join $gred(setup) doc] \
                        ]
    
    foreach dir $dirsListToEdit {
        catch {MakeMenuCascadeFromDirectory $menu $menu.sub[incr i]\
                                                  [file join $dir *]}
    }
    
    $menu add separator
    
    $menu add command -label "Editer le \"localfilerc\" de gred"  \
              -command {gred:edit $gred(setup,localfilerc) }
              
    catch {MakeMenuCascadeFromDirectory $menu $menu.sub[incr i]\
                                       [file join $gred(setup) local *]}
}

proc gred:updateDoc {} {
    global gred 
    
    gred:status all "Recompilation des fichiers HTML en cours..."
    set dirOri [pwd]
    cd [file join $gred(setup) doc]
#     exec [file join $gred(pistsetup) lib hview-0.1 compile_html2htcl] \
#           -directory [file join $gred(setup) doc] &
          
    html2htcl  -directory [file join $gred(setup) doc]
    cd $dirOri
}

proc MakeMenuCascadeFromDirectory {menu subMenu pattern} {
    global env
    if ![info exist env(EDITOR)] {set env(EDITOR) stead}
    
    set firstTime 1
    set files [lsort [glob -nocomplain $pattern] ]
    foreach f $files  {
    
        if {$firstTime} {
            set label "$env(EDITOR) [file dirname $f]/..."
            set label "$env(EDITOR) $pattern..."
            menu $subMenu -tearoff 0
            $menu add cascade -label $pattern -menu $subMenu
            set firstTime 0
        }
        
        if [file isdirectory $f] continue
        $subMenu add command -label [file tail $f] \
                          -command "exec $env(EDITOR) $f &"
    } 
}
