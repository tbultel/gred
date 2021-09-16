 #
# $Id: hviewTkhtml.tcl,v 1.3 1997/04/17 09:02:33 carqueij Exp $
#
# This software is copyright (C) 1995 by the Lawrence Berkeley Laboratory.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that: (1) source code distributions
# retain the above copyright notice and this paragraph in its entirety, (2)
# distributions including binary code include the above copyright notice and
# this paragraph in its entirety in the documentation or other materials
# provided with the distribution, and (3) all advertising materials mentioning
# features or use of this software display the following acknowledgement:
# ``This product includes software developed by the University of California,
# Lawrence Berkeley Laboratory and its contributors.'' Neither the name of
# the University nor the names of its contributors may be used to endorse
# or promote products derived from this software without specific prior
# written permission.
# 
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
# This code is based on Angel Li's (angel@flipper.rsmas.miami.edu) HTML
# rendering code.
#

# "package provide" est inutile car ce fichier est directement sourcé
# package provide hview 0.1


########################################################################
# Procedure qui parse un fichier HTML, et appelle une procedure TCL pour
# chaque commande HTML.
# On utilise 3 fichiers temporaires qui permettent de creer le fichier
# de cache
# $tkhtml_priv(tmpFile)1.htcl permet de memoriser le texte du fichier
# HTML, sans les commandes HTML
# $tkhtml_priv(tmpFile)2.htcl permet de memoriser la configuration des
# tags
# $tkhtml_priv(tmpFile)3.htcl permet d'affecter un tag a un zone de texte
########################################################################
proc tkhtml_render {w w2 html} {
    global tkhtml_priv tkhtml_entity
    set tkhtml_priv(rendering) 1
    $w config -state normal
    $w2 config -state normal
    $w delete 1.0 end
    $w2 delete 1.0 end
    tkhtml_setup $w $w2
    if [file exists [file join $tkhtml_priv(tmpFile) 1.htcl]] {
        file delete -force [file join $tkhtml_priv(tmpFile) 1.htcl]
    }
    if [file exists [file join $tkhtml_priv(tmpFile) 1bis.htcl]] {
        file delete -force [file join $tkhtml_priv(tmpFile) 1bis.htcl]
    }
    if [file exists [file join $tkhtml_priv(tmpFile) 2.htcl]] {
        file delete -force [file join $tkhtml_priv(tmpFile) 2.htcl]
    }
    if [file exists [file join $tkhtml_priv(tmpFile) 3.htcl]] {
        file delete -force [file join $tkhtml_priv(tmpFile) 3.htcl]
    }
    # On cree un canal pour chaque fichier temporaire
    set tkhtml_priv(channel) [open [file join $tkhtml_priv(tmpFile) 1.htcl] w]
    set tkhtml_priv(channel1bis) [open [file join $tkhtml_priv(tmpFile) 1bis.htcl] w]
    set tkhtml_priv(channel2) [open [file join $tkhtml_priv(tmpFile) 2.htcl] w]
    set tkhtml_priv(channel3) [open [file join $tkhtml_priv(tmpFile) 3.htcl] w]
    # On creer un procedure qui initialisera les 2 widgets textes
    puts $tkhtml_priv(channel) "proc updateTextWidget \
                                       {widget1 widget2 imageDir} {"
    puts $tkhtml_priv(channel) "global tkhtml_priv tkhtml_entity"
    puts $tkhtml_priv(channel) "\$widget1 delete 1.0 end"
    puts $tkhtml_priv(channel) "\$widget2 delete 1.0 end"
    puts $tkhtml_priv(channel) "\$widget1 configure -bg $tkhtml_priv(bgcolor)"
    puts $tkhtml_priv(channel) "\$widget2 configure -bg $tkhtml_priv(bgcolor)"
    $w configure -bg $tkhtml_priv(bgcolor)
    $w2 configure -bg $tkhtml_priv(bgcolor)
    # On definit les tags pour hr et HEADER
    puts $tkhtml_priv(channel) \
           "\$widget1 tag config hr -relief sunken -borderwidth 1 \
            -font -*-*-*-*-*-*-$tkhtml_priv(ruler_height)-*-*-*-*-*-*-*"
    puts $tkhtml_priv(channel) \
            "\$widget1 tag configure HEADER \
             -font -*-times-medium-r-normal-*-*-160-*-*-*-*-iso8859-* \
             -foreground black -lmargin1 0m -lmargin2 0m -justify left"
    # On installe les bindings pour les href et les index
    puts $tkhtml_priv(channel) \
        "\$widget1 tag bind HREF <Enter> \"enter_href %W href %x %y\""
    puts $tkhtml_priv(channel) \
        "\$widget1 tag bind HREF <Leave> \"leave_href %W href \""
    puts $tkhtml_priv(channel) \
        "\$widget1 tag bind HREF <1> \"click_href %W href %x %y\""
    puts $tkhtml_priv(channel) \
        "\$widget1 tag bind HREF <Motion> \"update_href %W href %x %y\""
    puts $tkhtml_priv(channel) \
        "\$widget2 tag bind HEADER <Enter> \"enter_href %W header %x %y\""
    puts $tkhtml_priv(channel) \
        "\$widget2 tag bind HEADER <Leave> \"leave_href %W header \""
    puts $tkhtml_priv(channel) \
        "\$widget2 tag bind HEADER <1> \"click_href %W header %x %y\""
    puts $tkhtml_priv(channel) \
        "\$widget2 tag bind HEADER <Motion> \"update_href %W header %x %y\""

    puts -nonewline $tkhtml_priv(channel) "\$widget1 insert end {"
    puts -nonewline $tkhtml_priv(channel1bis) "\$widget2 insert end {"
    set tkhtml_priv(continue_rendering) 1
    tkhtml_set_tag
    # On parse le texte HTML
    while {$tkhtml_priv(continue_rendering)} {
        # normal state
        while {[set len [string length $html]]} {
            # look for text up to the next <> element
            if [regexp -indices "^\[^<\]+" $html match] {
                set text [string range $html 0 [lindex $match 1]]
                tkhtml_append_text $text
                set html \
                    [string range $html [expr [lindex $match 1]+1] end]
            }
            # we're either at a <>, or at the eot
            if [regexp -indices "^<(\[^>\]+)>" $html match entity] {
                set entity [string range $html [lindex $entity 0] \
                            [lindex $entity 1]]
                set cmd [string tolower [lindex $entity 0]]
                if {[info exists tkhtml_entity($cmd)]} {
                    tkhtml_do $cmd [lrange $entity 1 end]
                }
                set html \
                    [string range $html [expr [lindex $match 1]+1] end]
            }
            if [info exists tkhtml_priv(render_hook)] {
                eval $tkhtml_priv(render_hook) $len
            }
            if $tkhtml_priv(verbatim) break
        }
        # we reach here if html is empty, or verbatim is 1
        if !$len break
        # verbatim must be 1
        # append text until a </pre> is reached
        if {[regexp -indices -nocase \
                    $tkhtml_priv(verb_end_token) $html match]} {
            set text [string range $html 0 [expr [lindex $match 0]-1]]
            set html [string range $html [expr [lindex $match 1]+1] end]
        } else {
            set text $html
            set html ""
        }
        tkhtml_append_text $text
        if [info exists \
                 tkhtml_entity([string trim $tkhtml_priv(verb_end_token) <>])] {
            tkhtml_do [string trim $tkhtml_priv(verb_end_token) <>]
        }
    }
    $w config -state disabled
    # Updating window title, if exists.
    if {[tkhtml_title] != ""} {
        puts $tkhtml_priv(channel3) \
            "set tkhtml_priv(title) \"[tkhtml_title]\""
    }
    # On sauvegarde l'emplacement des tags dans les 2 widgets textes
    set listOfTags [$tkhtml_priv(w) tag names]
    foreach el $listOfTags {
        set tagRange [$tkhtml_priv(w) tag ranges $el]
        puts $tkhtml_priv(channel3) "addTag \$widget1 $el $tagRange"
    }
    set listOfTags [$tkhtml_priv(w2) tag names]
    foreach el $listOfTags {
        set tagRange [$tkhtml_priv(w2) tag ranges $el]
        puts $tkhtml_priv(channel3) "addTag \$widget2 $el $tagRange"
    }
    # On ferme les fichiers temporaires
    puts $tkhtml_priv(channel) "}"
    puts $tkhtml_priv(channel1bis) "}"
    # On ecrit les references dans le fichier de cache
    puts $tkhtml_priv(channel2) \
        "array set tkhtml_priv [list [array get tkhtml_priv href*]]"
    puts $tkhtml_priv(channel2) \
        "array set tkhtml_priv [list [array get tkhtml_priv header*]]"
#     puts $tkhtml_priv(channel) "\$widget1 configure -state disabled"
#     puts $tkhtml_priv(channel) "\$widget2 configure -state disabled"
#     $w configure -state disabled
#     $w2 configure -state disabled
    puts $tkhtml_priv(channel3) "} ; # endproc updateTextWidget"
    close $tkhtml_priv(channel)
    close $tkhtml_priv(channel1bis)
    close $tkhtml_priv(channel2)
    close $tkhtml_priv(channel3)
    set tkhtml_priv(rendering) 0
}

########################################################################
# Procedure d'initailisation des valeurs par default des fontes...
########################################################################
proc tkhtml_defaults {} {
    global tkhtml_priv
    set tkhtml_priv(defaults_set) 1
    set tkhtml_priv(default_font) times
    set tkhtml_priv(fixed_font) courier
    set tkhtml_priv(font_size) medium
    set tkhtml_priv(small_points) "60 80 100 120 140 180 240"
    set tkhtml_priv(medium_points) "80 100 120 140 180 240 360"
    set tkhtml_priv(large_points) "100 120 140 180 240 360 480"
    set tkhtml_priv(huge_points) "120 140 180 240 360 480 640"
    set tkhtml_priv(ruler_height) 4
    set tkhtml_priv(indent_incr) 10
    # memorise le nom de fenetre text ou afficher le texte en HTML
    set tkhtml_priv(w) {}
    # memorise le nom de fenetre text ou afficher la struture du texte HTML
    set tkhtml_priv(w2) {}
    set tkhtml_priv(counter) -1
} ; # end proc tkhtml_defaults

proc tkhtml_set_font {font size} {
    global tkhtml_priv
    set tkhtml_priv(default_font) $font
    set tkhtml_priv(font) $font
    set tkhtml_priv(font_size) $size
} ; # end proc tkhtml_set_font

########################################################################
# Procedure permettant d'initialiser les variables avant de parser un 
# fichier HTML
########################################################################
proc tkhtml_setup {w w2} {
    global tkhtml_priv
    if ![info exists tkhtml_priv(defaults_set)] tkhtml_defaults
    set tkhtml_priv(renderin) 0
    # Memorise le tag dans lequel on vient d'entrer (pour le binding <Enter>)
    set tkhtml_priv(tagSelectionnedhref) ""
    set tkhtml_priv(tagSelectionnedheader) ""
    # Permet de memoriser la liste des tags deja configures, cela permet 
    # de ne pas reecrire la meme configuration de tag dans le fichier de 
    # tag
    set tkhtml_priv(listOfTagAdded) {}
    # Indique que le texte qui suit est un header, typiquement 
    # tkhtml_priv(in_header) vaut 1 entre <Hx> et </Hx> x dans [1..6]
    set tkhtml_priv(in_header) 0
    # permet de memoriser le texte d'un header, vaut AAA apres :
    # <Hx>AAA</Hx>
    set tkhtml_priv(headerText) ""
    # Permet de memoriser l'index courant pour generer la structure du 
    # document
    set tkhtml_priv(currentIndexNb) "0."
    # Contient la valeur du header precedent. Vaut x apres la commande <Hx> 
    set tkhtml_priv(header) 0
    # Memorise la valeur du premier header. Vaut x apres la premiere
    # commande <Hx>
    set tkhtml_priv(firstHeader) ""
    # S'incremente a chaque commande <Hx>, permet numeroter les tags pour les
    # header
    set tkhtml_priv(headerCount) 0
    # Permet la procedure tkhtml_set_tag de savoir qu'il sagit d'un header
    set tkhtml_priv(headerTag) ""
    # Mode d'affichage des indices pour la table des matieres
    # Ici on aura : I. heading 1
    #                 A. heading 2
    #                   1. heading 3
    #                     1.1. heading 4
    #                       i. heading 5
    #                         heading 6
    #                         Le texte...
    set tkhtml_priv(TYPE1) I
    set tkhtml_priv(TYPE2) A
    set tkhtml_priv(TYPE3) 1
    set tkhtml_priv(TYPE4) 1
    set tkhtml_priv(TYPE5) i
    set tkhtml_priv(TYPE6) i
    set tkhtml_priv(headerStruct1) "h1."
    set tkhtml_priv(headerStruct2) "h2."
    set tkhtml_priv(headerStruct3) "h3."
    set tkhtml_priv(headerStruct4) "h3.h4."
    set tkhtml_priv(headerStruct5) "h5."
    set tkhtml_priv(headerStruct6) ""
    # La couleur de fond de page...
    set tkhtml_priv(bgcolor) #d9d9d9
    # Les commandes suivantes permettent de communiquer des informations 
    # a la procedure tkhtml_set_tag 
    set tkhtml_priv(font) $tkhtml_priv(default_font)
    set tkhtml_priv(left) 0
    set tkhtml_priv(left2) 0
    set tkhtml_priv(dd) 0
    set tkhtml_priv(li) 0
    set tkhtml_priv(strike) 0
    set tkhtml_priv(underline) 0
    set tkhtml_priv(right) 0
    set tkhtml_priv(justify) L
    set tkhtml_priv(weight) 0
    set tkhtml_priv(slant) 0
    set tkhtml_priv(underline) 0
    set tkhtml_priv(verbatim) 0
    set tkhtml_priv(pre) 0
    set tkhtml_priv(title) ""
    set tkhtml_priv(in_title) 0
    set tkhtml_priv(color) black
    set tkhtml_priv(li_style) bullet
    set tkhtml_priv(anchor_count) 0
    set tkhtml_priv(anchor_count2) 0
    set tkhtml_priv(verb_end_token) {}
    set tkhtml_priv(orderedListIndice) 0
    # initialisation des piles
    set tkhtml_priv(stack.header) {}
    set tkhtml_priv(stack.strike) {}
    set tkhtml_priv(stack.underline) {}
    set tkhtml_priv(stack.font) {}
    set tkhtml_priv(stack.left) {}
    set tkhtml_priv(stack.left2) {}
    set tkhtml_priv(stack.color) {}
    set tkhtml_priv(stack.justify) {}
    set tkhtml_priv(stack.li_style) {}
    set tkhtml_priv(stack.href) {}
    set tkhtml_priv(stack.aref) {}
    set tkhtml_priv(stack.orderedListIndice) {}
    set tkhtml_priv(points_ndx) 2
    set tkhtml_priv(aref) ""
    if {$tkhtml_priv(w2) != $w2} {
        set tkhtml_priv(w2) $w2
        $w2 tag configure HEADER \
             -font -*-times-medium-r-normal-*-*-160-*-*-*-*-iso8859-* \
             -foreground black -lmargin1 0m -lmargin2 0m -justify left
    }
    # initialisation de la separation pour la commande <HR>
    if {$tkhtml_priv(w) != $w} {
        set tkhtml_priv(w) $w
        $tkhtml_priv(w) tag config hr -relief sunken -borderwidth 1 \
            -font -*-*-*-*-*-*-$tkhtml_priv(ruler_height)-*-*-*-*-*-*-*
        foreach elt [array names tkhtml_priv] {
            if [regexp "^tag\\..*" $elt] {
                unset tkhtml_priv($elt)
            }
        }
    }
    # Les bindings pour les index
    $tkhtml_priv(w2) tag bind HEADER <1> "click_href %W header %x %y"
    $tkhtml_priv(w2) tag bind HEADER <Enter> "enter_href %W header %x %y"
    $tkhtml_priv(w2) tag bind HEADER <Leave> "leave_href %W header"
    $tkhtml_priv(w2) tag bind HEADER <Motion> "update_href %W header %x %y"
    # Les bindings pour les references HTML
    $tkhtml_priv(w) tag bind HREF <Enter> "enter_href %W href %x %y"
    $tkhtml_priv(w) tag bind HREF <Leave> "leave_href %W href"
    $tkhtml_priv(w) tag bind HREF <1> "click_href %W href %x %y"
    $tkhtml_priv(w) tag bind HREF <Motion> "update_href %W href %x %y"
} ; # end proc tkhtml_setup
#######################################################################
# update_href --
# Procedure executee lorsque la souris passe d'une href a une autre href
# (dans le widget HTML) ou un index (dans le widget index). Cela permet
# d'updater la couleur de l'href selectionnee !
# PARAMETRES : 
# 	ENTREES :
#         - w : nom du widget texte
#         - prefixe : vaut href pour une reference html, et header pour un
#                     index (fenetre index)
#         - x y : Coordonnees de la souris au moment de l'execution de la
#                 procedure update_href
########################################################################
proc update_href {w prefixe x y} {
    global tkhtml_priv
    if {$tkhtml_priv(rendering)} return
    set ListOfTag [$w tag names @$x,$y]
    set href ""
    foreach tag $ListOfTag {
        if [regexp -indices "$prefixe:" $tag match] {
            set href \
                  [string range $tag [expr [lindex $match 1]+1] end]
        }
    }
    if {[string compare $href $tkhtml_priv(tagSelectionned$prefixe)] != 0
        && ($tkhtml_priv(tagSelectionned$prefixe) != "")
        && ($href != "")} {
        $w tag configure \
            $prefixe:$tkhtml_priv(tagSelectionned$prefixe) \
            -foreground [lindex \
                          $tkhtml_priv($tkhtml_priv(tagSelectionned$prefixe)) 1]
        $w tag configure $prefixe:$href \
               -foreground red
        set tkhtml_priv(tagSelectionned$prefixe) $href
    }
}
########################################################################
# click_href --
# Procedure executee lorsque l'on clique sur une reference href 
# (dans le widget HTML) ou un index (dans le widget index)
# PARAMETRES : 
# 	ENTREES :
#         - w : nom du widget texte
#         - prefixe : vaut href pour une reference html, et header pour un
#                     index (fenetre index)
#         - x y : Coordonnees de la souris au moment de l'execution de la
#                 procedure click_href
########################################################################
proc click_href {w prefixe x y} {
    global tkhtml_priv
    # On recupere les tags
    set ListOfTag [$w tag names @$x,$y]
    set href ""
    # On recupere le bon tag href:... ou header:...
    foreach tag $ListOfTag {
        if [regexp -indices "$prefixe:" $tag match] {
            set href \
                  [string range $tag [expr [lindex $match 1]+1] end]
        }
    }
    if {$href != ""} {
        $w tag configure $prefixe:$href \
              -foreground [lindex \
                          $tkhtml_priv($tkhtml_priv(tagSelectionned$prefixe)) 1]
        eval [list tkhtml_${prefixe}_click $tkhtml_priv(command$prefixe) \
                          [lindex $tkhtml_priv($href) 0]]
    }
} ; # end proc update_href
########################################################################
# enter_href --
# Procedure executee lorsque la souris passe sur une reference href 
# (dans le widget HTML) ou un index (dans le widget index)
# PARAMETRES : 
# 	ENTREES :
#         - w : nom du widget texte
#         - prefixe : vaut href pour une reference html, et header pour un
#                     index (fenetre index)
#         - x y : Coordonnees de la souris au moment de l'execution de la
#                 procedure enter_href
########################################################################
proc enter_href {w prefixe x y} {
    global tkhtml_priv
    if {$tkhtml_priv(rendering)} return
    set ListOfTag [$w tag names @$x,$y]
    foreach tag $ListOfTag {
        if [regexp -indices "$prefixe:" $tag match] {
            set tkhtml_priv(tagSelectionned$prefixe) \
                  [string range $tag [expr [lindex $match 1]+1] end]
        }
    }
    if {$tkhtml_priv(tagSelectionned$prefixe) != ""} {
        $w tag configure \
                   $prefixe:$tkhtml_priv(tagSelectionned$prefixe) \
                   -foreground red
        $w configure -cursor hand2
    }
} ; # end proc enter_href
########################################################################
# leave_href --
# Procedure executee lorsque la souris passe sur une reference href 
# (dans le widget HTML) ou un index (dans le widget index)
# PARAMETRES : 
# 	ENTREES :
#         - w : nom du widget texte
#         - prefixe : vaut href pour une reference html, et header pour un
#                     index (fenetre index)
#         - x y : Coordonnees de la souris au moment de l'execution de la
#                 procedure leave_href
########################################################################
proc leave_href {w prefixe } {
    global tkhtml_priv
    if {$tkhtml_priv(tagSelectionned$prefixe) != ""} {
        $w tag configure \
            $prefixe:$tkhtml_priv(tagSelectionned$prefixe) \
            -foreground [lindex \
                          $tkhtml_priv($tkhtml_priv(tagSelectionned$prefixe)) 1]
        $w configure -cursor xterm
    }
    set tkhtml_priv(tagSelectionned$prefixe) ""
    
} ; # end proc leave_href

proc tkhtml_define_font {name foundry family weight slant registry} {
    global tkhtml_priv
    lappend tkhtml_priv(font_names) $name
    set tkhtml_priv(font_info.$name) \
        [list $foundry $family $weight $slant $registry]
} ; # end proc tkhtml_define_font

proc tkhtml_define_entity {name body} {
    global tkhtml_entity
    set tkhtml_entity($name) $body
} ; # end proc tkhtml_define_entity

# Pour la commande <TOTO> ececute la commande contenue dans $tkhtml_entity(TOTO)
proc tkhtml_do {cmd {argv {}}} {
    global tkhtml_priv tkhtml_entity
    eval $tkhtml_entity($cmd)
} ; # end proc tkhtml_do

proc tkhtml_append_text {text} {
    global tkhtml_priv
    if !$tkhtml_priv(verbatim) {
        if !$tkhtml_priv(pre) {
                regsub -all "\[ \n\r\t\]+" [string trim $text] " " text
        }
        set text [tkhtml_map_esc $text]
        if ![string length $text] return
    }
    if {!$tkhtml_priv(pre) && !$tkhtml_priv(in_title)} {
        set p [$tkhtml_priv(w) get "end - 2c"]
        set n [string index $text 0]
        if {![regexp "\[ \n(\]" $p] && ![regexp "\[\\.,')\]" $n]} {
            $tkhtml_priv(w) insert end " "
            puts -nonewline $tkhtml_priv(channel) " "
            if $tkhtml_priv(in_header) {
                set tkhtml_priv(headerText) "$tkhtml_priv(headerText) "
            }
        }
        $tkhtml_priv(w) insert end $text $tkhtml_priv(tag)
        puts -nonewline $tkhtml_priv(channel) "$text"
        if $tkhtml_priv(in_header) {
                set tkhtml_priv(headerText) "$tkhtml_priv(headerText)$text"
        }
        return
    }
    if {$tkhtml_priv(pre) && !$tkhtml_priv(in_title)} {
        $tkhtml_priv(w) insert end $text $tkhtml_priv(tag)
        puts -nonewline $tkhtml_priv(channel) "$text"
        if $tkhtml_priv(in_header) {
                set tkhtml_priv(headerText) "$tkhtml_priv(headerText)$text"
        }
        return
    }
    append tkhtml_priv(title) $text
} ; # end proc tkhtml_append_text

# a tag is constructed as: font?B?I?U?Points-LeftLeft2RightColorJustify
proc tkhtml_set_tag {} {
    global tkhtml_priv
    global a
    set i -1
    foreach var {foundry family weight slant registry} {
        set $var [lindex $tkhtml_priv(font_info.$tkhtml_priv(font)) [incr i]]
    }
    set x_font "-$foundry-$family-"
    set tag $tkhtml_priv(font)
    set args {}
    if {$tkhtml_priv(weight) > 0} {
        append tag "B"
        append x_font [lindex $weight 1]-
    } else {
        append x_font [lindex $weight 0]-
    }
    if {$tkhtml_priv(slant) > 0} {
        append tag "I"
        append x_font [lindex $slant 1]-
    } else {
        append x_font [lindex $slant 0]-
    }
    if {$tkhtml_priv(underline) > 0} {
        append tag "U"
        append args " -underline 1"
    }
    if {$tkhtml_priv(strike) > 0} {
        append tag "S"
        append args " -overstrike 1"
    }
    switch $tkhtml_priv(justify) {
        L { append args " -justify left" }
        R { append args " -justify right" }
        C { append args " -justify center" }
    }
    set pts [lindex $tkhtml_priv($tkhtml_priv(font_size)_points) \
             $tkhtml_priv(points_ndx)]
    append tag $tkhtml_priv(points_ndx) - $tkhtml_priv(left) \
        $tkhtml_priv(left2) $tkhtml_priv(right) \
        $tkhtml_priv(color) $tkhtml_priv(justify)
    append x_font "normal-*-*-$pts-*-*-*-*-$registry-*"
    set tags {}
    if $tkhtml_priv(anchor_count) {
        set href [tkhtml_peek href] ; # lsort.n.html#M7
        if {$tkhtml_priv(anchor_count) == 2} {
            # Si tkhtml_priv(anchor_count)=2, c'est que la commande 
            # <a ..>...</a> a ete coupe par une autre commande. Par exemple :
            # <a HREF=kiki> <b> pointeur <i> suite</i> </b> </a>
            set href_tag href$tkhtml_priv(counter) ; # href78
        } else {
            set href_tag href[incr tkhtml_priv(counter)] ; # href79
        }
        set tags [list $tag href:$href_tag HREF]
        if {([info exists tkhtml_priv(commandhref)]) 
            && ($tkhtml_priv(anchor_count) == 1)} {
            # On installe le lien...
            set tkhtml_priv($href_tag) \
                  [list $href $tkhtml_priv(color)]
        }
        set tkhtml_priv(anchor_count) 2
    }
    if {$tkhtml_priv(anchor_count2)} {
        set aref [tkhtml_peek aref]
        if {$tags == {}} {
            # Il y a une information HREF=menu.html ET une info
            # NAME=M12
            set tags [list $tag $aref]
        } else {
            # Il y a seulement une info NAME=M12
            lappend tags $aref
        }
    } elseif {$tkhtml_priv(anchor_count) == 0} {
        set tags $tag
    }
    if {$tkhtml_priv(headerTag) != ""} {
        lappend tags header$tkhtml_priv(headerCount)
    }
    if {![info exists tkhtml_priv(tag.$tag)]} {
        set tkhtml_priv(tag_font.$tag) 1
        eval $tkhtml_priv(w) tag configure $tag \
            -font $x_font -foreground $tkhtml_priv(color) \
            -lmargin1 $tkhtml_priv(left)m \
            -lmargin2 $tkhtml_priv(left2)m $args
        if {[lsearch $tkhtml_priv(listOfTagAdded) $tag] == -1} {
        # On ajoute la definition du tag que si c'est un nouveau tag
            puts $tkhtml_priv(channel2) \
                "\$widget1 tag configure $tag\
                    -font $x_font -foreground $tkhtml_priv(color)\
                    -lmargin1 $tkhtml_priv(left)m\
                    -lmargin2 $tkhtml_priv(left2)m $args"
            lappend tkhtml_priv(listOfTagAdded) $tag
        }
    }
    set tkhtml_priv(tag) $tags
} ; # end proc tkhtml_set_tag

proc tkhtml_reconfig_tags {w} {
    global tkhtml_priv
    foreach tag [$w tag names] {
        foreach font $tkhtml_priv(font_names) {
            if [regexp "${font}(B?)(I?)(U?)(\[1-9\]\[0-9\]*)-" \
                       $tag t b i u points] {
                set j -1
                if {$font != $tkhtml_priv(fixed_font)} {
                    set font $tkhtml_priv(font)
                }
                foreach var {foundry family weight slant registry} {
                    set $var [lindex $tkhtml_priv(font_info.$font) [incr j]]
                }
                set x_font "-$foundry-$family-"
                if {$b == "B"} {
                    append x_font [lindex $weight 1]-
                } else {
                    append x_font [lindex $weight 0]-
                }
                if {$i == "I"} {
                    append x_font [lindex $slant 1]-
                } else {
                    append x_font [lindex $slant 0]-
                }
                set pts [lindex $tkhtml_priv($tkhtml_priv(font_size)_points) \
                         $points]
                append x_font "normal-*-*-$pts-*-*-*-*-$registry-*"
                $w tag config $tag -font $x_font
                break
            }
        }
    }
} ; # end proc tkhtml_reconfig_tags

proc tkhtml_push {stack value} {
    global tkhtml_priv
    lappend tkhtml_priv(stack.$stack) $value
} ; # end proc tkhtml_push

proc tkhtml_pop {stack} {
    global tkhtml_priv
    set n [expr [llength $tkhtml_priv(stack.$stack)]-1]
    if {$n < 0} {
        puts "popping empty stack $stack"
        return ""
    }
    set val [lindex $tkhtml_priv(stack.$stack) $n]
    set tkhtml_priv(stack.$stack) [lreplace $tkhtml_priv(stack.$stack) $n $n]
    return $val
} ; # end proc tkhtml_pop

proc tkhtml_peek {stack} {
    global tkhtml_priv
    return [lindex $tkhtml_priv(stack.$stack) end]
} ; # end proc tkhtml_peek

proc tkhtml_parse_fields {array_var string} {
    upvar $array_var array
    regsub -all "\[ \t\]*=" $string "=" string
    regsub -all "=\[ \t\]*" $string "=" string
    foreach arg $string {
        if ![regexp "(\[^ \n\r=\]+)\[ \t\]*=\[ \t\]*\"?(\[^\"\n\r\t \]*)"\
                    $arg dummy field value] {
            puts "malformed command field"
            puts "field = \"$arg\""
            continue
        }
        set array([string tolower $field]) $value
    }
} ; # end proc tkhtml_parse_fields


proc tkhtml_title {} {
    global tkhtml_priv
    if [info exists tkhtml_priv(title)] {
        return $tkhtml_priv(title)
    }
    return ""
} ; # end proc tkhtml_title

proc tkhtml_set_render_hook {hook} {
    global tkhtml_priv
    set tkhtml_priv(render_hook) $hook
} ; # end proc tkhtml_set_render_hook

proc tkhtml_set_image_hook {hook} {
    global tkhtml_priv
    set tkhtml_priv(image_hook) $hook
} ; # end proc tkhtml_set_image_hook

proc tkhtml_set_tmpFile {tmpFile} {
    global tkhtml_priv
    set tkhtml_priv(tmpFile) $tmpFile
} ; # end proc tkhtml_set_tmpFile

proc tkhtml_set_command_href {cmd} {
    global tkhtml_priv
    set tkhtml_priv(commandhref) $cmd
} ; # end proc tkhtml_set_command_href

proc tkhtml_set_command_header {cmd} {
    global tkhtml_priv
    set tkhtml_priv(commandheader) $cmd
} ; # end proc tkhtml_set_command_header

proc tkhtml_set_imagePath {path} {
    global tkhtml_priv
    set tkhtml_priv(imagePath) $path
} ; # end proc tkhtml_set_imagePath

proc tkhtml_href_click {cmd href} {
    uplevel #0 $cmd $href
} ; # end proc tkhtml_href_click
proc tkhtml_header_click {cmd header} {
    uplevel #0 $cmd $header
} ; # end proc tkhtml_header_click

# define the fonts we're going to use
set tkhtml_priv(font_names) ""
tkhtml_define_font helvetica adobe helvetica "medium bold" "r o" iso8859
tkhtml_define_font courier adobe courier "medium bold" "r o" iso8859
tkhtml_define_font times adobe times "medium bold" "r i" iso8859
tkhtml_define_font symbol adobe symbol "medium medium" "r r" adobe

# define the entities we're going to handle
tkhtml_define_entity b { incr tkhtml_priv(weight); tkhtml_set_tag }
tkhtml_define_entity /b { incr tkhtml_priv(weight) -1; tkhtml_set_tag }
tkhtml_define_entity strong { incr tkhtml_priv(weight); tkhtml_set_tag }
tkhtml_define_entity /strong { incr tkhtml_priv(weight) -1; tkhtml_set_tag }
tkhtml_define_entity tt {
    tkhtml_push font $tkhtml_priv(font)
    set tkhtml_priv(font) $tkhtml_priv(fixed_font)
    tkhtml_set_tag
}
tkhtml_define_entity /tt {
    set tkhtml_priv(font) [tkhtml_pop font]
    tkhtml_set_tag
}
tkhtml_define_entity code { 
    tkhtml_push font $tkhtml_priv(font)
    set tkhtml_priv(font) $tkhtml_priv(fixed_font)
    tkhtml_set_tag
}
tkhtml_define_entity /code {
    set tkhtml_priv(font) [tkhtml_pop font]
    tkhtml_set_tag
}
tkhtml_define_entity kbd { tkhtml_do tt }
tkhtml_define_entity /kbd { tkhtml_do /tt }
tkhtml_define_entity em { incr tkhtml_priv(slant); tkhtml_set_tag }
tkhtml_define_entity /em { incr tkhtml_priv(slant) -1; tkhtml_set_tag }
tkhtml_define_entity var { incr tkhtml_priv(slant); tkhtml_set_tag }
tkhtml_define_entity /var { incr tkhtml_priv(slant) -1; tkhtml_set_tag }
tkhtml_define_entity cite { incr tkhtml_priv(slant); tkhtml_set_tag }
tkhtml_define_entity /cite { incr tkhtml_priv(slant) -1; tkhtml_set_tag }
tkhtml_define_entity address {
    tkhtml_do br
    incr tkhtml_priv(slant)
    tkhtml_set_tag
}
tkhtml_define_entity /address {
    incr tkhtml_priv(slant) -1
    tkhtml_do br
    tkhtml_set_tag
}
tkhtml_define_entity /cite { incr tkhtml_priv(slant) -1; tkhtml_set_tag }

tkhtml_define_entity p {
    set x [$tkhtml_priv(w) get end-3c]
    set y [$tkhtml_priv(w) get end-2c]
    if {$x == "" && $y == ""} return
    if {$y == ""} {
        $tkhtml_priv(w) insert end "\n\n"
        puts -nonewline $tkhtml_priv(channel) "\n\n"
        return
    }
    if {$x == "\n" && $y == "\n"} return
    if {$y == "\n"} {
        $tkhtml_priv(w) insert end "\n"
        puts -nonewline $tkhtml_priv(channel) "\n"
        return
    }
    $tkhtml_priv(w) insert end "\n\n"
    puts -nonewline $tkhtml_priv(channel) "\n\n"
}
tkhtml_define_entity br {
    if {[$tkhtml_priv(w) get "end-2c"] != "\n"} {
        $tkhtml_priv(w) insert end "\n"
        puts -nonewline $tkhtml_priv(channel) "\n"
    }
}
########################################################################
tkhtml_define_entity i {
    incr tkhtml_priv(slant)
    tkhtml_set_tag
}
tkhtml_define_entity /i {
    incr tkhtml_priv(slant) -1
    tkhtml_set_tag
}
########################################################################
# <<BODY bgcolor=black>
tkhtml_define_entity  body {
    set ar(bgcolor) #d9d9d9
    tkhtml_parse_fields ar $argv
    set tkhtml_priv(bgcolor) $ar(bgcolor)
    $tkhtml_priv(w) configure -bg $tkhtml_priv(bgcolor)
    puts $tkhtml_priv(channel3) "\$widget1 configure -bg $tkhtml_priv(bgcolor)"
    $tkhtml_priv(w2) configure -bg $tkhtml_priv(bgcolor)
    puts $tkhtml_priv(channel3) "\$widget2 configure -bg $tkhtml_priv(bgcolor)"
}
tkhtml_define_entity /body {
    set tkhtml_priv(bgcolor) #d9d9d9
}
########################################################################
# tkhtml_define_entity ul {
#     set ar(type) disc
#     tkhtml_parse_fields ar $argv
#     if $tkhtml_priv(left) {
#         tkhtml_do br
#     } else {
#         tkhtml_do p
#     }
#     incr tkhtml_priv(left) $tkhtml_priv(indent_incr)
#     incr tkhtml_priv(left2) [expr $tkhtml_priv(indent_incr)+4]
#     tkhtml_push li_style $tkhtml_priv(li_style)
#     set tkhtml_priv(li_style) $ar(type)
#     set tkhtml_priv(li) 0
#     tkhtml_set_tag
# }
########################################################################
tkhtml_define_entity h1 { tkhtml_header 1 }
tkhtml_define_entity /h1 { tkhtml_/header 1 }
tkhtml_define_entity h2 { tkhtml_header 2 }
tkhtml_define_entity /h2 { tkhtml_/header 2 }
tkhtml_define_entity h3 { tkhtml_header 3 }
tkhtml_define_entity /h3 { tkhtml_/header 3 }
tkhtml_define_entity h4 { tkhtml_header 4 }
tkhtml_define_entity /h4 { tkhtml_/header 4 }
tkhtml_define_entity h5 { tkhtml_header 5 }
tkhtml_define_entity /h5 { tkhtml_/header 5 }
tkhtml_define_entity h6 { tkhtml_header 6 }
tkhtml_define_entity /h6 { tkhtml_/header 6 }

proc nbEspace {n} {
    set i 0
    set result ""
    while {$i < $n} {
        set result "$result "
        incr i
    }
    return $result
} ; # end proc nbEspace

proc ConstruitHeader {header indice oldText newText} {
# Renvoie la construction de l'index courant, par exemple si header=4, indice=4
# oldText=3.h4. et newText=3 alors la procedure renvoie 3.iv. 
    global tkhtml_priv
    if {$oldText == ""} {
        regsub -all "h$indice" $tkhtml_priv(headerStruct$header) \
            [tkhtml_number $tkhtml_priv(TYPE$indice) $newText] new
    } else {
        regsub -all "h$indice" $oldText \
            [tkhtml_number $tkhtml_priv(TYPE$indice) $newText] new
    }
    return $new
} ; # end proc ConstruitHeader

proc returnNextIndex {header} {
    global tkhtml_priv
    set currentIndex $tkhtml_priv(currentIndexNb)
    array set index {1 0 2 2 3 4 4 6 5 8 6 10}
    set firstPartOfIndexText ""
    set firstPartOfIndexNb ""
    set i 0
    if {$header == 1} {
        # On veut incrementer 1.2.3.4, avec header=1. i.e. on veut 2.
        regexp {([^\.]*)\.} $currentIndex match firstIndex
        set firstIndex [expr $firstIndex+1]
        set tkhtml_priv(currentIndexNb) "$firstIndex."
        return "[nbEspace $index(1)][ConstruitHeader $header 1 \
                                       $firstPartOfIndexText $firstIndex]"
    }
    set continueBoucle \
         [regexp -indices {([^\.]*)\.} $currentIndex match firstIndex]
    while {$continueBoucle} {
        incr i
        # On reconstruit 1.2.3
        set firstPartOfIndexNb \
            "$firstPartOfIndexNb[string range $currentIndex \
                                       [lindex $firstIndex 0] \
                                       [lindex $firstIndex 1]]."
        # On construit I.B.3
        set firstPartOfIndexText "[ConstruitHeader $header $i \
                                       $firstPartOfIndexText \
                                       [string range $currentIndex \
                                         [lindex $firstIndex 0] \
                                         [lindex $firstIndex 1]]]"
        set currentIndex [string range $currentIndex \
                                      [expr 1+[lindex $match 1]] end]
        set continueBoucle \
            [regexp -indices {([^\.]*)\.} $currentIndex match firstIndex]
        if {($i >= [expr $header-1])} {
            break
        }
    }
    
    if {!($continueBoucle)} {
        # On sort de la boucle car on a header=4 et currentIndex=1.2.3 par
        # exemple. On doit creer un nouveau rang ie renvoyer 1.2.3.1.
        if {([expr $header-$i] <= 1)} {
            # On affiche que si on a <h2>...</h2> puis <h3>...</h3>, on affiche
            # pas d'index si on a un <hY> suivit d'un <hX> avec X>Y+1
            set tkhtml_priv(currentIndexNb) "${firstPartOfIndexNb}1."
            return "[nbEspace $index($header)][ConstruitHeader $header\
                                                 [expr $i+1] \
                                                 $firstPartOfIndexText 1]"
        } else {
            return "error"
        }
    } else {
        # On a 1.2.3.4 et header=2 par exemple, on veut 1.3.
        regexp -indices {([^\.]*)\.} $currentIndex match firstIndex
        set match [string range $currentIndex \
                                       [lindex $firstIndex 0] \
                                       [lindex $firstIndex 1]]
        set tkhtml_priv(currentIndexNb) \
             "$firstPartOfIndexNb[tkhtml_number 1 [expr $match+1]]."
        return "[nbEspace $index($header)][ConstruitHeader $header \
                                             [incr i] \
                                             $firstPartOfIndexText \
                                             [expr $match+1]]"
    }
} ; # end proc returnNextIndex

proc tkhtml_header {level} {
    global tkhtml_priv
    tkhtml_do p
    if {$tkhtml_priv(firstHeader) == ""} {
        set tkhtml_priv(firstHeader) $level
    }
    set tkhtml_priv(in_header) 1
    tkhtml_push header $tkhtml_priv(header)
    set tkhtml_priv(header) $level
    set tkhtml_priv(points_ndx) [expr 6-$level]
    incr tkhtml_priv(weight)
    incr tkhtml_priv(headerCount)
    set tkhtml_priv(headerTag) header:header$tkhtml_priv(headerCount)
    tkhtml_set_tag
} ; # end proc tkhtml_header

proc tkhtml_/header {level} {
    global tkhtml_priv
    set tkhtml_priv(points_ndx) 2
    incr tkhtml_priv(weight) -1
    tkhtml_set_tag
    set tkhtml_priv(in_header) 0
    set temp [returnNextIndex [expr -$tkhtml_priv(firstHeader)\
                                    +$tkhtml_priv(header)+1]]
    if {[$tkhtml_priv(w2) get "end-2c"] != "\n"} {
        $tkhtml_priv(w2) insert end "\n"
        puts -nonewline $tkhtml_priv(channel1bis) "\n"
    }
    if {$temp != "error"} {
        # On ajoute l'index dans la fenetre \$widget2
        set tkhtml_priv(header$tkhtml_priv(headerCount)) \
                    [list header$tkhtml_priv(headerCount) black]
        $tkhtml_priv(w2) insert end "$temp $tkhtml_priv(headerText)" \
                [list HEADER header:header$tkhtml_priv(headerCount)]
        puts -nonewline $tkhtml_priv(channel1bis) \
            "$temp $tkhtml_priv(headerText)"
    }
    set tkhtml_priv(header) [tkhtml_pop header]
    set tkhtml_priv(headerText) ""
    set tkhtml_priv(headerTag) ""
    tkhtml_do p
} ; # end proc tkhtml_/header
tkhtml_define_entity pre { 
    tkhtml_push font $tkhtml_priv(font)
    set tkhtml_priv(font) $tkhtml_priv(fixed_font)
    tkhtml_set_tag
    tkhtml_do br
    incr tkhtml_priv(pre)
}
tkhtml_define_entity /pre {
    set tkhtml_priv(font) [tkhtml_pop font]
    tkhtml_set_tag
    set tkhtml_priv(pre) 0
    tkhtml_do p
}

tkhtml_define_entity hr {
    tkhtml_do p
    $tkhtml_priv(w) insert end "\n" hr
    puts -nonewline $tkhtml_priv(channel) "\n"
}
tkhtml_define_entity center {
    tkhtml_push justify $tkhtml_priv(justify)
    set tkhtml_priv(justify) C
    tkhtml_set_tag
}
tkhtml_define_entity /center {
    set tkhtml_priv(justify) [tkhtml_pop justify]
    tkhtml_set_tag
}
tkhtml_define_entity ul {
    set ar(type) disc
    tkhtml_parse_fields ar $argv
    if $tkhtml_priv(left) {
        tkhtml_do br
    } else {
        tkhtml_do p
    }
    incr tkhtml_priv(left) $tkhtml_priv(indent_incr)
    incr tkhtml_priv(left2) [expr $tkhtml_priv(indent_incr)+4]
    tkhtml_push li_style $tkhtml_priv(li_style)
    set tkhtml_priv(li_style) $ar(type)
    set tkhtml_priv(li) 0
    tkhtml_set_tag
}
tkhtml_define_entity /ul {
    incr tkhtml_priv(left) -$tkhtml_priv(indent_incr)
    incr tkhtml_priv(left2) -[expr $tkhtml_priv(indent_incr)+4]
    set tkhtml_priv(li_style) [tkhtml_pop li_style]
#     tkhtml_do p
    tkhtml_set_tag
}
########################################################################
tkhtml_define_entity blockquote {
    if $tkhtml_priv(left) {
        tkhtml_do br
    } else {
        tkhtml_do p
    }
    incr tkhtml_priv(left) $tkhtml_priv(indent_incr)
    incr tkhtml_priv(left2) [expr $tkhtml_priv(indent_incr)]
    incr tkhtml_priv(slant)
    tkhtml_set_tag
}
tkhtml_define_entity /blockquote {
    incr tkhtml_priv(left) -$tkhtml_priv(indent_incr)
    incr tkhtml_priv(left2) -[expr $tkhtml_priv(indent_incr)]
    incr tkhtml_priv(slant) -1
    tkhtml_set_tag
}
tkhtml_define_entity title { 
    set tkhtml_priv(in_title) 1 
}
tkhtml_define_entity /title {
    set tkhtml_priv(in_title) 0
}
tkhtml_define_entity a {
    # <a HREF=menu.html#M12 NAME=M13>...TEXTE...</a>
    tkhtml_parse_fields ar $argv
    tkhtml_push color $tkhtml_priv(color)
    tkhtml_push weight $tkhtml_priv(weight)
    tkhtml_push underline $tkhtml_priv(underline)
    tkhtml_push anchor_count $tkhtml_priv(anchor_count)
    tkhtml_push anchor_count2 $tkhtml_priv(anchor_count2)
    
    if [info exists ar(href)] {
        # Il y a HREF=...
        tkhtml_push href $ar(href)
        incr tkhtml_priv(underline)
        incr tkhtml_priv(anchor_count)
        set tkhtml_priv(color) blue
    } else {
        tkhtml_push href {}
    }
    if  [info exists ar(name)] {
        # Il y a NAME=...
        tkhtml_push aref $ar(name)
        incr tkhtml_priv(anchor_count2) 
        incr tkhtml_priv(weight)
    } else {
        tkhtml_push aref {}
    }
    tkhtml_set_tag
}
tkhtml_define_entity /a {
    tkhtml_pop href
    tkhtml_pop aref
    set tkhtml_priv(aref) ""
    set tkhtml_priv(color) [tkhtml_pop color]
    set tkhtml_priv(weight) [tkhtml_pop weight]
    set tkhtml_priv(underline) [tkhtml_pop underline]
    set tkhtml_priv(anchor_count) [tkhtml_pop anchor_count]
    set tkhtml_priv(anchor_count2) [tkhtml_pop anchor_count2] 
    tkhtml_set_tag
}
tkhtml_define_entity ol {
    set ar(type) 1
    tkhtml_parse_fields ar $argv
    if $tkhtml_priv(left) {
        tkhtml_do br
    } else {
        tkhtml_do p
    }
    tkhtml_push orderedListIndice $tkhtml_priv(orderedListIndice)
    set tkhtml_priv(orderedListIndice) 0
    incr tkhtml_priv(left) $tkhtml_priv(indent_incr)
    incr tkhtml_priv(left2) [expr $tkhtml_priv(indent_incr)+2]
    tkhtml_push li_style $tkhtml_priv(li_style)
    set tkhtml_priv(li_style) $ar(type)
    set tkhtml_priv(li) 0
    tkhtml_set_tag
}
tkhtml_define_entity /ol {
    set tkhtml_priv(orderedListIndice) [tkhtml_pop orderedListIndice]
    incr tkhtml_priv(left) -$tkhtml_priv(indent_incr)
    incr tkhtml_priv(left2) -[expr $tkhtml_priv(indent_incr)+2]
    set tkhtml_priv(li_style) [tkhtml_pop li_style]
    tkhtml_set_tag
}
tkhtml_define_entity menu {
    set ar(type) disc
    tkhtml_parse_fields ar $argv
    if $tkhtml_priv(left) {
        tkhtml_do br
    } else {
        tkhtml_do p
    }
    incr tkhtml_priv(left) $tkhtml_priv(indent_incr)
    incr tkhtml_priv(left2) [expr $tkhtml_priv(indent_incr)+4]
    tkhtml_push li_style $tkhtml_priv(li_style)
    set tkhtml_priv(li_style) $ar(type)
    set tkhtml_priv(li) 0
    tkhtml_set_tag
}
tkhtml_define_entity /menu {
    incr tkhtml_priv(left) -$tkhtml_priv(indent_incr)
    incr tkhtml_priv(left2) -[expr $tkhtml_priv(indent_incr)+4]
    set tkhtml_priv(li_style) [tkhtml_pop li_style]
    tkhtml_set_tag
}
proc tkhtml_number {type count} {
	switch -- $type {
	    A -
	    a {
		# Count a, b, c, ..., z, aa, ab, ac, ..., az, ba, bb, bc
		# which is odd, because in the '1's position a means 0,
		# but in the '10's and '100's position a means 1...
		# (imagine lists count from 0: a => 0, but aa => 10) 
		scan $type %c A
		set result ""
		while {$count > 0} {
		    set result [format %c [expr $A + (($count-1) % 26)]]$result
		    set count [expr ($count-1) / 26]
		}
		return $result
	    }
	    i -
	    I {
		# Count with roman numbers
		# i, ii, iii, iv, v, vi, viii, ix, x
		set one I ; set five V ; set ten X
		set result ""
		while {$count > 0} {
		    set frac [expr $count % 10]
		    switch $frac {
			1 {set result $one$result}
			2 {set result $one$one$result}
			3 {set result $one$one$one$result}
			4 {set result $one$five$result}
			5 {set result $five$result}
			6 {set result $five$one$result}
			7 {set result $five$one$one$result}
			8 {set result $five$one$one$one$result}
			9 {set result $one$ten$result}
		    }
		    set count [expr $count / 10]
		    switch $one {
			I {set one X ; set five L ; set ten C}
			X {set one C ; set five D ; set ten M}
			C {set one M ; set five ? ; set ten !}
			default {set one ! ; set five # ; set ten @}
		    }
		}
		if {$type == "i"} {
		    return [string tolower $result]
		} else {
		    return $result
		}
	    }
	    1 -
	    default { 
		return $count
	    }
	}
} ; # end proc tkhtml_number

tkhtml_define_entity li {
    tkhtml_do br
    if {$tkhtml_priv(li_style) == "disc" ||
        $tkhtml_priv(li_style) == "circle" ||
        $tkhtml_priv(li_style) == "square"} {
        array set li_style {disc \xb7 circle o square \xb9}
        set old_font $tkhtml_priv(font)
        set tkhtml_priv(font) symbol
        tkhtml_set_tag
        $tkhtml_priv(w) insert end "$li_style($tkhtml_priv(li_style))" \
                                   $tkhtml_priv(tag)
        puts -nonewline $tkhtml_priv(channel) \
                        "$li_style($tkhtml_priv(li_style))"
        set tkhtml_priv(font) $old_font
        tkhtml_set_tag
    } elseif {$tkhtml_priv(li_style) == "1" ||
              $tkhtml_priv(li_style) == "A" ||
              $tkhtml_priv(li_style) == "I" ||
              $tkhtml_priv(li_style) == "i"} {
        incr tkhtml_priv(orderedListIndice)
        set old_font $tkhtml_priv(font)
#         set tkhtml_priv(font) symbol
        tkhtml_set_tag
        $tkhtml_priv(w) configure -tabs {2c left}
        $tkhtml_priv(w) insert end \
             "[tkhtml_number $tkhtml_priv(li_style) \
                            $tkhtml_priv(orderedListIndice)]." \
             $tkhtml_priv(tag)
        puts -nonewline $tkhtml_priv(channel) \
             "[tkhtml_number $tkhtml_priv(li_style) \
                            $tkhtml_priv(orderedListIndice)]."
        set tkhtml_priv(font) $old_font
        tkhtml_set_tag
    } else {
        puts "Wrong TYPE : $tkhtml_priv(li_style)"
    }
}
tkhtml_define_entity dl {
    # On memorise l'espace de tabulation
    tkhtml_push left $tkhtml_priv(left)
    tkhtml_push left2 $tkhtml_priv(left2)
    tkhtml_set_tag
}
tkhtml_define_entity dt {
    if $tkhtml_priv(left) {
        tkhtml_do br
    } else {
        tkhtml_do p
    }
    set tkhtml_priv(left) [tkhtml_peek left]
    set tkhtml_priv(left2) [tkhtml_peek left2]
    set tkhtml_priv(dd) 0
    tkhtml_set_tag
}
tkhtml_define_entity dd {
    tkhtml_do br
    if {$tkhtml_priv(dd) == 0} {
        # On incremente l'espace de tabulation
        incr tkhtml_priv(left) $tkhtml_priv(indent_incr)
        incr tkhtml_priv(left2) $tkhtml_priv(indent_incr)
        set tkhtml_priv(dd) 1
    }
    tkhtml_set_tag
}
tkhtml_define_entity /dl {
    # On restaure l'espace de tabulation
    set tkhtml_priv(left) [tkhtml_pop left]
    set tkhtml_priv(left2) [tkhtml_pop left2]
    tkhtml_set_tag
    tkhtml_do br
}
tkhtml_define_entity strike {
    tkhtml_push strike $tkhtml_priv(strike)
    set tkhtml_priv(strike) 1
    tkhtml_set_tag
}
tkhtml_define_entity /strike {
    set tkhtml_priv(strike) [tkhtml_pop strike]
    tkhtml_set_tag
}
tkhtml_define_entity u {
    tkhtml_push underline $tkhtml_priv(underline)
    set tkhtml_priv(underline) 1
    tkhtml_set_tag
}
tkhtml_define_entity /u {
    set tkhtml_priv(underline) [tkhtml_pop underline]
    tkhtml_set_tag
}
tkhtml_define_entity listing { tkhtml_do pre }
tkhtml_define_entity /listing { tkhtml_do /pre }

# Procedure utilisee lors de la creation d'image avec le compilateur
# html2htcl
proc createImage {dir file} {
    image create photo -file [file join $dir $file]
} ; # end proc createImage

tkhtml_define_entity img {
    set ar(align) center
    tkhtml_parse_fields ar $argv
    if {$ar(align) == "middle"} {
        set ar(align) "center"
    }
    if [info exists ar(src)] {
        set file $ar(src)
        if [info exists tkhtml_priv(image_hook)] {
            if [info exists tkhtml_priv(imagePath)] {
                set file [file join $tkhtml_priv(imagePath) $file]
            }
            if [file exists $file] {
                set img [eval $tkhtml_priv(image_hook) [pwd] $ar(src)]
                puts $tkhtml_priv(channel) "\}"
                puts $tkhtml_priv(channel) \
                     "set img \[eval $tkhtml_priv(image_hook) \$imageDir $ar(src)\]"
            } else {
                return
            }
        } else {
            if [catch {set img [image create photo -file $file]} err] {
                puts stderr "Couldn't create image $file: $err"
                return
            }
        }
        set align bottom
        if [info exists ar(align)] {
            set align [string tolower $ar(align)]
        }
        if {[$tkhtml_priv(w) get "end-2c"] == "\n"} {
            $tkhtml_priv(w) insert end " " $tkhtml_priv(tag)
            puts $tkhtml_priv(channel) "\$widget1 insert end \" \""
        }
        label $tkhtml_priv(w).$img -image $img \
                -background $tkhtml_priv(bgcolor)
        $tkhtml_priv(w) window create end -window $tkhtml_priv(w).$img \
            -align $align
        # puts [$tkhtml_priv(w).$img configure]
        puts $tkhtml_priv(channel) "label \$widget1.\$img -image \$img \
            -background $tkhtml_priv(bgcolor)"
        puts $tkhtml_priv(channel) "\$widget1 window create end \
            -window $tkhtml_priv(w).\$img -align $align"
        puts -nonewline $tkhtml_priv(channel) "\$widget1 insert end \{"
        set tkhtml_priv(windowBefore) 1
    }
}

########################################################################
# find HTML escape characters of the form &xxx;
proc tkhtml_map_esc {text} {
        if {![regexp & $text]} {return $text}
        regsub -all {([][$\\])} $text {\\\1} new
        regsub -all {&#([0-9][0-9]?[0-9]?);?} \
                $new {[format %c [scan \1 %d tmp;set tmp]]} new
        regsub -all {&([a-zA-Z0-9]+);?} $new {[tkhtml_do_map \1]} new
        return [subst $new]
} ; # end proc tkhtml_map_esc

# convert an HTML escape sequence into character
proc tkhtml_do_map {text {unknown ?}} {
        global tkhtml_priv
        set result $unknown
        catch {set result $tkhtml_priv($text)}
        return $result
} ; # end proc tkhtml_do_map

# table of escape characters (ISO latin-1 esc's are in a different table)
array set tkhtml_priv {
   lt <   gt >   amp &   quot \"   copy \xa9
   reg \xae   ob \x7b   cb \x7d   nbsp \xa0
}
# ISO Latin-1 escape codes

array set tkhtml_priv {
        nbsp \xa0 iexcl \xa1 cent \xa2 pound \xa3 curren \xa4
        yen \xa5 brvbar \xa6 sect \xa7 uml \xa8 copy \xa9
        ordf \xaa laquo \xab not \xac shy \xad reg \xae
        hibar \xaf deg \xb0 plusmn \xb1 sup2 \xb2 sup3 \xb3
        acute \xb4 micro \xb5 para \xb6 middot \xb7 cedil \xb8
        sup1 \xb9 ordm \xba raquo \xbb frac14 \xbc frac12 \xbd
        frac34 \xbe iquest \xbf Agrave \xc0 Aacute \xc1 Acirc \xc2
        Atilde \xc3 Auml \xc4 Aring \xc5 AElig \xc6 Ccedil \xc7
        Egrave \xc8 Eacute \xc9 Ecirc \xca Euml \xcb Igrave \xcc
        Iacute \xcd Icirc \xce Iuml \xcf ETH \xd0 Ntilde \xd1
        Ograve \xd2 Oacute \xd3 Ocirc \xd4 Otilde \xd5 Ouml \xd6
        times \xd7 Oslash \xd8 Ugrave \xd9 Uacute \xda Ucirc \xdb
        Uuml \xdc Yacute \xdd THORN \xde szlig \xdf agrave \xe0
        aacute \xe1 acirc \xe2 atilde \xe3 auml \xe4 aring \xe5
        aelig \xe6 ccedil \xe7 egrave \xe8 eacute \xe9 ecirc \xea
        euml \xeb igrave \xec iacute \xed icirc \xee iuml \xef
        eth \xf0 ntilde \xf1 ograve \xf2 oacute \xf3 ocirc \xf4
        otilde \xf5 ouml \xf6 divide \xf7 oslash \xf8 ugrave \xf9
        uacute \xfa ucirc \xfb uuml \xfc yacute \xfd thorn \xfe
        yuml \xff
}
########################################################################
