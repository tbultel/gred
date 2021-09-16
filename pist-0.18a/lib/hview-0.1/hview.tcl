package provide hview 0.1


foreach file {hviewObject.tcl hviewTkhtml.tcl} {
    uplevel #0 [list source [file join [file dirname [info script]] $file]]
}

########################################################################
# htmlView_Box --
# Cree une fenetre d'aide si elle n'existe pas, sinon la fait apparaitre
########################################################################
proc hView_Box {w args} {
    if [winfo exists $w] {
        wm deiconify $w
        raise $w
    } else {
        eval [list hView_Box2] [linsert $args 0 $w]
        $w centerWindow
    }
} ; # end proc htmlView_Box

########################################################################
# Cree une fenetre permettant de visualiser du HTML, cela permet en autre
# d'afficher une (jolie !) aide.
# UTILISATION : 
#     htmlView_Box2 .help -topics $help_topics \
#         -helpdir $filedir \
#         -cacheDir /usr/lei/mos4/carqueij_work/LIBS/AFFICHE_HTML/TMP/ \
#         -tmpFile /usr/lei/mos4/carqueij_work/LIBS/AFFICHE_HTML/TMP/temp
# PARAMETRES D'ENTREES :
#     -helpdir <helpdir> : repertoire contenant le fichier html
#     -cacheDir <cacheDir> : repertoire ou doit se trouver le cache (pour
#       lire et ecrire des fichiers de cache
#     -tmpFile <tmpFile> : Prefixe des fichiers temporaire necessaire
#       la gestion des caches
#     -width <width> et -height <height> taille de la fenetre affichant 
#       le HTML
########################################################################
dialog hView_Box2 {
    # Liste des fichiers HTML a ouvrir
    param topics {}
    # Taille de la fenetre
    param width 12
    param height 25
    # Repertoire contenant les fichier HTML
    param helpdir .
    member initialDir .
    # Autoriser l'affichage de ce que g nomme la "feedBack Bar"
    member feedBar 1
    # Repertoire de cache
    # Creer TMP si il n'existe pas ?
    param cacheDir [file join [pwd] TMP]
    # Repertoire temporaire (pour les fichiers temporaire...)
    param tmpFile [file join [pwd] TMP]
    # Variable propre a la fenetre creer, permettant de gerer
    # les commande BACK et FORWARD
    member history {}
    member history_ndx -1
    member history_len 0
    member addHistory 0
    member currentPage ""
    # Permet de savoir si on est en train d'afficher un fichier HTML
    member rendering 0
    # Doit on effacer la cache en sortant du programme ?
    member deleteCache 1
    # Numero d'Index des fichiers de cache dans le fichier 
    # d'index  "Index"
    member cacheIdx 0
    # Liste des fichiers de cache crees pendant la session
    # member listOf_tcthtmlFile ""
    # variables utiles pour gerer la barre de progression
    member steps 10
    member barwidth 470
    member barheight 10
    member barcolor DodgerBlue
    member step 0
    # variables utiles pour gerer la barre de redimensionnement
    member sash-hh 0
    member sash-beg 0
    member sash-ppl 0
    member sash-min 0
    member sash-max 0

    ####################################################################
    # METHOD create
    # Method permettant de creer la fenetre d'help
    # EFFET DE BORD : Actualise la variable cacheIdx, en fonction du fichier 
    # Index (si il existe)
    method create {} {
        set slot(initialDir) $slot(helpdir)
        # Initialise the delete protocol
        wm protocol $self WM_DELETE_WINDOW \
                "$self delete_file ; destroy $self"
                
        # Initialise the menu
        frame $self.menu -relief raised -bd 2
        menubutton $self.menu.topics -text "Topics" -underline 0 \
            -menu $self.menu.topics.m
        pack $self.menu.topics -in $self.menu -side left
        set m [menu $self.menu.topics.m]
        menubutton $self.menu.navigate -text "Navigate" -underline 0 \
            -menu $self.menu.navigate.m
        pack $self.menu.navigate -in $self.menu -side left
        set m [menu $self.menu.navigate.m]
        $m add command -label "Forward" -underline 0 -state disabled \
            -command "$self forward" -accelerator f
        $m add command -label "Back" -underline 0 -state disabled \
            -command "$self back" -accelerator b
        $m add cascade -label "Go" -underline 0 -menu $m.go
        menu $m.go -postcommand "$self fill_go_menu"
        menubutton $self.menu.option -text "Option" -underline 0 \
            -menu $self.menu.option.m
        set m [menu $self.menu.option.m]
        $m add checkbutton -variable [object_slotname deleteCache]\
                -label "Delete cache ?" \
                -offvalue 0 \
                -onvalue 1
        pack $self.menu.option -in $self.menu -side left
        
        # Creating the scrollbar and the text widget
        frame $self.text -bd 2 -relief raised
        scrollbar $self.text.sb -command "$self.text.t yview" -width 10
        text $self.text.t -relief groove -bd 2 -yscroll "$self.text.sb set" \
            -wrap word -setgrid 1
        
        # Creating the second scrollbar and the text widget
        frame $self.text2 -bd 2 -relief raised
        scrollbar $self.text2.sb -command "$self.text2.t yview" -width 10
        text $self.text2.t -relief groove -bd 2 -yscroll "$self.text2.sb set" \
            -wrap word -setgrid 1 -height 8
        
        # Creating the resize bar
        frame $self.sep -relief flat -height 5 -bd 1 -cursor hand2
        frame $self.line -relief sunken -height 2 -bd 1 
        
        # Bindings to resize the 2 texts widgets
        bind $self.sep <ButtonPress-1> \
                         "$self sash-begin"
        bind $self.sep <B1-Motion> "$self sash-draw %Y"
        bind $self.sep <ButtonRelease-1> "$self sash-split-end"

        # Creating feed back bar
        frame $self.feedback
        $self.feedback config -bd 2 -relief ridge
        frame $self.feedback.spacer
        frame $self.feedback.framebar
        frame $self.feedback.framebar.bar -relief raised \
                                          -bd 2 -highlightthickness 0
        label $self.feedback.percentage -text 0% -height 0
        $self.feedback.framebar.bar config -height $slot(barheight)\
                                           -bg $slot(barcolor)
        if {$slot(feedBar)} {
            pack $self.feedback.percentage -side left \
                -fill x -padx 1 -pady 1
            pack $self.feedback.framebar -side left \
                -padx 1 -fill x
            pack $self.feedback.framebar.bar -side left \
                -fill x
            pack $self.feedback.spacer -side left -padx 1 \
                -fill x -anchor w
            pack $self.feedback -in $self -side bottom \
                -fill x
        }
        # end Creation feedback bar
        
        pack $self.text.t -in $self.text -side left -expand yes -fill both
        pack $self.text.sb -in $self.text -side right -fill y
        pack $self.text2.t -in $self.text2 -side left -expand yes -fill both
        pack $self.text2.sb -in $self.text2 -side right -fill y
        pack $self.menu -in $self -side top -fill x
        pack $self.text -in $self -side bottom -fill both -expand yes
        place configure $self.line -in $self.sep -relx 0.03 -rely 0.4 \
           -relwidth 0.95
        raise $self.line
        pack $self.sep -in $self -side bottom -fill x
        pack $self.text2 -in $self -side bottom -fill both -expand yes

        bind $self <Key-f> "$self forward"
        bind $self <Key-b> "$self back"
        bind $self <Alt-Right> "$self forward"
        bind $self <Alt-Left> "$self back"
        bind $self <Key-space> "$self page_forward"
        bind $self <Key-Next> "$self page_forward"
        bind $self <Key-BackSpace> "$self page_back"
        bind $self <Key-Prior> "$self page_back"
        bind $self <Key-Delete> "$self page_back"
        bind $self <Key-Down> "$self line_forward"
        bind $self <Key-Up> "$self line_back"
        bind $self <Control-c> "$self delete_file ; destroy $self"
        bind $self <Escape> "$self delete_file ; destroy $self"
        bind $self <Meta-q> "$self delete_file ; destroy $self"
        # On actualise la variable slot(cacheIdx)
        set indexFile [file join $slot(cacheDir) Index]
        if [file exists $indexFile] {
            source $indexFile
        } else {
            set slot(cacheIdx) 0
        }
    }
    ####################################################################
    # METHOD centerWindow
    # Permet de centrer la fenetre
    method centerWindow {} {
        wm withdraw $self
        update idletasks
        set w [winfo reqwidth $self]
        set h [winfo reqheight $self]
        set sh [winfo screenheight $self]
        set sw [winfo screenwidth $self]
        wm geometry $self +[expr {($sw-$w)/2}]+[expr {($sh-$h)/2}]
        wm deiconify $self
    }
    ####################################################################
    # METHOD open
    # Method permettant d'ouvrir un fichier HTML a l'aide du browser de fichier
    method open {} {
        if {$slot(rendering)} return
        #   Type names		Extension(s)	Mac File Type(s)
        set types {
            {"HTML files"    "*.html *.htm"    {HTML}}
            {"All files"     *}
        }
        set file [tk_getOpenFile -filetypes $types -parent $self\
                                 -initialdir $slot(helpdir)]
        if {$file != ""} {
            $self follow_link $file
        }
    }
    ####################################################################
    # METHOD generate
    # Method permettant de generer, un fichier de cache pour la page courante
    method generate {} {
        global tkhtml_priv
        # On ecrit le fichier cache (ie le fichier htcl) !
        incr slot(cacheIdx)
        set fichier [file join $slot(cacheDir) $slot(cacheIdx).htcl]
        set file [open $fichier w+]
        # On recopie le fichier contenant le texte du fichier HTML
        # Comme etant la premiere partie du ficheir de cache
        set f [open [file join $slot(tmpFile) 1.htcl] r]
        set txt [read $f]
        puts $file $txt
        close $f
        file delete -force [file join $slot(tmpFile) 1.htcl]
        # On recopie le fichier contenant le texte du fichier HTML
        # Comme etant la premiere partie du fichier de cache
        set f [open [file join $slot(tmpFile) 1bis.htcl] r]
        set txt [read $f]
        puts $file $txt
        close $f
        $tkhtml_priv(w) configure -state disabled
        $tkhtml_priv(w2) configure -state disabled
        file delete -force [file join $slot(tmpFile) 1bis.htcl]
        # On recopie le fichier contenant la definition des tags
        # a la suite du fichier de cache
        set f [open [file join $slot(tmpFile) 2.htcl] r]
        set txt [read $f]
        puts $file $txt
        close $f
        puts $file "\$widget1 configure -state disabled"
        puts $file "\$widget2 configure -state disabled"
        file delete -force [file join $slot(tmpFile) 2.htcl]
        # On recopie le fichier contenant l'emplacement des tags
        # a la suite du fichier de cache
        set f [open [file join $slot(tmpFile) 3.htcl] r]
        set txt [read $f]
        puts $file $txt
        close $f
        file delete -force [file join $slot(tmpFile) 3.htcl]
        close $file
        unset txt
#         lappend slot(listOf_tcthtmlFile) $fichier
        
        # On update le fichier d'"Index" des fichiers de cache
        # Le fichier d'Index contient la correspondance entre les fichers
        # de cache et les fichiers HTML
        set IndexTemp [file join $slot(cacheDir) IndexTemp]
        set Index [file join $slot(cacheDir) Index]
        set newIndex 0
        if [file exists $IndexTemp] {
            file delete $IndexTemp
        }
        if [file exists $Index] {
            file copy $Index $IndexTemp
            file delete $Index
            set f [open $IndexTemp r]
            set f2 [open $Index w]
            set txt [read $f]
            puts $f2 $txt
            set newIndex 1
        } else {
            set f2 [open $Index w]
        }
        puts $f2 "array set CacheInfo {$slot(currentPage) $slot(cacheIdx)}"
        puts $f2 "set slot(cacheIdx) $slot(cacheIdx)"
        close $f2
        if {$newIndex == 1} {
            close $f
            file delete $f
        }
    }
    ####################################################################
    # METHOD delete_file
    # permettant de detruire les fichiers de cache a la fermeture de la
    # fenetre d'help
    method delete_file {} {
    # Pour effacer la cache si necessaire (si l'utilisateur le desire...)
        if {$slot(deleteCache) == 1} {
            foreach el [glob -nocomplain [file join $slot(cacheDir) *]] {
                puts "deleting $el"
                file delete -force $el
            }
        }
    }
    ####################################################################
    # METHOD open_topic
    # permet d'ouvrir un topic a partir du menu
    method open_topic {topic} {
        set slot(helpdir) $slot(initialDir)
        eval [list $self follow_link $topic]
    }
    ####################################################################
    # METHOD reconfig
    # permet de reconfigurer la fenetre d'help
    method reconfig {} {
        set m $self.menu.topics.m
        $m delete 0 last
        foreach topic $slot(topics) {
            $m add radiobutton -variable [object_slotname topic] \
                -value $topic \
                -label $topic \
                -command [list $self open_topic $topic]
        }
#         $m add separator
#         $m add command -label "Open File" -underline 0 \
#             -command "$self open" -accelerator o
        $m add separator
        $m add command -label "Close Help" -underline 0 \
            -command "$self delete_file ; destroy $self"
        $self.text.t config -width $slot(width) -height $slot(height)
    }
    ####################################################################
    # METHOD show_text
    # permet d'afficher une chaine HTML. Ne cree pas de cache associe.
    method show_text {text} {
        wm title $self "Help"
        set slot(rendering) 1
#         puts "Displaying string..."
        # On parse la nouvelle page
        # a mettre autre part le if et les 2 lignes suivantes...
        set slot(steps) [string length $text]
        set slot(len) [string length $text]
        set slot(remaining) $slot(len)
        tkhtml_set_render_hook "$self update_feedback"
        tkhtml_set_command_href "$self follow_link"
        tkhtml_set_command_header "$self searchTag"
        tkhtml_set_image_hook "$self image_create"
        tkhtml_set_tmpFile $slot(tmpFile)
        tkhtml_render $self.text.t $self.text2.t $text
        $self reset_feedbar
        # Updating window title, if exists.
        if {[tkhtml_title] != ""} {
            wm title $self [tkhtml_title]
        }
        set slot(rendering) 0
    }
    ####################################################################
    # METHOD read_topic
    # permet d'ouvrir un fichier HTML. Si le cache existe, on execute le cache.
    # sinon on parse le fichier HTML
    # Principe de recherche du cache : 1) On examine le fichier Index pour voir 
    # si il existe un cache pour topic.  2) On regarde si il exite un fichier
    # de cache dans le meme repertoire que le fichier topic
    method read_topic {topic} {
        global tkhtml_priv
        set tkhtml_priv(rendering) 0
        tkhtml_set_command_href "$self follow_link"
        tkhtml_set_command_header "$self searchTag"
        # topic=/usr/lei/a.html
        wm title $self "Help: $topic"
        set nextPage $topic
        set indexFile [file join $slot(cacheDir) Index]
        
        # on charge le fichier "Index" si il existe et on recupere le fichier
        # htcl correspondant
        if [file exists $indexFile] {
            source $indexFile
            if [info exists CacheInfo($nextPage)] {
                set cache [file join $slot(cacheDir) \
                                    $CacheInfo($nextPage).htcl]
            }
        }
        set file [file rootname $topic]
        set extension [file extension $topic]
        if [string match "*htm*" $extension] {
        # Le fichier htcl peut etre dans le meme repertoire que $topic
            if [file exists $file.htcl] {
                set cache $file.htcl
            }
        } else {
            if [file exists $file.htcl] {
                set cache $topic.htcl
            }
        }
        # On charge le fichier source htcl si il existe...
        if {([info exists cache]) && ([file exists $cache])} {
#             puts "Opening cache file: $cache"
            $self.text.t config -state normal
            $self.text2.t config -state normal
            source $cache
            # On update les widgets texts, en fonction de la nouvelle procedure
            updateTextWidget $self.text.t $self.text2.t $slot(helpdir)
            set slot(currentPage) $topic
            set slot(topic) $topic
            set slot(addHistory) 1
        } else {
            set slot(rendering) 1
#             puts "Opening new html file: $topic"
            # On parse la nouvelle page
            # a mettre autre part le if et les 2 lignes suivantes...
            if {[info exists tkhtml_priv(text)]} {
                unset tkhtml_priv(text) tkhtml_priv(tagText)
            }
            set tkhtml_priv(text) ""
            set tkhtml_priv(tagText) ""
            
            set slot(addHistory) 1

            set slot(currentPage) $topic
            set slot(topic) $topic
            set f [open $topic]
            set txt [read $f]
            close $f
            set slot(steps) [string length $txt]
            set slot(len) [string length $txt]
            set slot(remaining) $slot(len)
            tkhtml_set_render_hook "$self update_feedback"
            tkhtml_set_command_href "$self follow_link"
            tkhtml_set_command_header "$self searchTag"
            tkhtml_set_image_hook "$self image_create"
            tkhtml_set_tmpFile $slot(tmpFile)
            tkhtml_render $self.text.t $self.text2.t $txt
            $self reset_feedbar
            # On genere le cache associe (ie le fichier htcl)
            $self generate
            set slot(rendering) 0
        }
        # Updating window title, if exists.
        if {[tkhtml_title] != ""} {
            wm title $self [tkhtml_title]
        }
    }
    ####################################################################
    # METHOD image_create
    # permet de memoriser un commande pour afficher une image dans un 
    # widget text, cette commande est utilise par le parseur de HTML
    # L'image est recherchee dans le meme repertoire que le fichier 
    # HTML courant
    # Le parametre bidon est la pour assurer la compatibilte entre 
    # html2htcl.tcl et htmlView.tcl. Dans htmlView.tcl, le parametre
    # bidon correspond au chemin du fichier image.
    method image_create {bidon image} {
        return [image create photo -file [file join $slot(helpdir) $image]]
    }
    ####################################################################
    # METHOD follow_link
    # Si on demande d'ouvrir le meme fichier que le fichier courant on ne fait 
    # rien (sauf se positionner sur la bonne partie de texte si on a topic qui 
    # vaut : fichier.html#marque)
    # Commande permettant de suivre un lien, comme : ../essai.html#M12
    # Gere l'history et affiche le menu FORWARD et BACK si necessaire
    method follow_link {link} {
        set slot(addHistory) 0
        $self.text.t configure -cursor watch
        set listFileAndMark [getFile $link]
        set file [lindex $listFileAndMark 0] ; # file=file.html
        set mark [lindex $listFileAndMark 1] ; # mark=mark (!)
        # On met a jour la variable slot(helpdir)
        global tcl_platform
        switch -exact -- $tcl_platform(platform) {
          macintosh {
              if {[file dirname $link] != ":"} {
                  set slot(helpdir) \
                      [file join $slot(helpdir) [file dirname $link]]
              }
          } 
          windows -
          unix {
              if {[file dirname $link] != "."} {
                  set slot(helpdir) \
                      [file join $slot(helpdir) [file dirname $link]]
              }
          } 
        }
        set currentPage $slot(currentPage)
        set nextPage [file join $slot(helpdir) $file]
        # On charge la nouvelle page si elle differe de la page courante et 
        # si elle n'est pas vide !
        if {([string compare $nextPage $currentPage] != 0)
            && ($file != "")} {
            $self read_topic $nextPage
        }
        if {[regexp "#\[\^ \]*" $link a]} {
            # On se positionne sur le bon tag !
            $self searchTag $mark
            if {$file != ""} {
                set slot(addHistory) 1
            }
        } else {
            # Sinon on se positionne au debut du fichier
            $self.text.t yview moveto 0.0
        }
        if {$mark == ""} {
            set pageARajouter [file join $slot(helpdir) $file]
        } else {
            set pageARajouter [file join $slot(helpdir) "$file#$mark"]
        }
        if {$slot(addHistory) && ([string compare $pageARajouter \
                   [lindex $slot(history) $slot(history_ndx)]] != 0)} {
            # On ajoute la page dans l'history !
            incr slot(history_ndx)
            set slot(history) [lrange $slot(history) 0 $slot(history_ndx)]
            set slot(history_len) [expr $slot(history_ndx) + 1]
            lappend slot(history) $pageARajouter
            set slot(addHistory) 0
        }
        set m $self.menu.navigate.m
        # faut-il faire apparaitre le menu BACK ?
        if {($slot(history_ndx)+1) < $slot(history_len)} {
            $m entryconfig 1 -state normal
        } else {
            $m entryconfig 1 -state disabled
        }
        # faut-il faire apparaitre le menu FORWARD ?
        if {$slot(history_ndx) > 0} {
            $m entryconfig 2 -state normal
        } else {
            $m entryconfig 2 -state disabled
        }
        $self.text.t configure -cursor xterm
    }
    ####################################################################
    # METHOD forward
    # permet d'ouvrir la page suivante
    method forward {} {
        if {$slot(rendering) || 
            ($slot(history_ndx)+1) >= $slot(history_len)} return
        incr slot(history_ndx)
        $self follow_link [lindex $slot(history) $slot(history_ndx)]
    }
    ####################################################################
    # METHOD back
    # permet d'ouvrir la page precedente
    method back {} {
        if {$slot(rendering) || $slot(history_ndx) <= 0} return
        incr slot(history_ndx) -1
        $self follow_link [lindex $slot(history) $slot(history_ndx)]
    }
    ####################################################################
    # METHOD fill_go_menu
    # met a jour le menu go
    method fill_go_menu {} {
        set m $self.menu.navigate.m.go
        catch {$m delete 0 last}
        for {set i [expr [llength $slot(history)]-1]} {$i >= 0} {incr i -1} {
            set topic [lindex $slot(history) $i]
            $m add command -label $topic \
                -command [list $self follow_link $topic]
        }
    }
    ####################################################################
    # METHOD reset_feedbar
    # met la feedbar a 0%
    method reset_feedbar {} {
        incr slot(step) 0
        $self.feedback.percentage config -text "0%"
        $self.feedback.framebar.bar config -width 0
        update
    }
    ####################################################################
    # METHOD update_feedback
    # update la feedbar de la valeur n
    method update_feedback {n} {
        set inc [expr $slot(remaining) - $n]
        if {$inc > .1*$slot(len)} {
            if {$slot(step) >= $slot(steps)} return
            incr slot(step) $inc
            set fraction [expr 1.0*$slot(step)/$slot(steps)]
            $self.feedback.percentage config \
                     -text [format %.0f%% [expr 100.0*$fraction]]
            $self.feedback.framebar.bar config \
                     -width [expr int($slot(barwidth)*$fraction)]
            update
            update idletasks
            set slot(remaining) $n
	}
    }
    ####################################################################
    method page_forward {} {
        $self.text.t yview scroll 1 pages
    }
    method page_back {} {
        $self.text.t yview scroll -1 pages
    }
    method line_forward {} { $self.text.t yview scroll 1 units }
    method line_back {} { $self.text.t yview scroll -1 units }
    method searchTag {tag} {
        set c [$self.text.t tag ranges $tag]
        regsub -all "\\\.\[^\\n\]*" [lindex $c 0] "" line
        $self.text.t yview [expr $line-1]
    }
    ####################################################################
    # method sash-begin
    # cette methode est executee, des que l'on clique sur la barre 
    # $self.sep pour redimensionner les fenetres textes
    method sash-begin {} {
        # nb de ligne du widget text :$self.text2.t
        set slot(sash-hh)  [$self.text2.t cget -height]
        set slot(sash-beg) [winfo y $self.line]
        set slot(sash-ppl) [expr [winfo height $self.text2.t]/\
                                        $slot(sash-hh)]
        set slot(sash-min) [expr [winfo y $self.text2.t]\
                                        +1*$slot(sash-ppl)]
        set slot(sash-max) [expr [winfo y $self]\
                                        +[winfo height $self]-50]
    }
    ####################################################################
    # method sash-draw
    # cette methode est executee, des que l'on bouge la barre 
    # $self.sep pour redimensionner les fenetres textes
    method sash-draw {Y} {
        if {$Y < $slot(sash-min) || 
            $Y > $slot(sash-max)} return
        
        set topy [winfo y $self]
        incr Y -$topy
        
        place configure $self.line -in $self \
            -relx 0.03 -rely 0 -y $Y -relwidth 0.95
            
        raise $self.line
    }
    ####################################################################
    # method sash-split-end
    # cette methode est executee, des que l'on lache la barre 
    # $self.sep pour redimensionner les fenetres textes
    method sash-split-end {} {
        global tkhtml_priv
        set hh [$self.text.t cget -height]
        set sashy [winfo y $self.line]
        set adj [expr round((1.0*$sashy-$slot(sash-beg))/\
                            $slot(sash-ppl))]
        $self.text2.t configure -height [expr $slot(sash-hh)+$adj]
        $self.text.t configure -height [expr $hh-$adj]

        place configure $self.line -in $self.sep -relx 0.03 -rely 0.4 \
            -y 0 -relwidth 0.95
        raise $self.line
    }
}

########################################################################
# renvoie la liste {a.html mark} pour un link /usr/lei/doc/a.html#mark
# PARAMETRES :
# 	ENTREES : 
#             - link : chaine symbolisant un lien, c'est a dire un 
#               pointeur sur un fichier
########################################################################
proc getFile {link} {
    set file [file tail $link]
    set matchString ""
    if [regexp -indices {#[^$]*} $file match] {
        set matchString [string range $file [expr [lindex $match 0]+1] end]
        set file [string range $file 0 [expr [lindex $match 0]-1]]
    }
    return [list $file $matchString]
}

########################################################################
# proc addTag
# ajoute des tags dans la fenetre text precisee <widgetText>.
# PARAMETRES :
#     ENTREES :
#        - args : liste du type <widgetText> <tagName> <ListOfIndex>
#                 liste of index contient un nombre pair d'index.
########################################################################
proc addTag {args} {
    set w [lindex $args 0]
    set tagName [lindex $args 1]
    set listOfTags [lrange $args 2 end]
    while {[llength $listOfTags]>0} {
        set i [lindex $listOfTags 0]
        set j [lindex $listOfTags 1]
        $w tag add $tagName $i $j
        set listOfTags [lrange $listOfTags 2 end]
    }
}
