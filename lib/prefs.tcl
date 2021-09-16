# Fichier pr�f�rence.tcl<BR>
# contient la d�finition des pr�f�rence et autres options de gred
#
# <A HREF="mailto:diam@ensta.fr>diam@ensta.fr</A> le 29/06/96<BR>

########################################################################
# gred:initPrefs --
# 
# 
# 
proc gred:initPrefs args {
global gred

    # Initiliastion du package pref de pist
    # 
    # Initialisation des pr�f�rences par d�faut :
    # report -t "    Pref_Init $gred(setup,localfilerc)\
    #        $gred(setup,userfilerc)..."   
    Pref_Init $gred(setup,localfilerc) $gred(setup,userfilerc) 
    # report -t "    Pref_Init FAIT"   


    # initialisation des variables globales non accessibles par l'utilisateur
    
    set gred(cursor,withSelection) "iron_cross"
    
    set gred(etape,border) 2
    
    set gred(etape,options) {type name state action file comment}
    set gred(etape,type) {Normal Initial Hyper Macro MacroBegin MacroEnd}
    set gred(etape,name) {"Etape normale" "Etape initiale" "Hyper �tape"\
                          "Macro �tape" "D�but de macro �tape" \
                          "Fin de macro �tape"}
    set gred(etape,state) {active inactive}
    
    set gred(transition,options) {name receptivity comment}
    
    set gred(grid) 25   ;# pixel pour l'instant, puis : 0.5cm
    
    # L'initialisation des preferences (Pref_Init) est report�e dans 
    # dans la proc�dure gred:start)

    Pref_Add {-group General
      -var gred(admin)   -xres admin -default 1
      -type BOOLEAN
      -comment "Privil�ge d'administrateur de gred"
      -help "Permet d'avoir un (ou des) menu suppl�mentaire pour la\
       gestion et la maintenance de cette application"
    }
    Pref_Add {-group General
      -var gred(untitled)
      -type STRING
      -default "Untitled\t\t"
      -comment "Titre par d�fault"
    }
    Pref_Add {-group General
      -var gred(userMail)
      -type STRING
      -comment "Adresse e-mail de l'utilisateur"
      -default "diam@ensta.fr"
      -help "Pr�f�rence n�cessaire pour permettre de faire des \"bugs reports\" � l'�quipe de developpement."
    }
    # Pref_Add {-group General
    #   -var gred(geometry)
    #   -xres geometry
    #   -default 10+10x400x700
    #   -type GEOMETRY
    #   -comment "G�ometrie de l'application"
    # }
    
    # Groupe "Grafcet" : aspect graphique g�n�ral.
    # # set gred(fontSize) 8 ;
    # # Pref_Add {-group Grafcet
    # #   -var gred(fontSize)
    # #   -default 12
    # #   -type LENGTH
    # #   -comment "Taille du texte"
    # #   -help "BLA BLA BLA BLA :-)"
    # # }
    # # Pref_Add {-group Grafcet
    # #   -var gred(fontGrafcet)
    # #   -default {-*-courier-bold-r-normal-*-12-*-*-*-*-*-iso8859-*}
    # #   -type FONTE
    # #   -comment "Fonte du grafcet"
    # #   -help "Utilis�e pour les noms d'�tape, de transition, d'action, ..."
    # # }
    Pref_Add {-group Grafcet
      -var gred(fontGrafcet)
      -default {courier 12 bold}
      -type FONTE
      -comment "Fonte du grafcet"
      -help "Utilis�e pour les noms d'�tape, de transition, d'action, ..."
    }
    Pref_Add {-group Grafcet
      -var gred(sequence,yStep)
      -default 60
      -type LENGTH
      -comment "Pas entre �tape/transition pour la cr�ation de s�quence"
    }
    # 
    Pref_Add {-group Grafcet
      -var gred(grid,color)
      -default #88F
      -type COLOR
      -comment "Couleur de la grille"
    }
    #
    Pref_Add {-group Grafcet
      -var gred(defaultSourceObjectType)
      -default Etape
      -type ENUM
      -typeargs {Etape Trans}
      -comment "Type d'objet source � cr�er par d�faut"
      -help "Le type de l'objet cr�� lorsqu'on clique sur une zone vide\
             peut etre modifi� temporairement par appui sur <Alt> (suivant\
             la plateforme) au moment du clique."
    }
    
    Pref_Add {-group Etape
      -var gred(etape,height) 
      -xres etapeWidth 
      -default 35
      -type LENGTH
      -comment "Largeur d'une �tape"
    }
    # Pref_Add {-group Etape
    #   -var gred(etape,border) 
    #   -xres etapeBorder 
    #   -default 2
    #   -type LENGTH
    #   -comment "Epaisseur du trait entourant l'�tape"
    # }
    Pref_Add { -group Etape
      -type COLOR
      -var gred(look,etapeBackground) 
      -default white
      -comment "Couleur du fond d'�tape"
    }
    Pref_Add { -group Etape
      -type STRING
      -var gred(etape,nameIndex) 
      -default X1
      -comment "Indexation du nom des �tapes"
      -help "Les noms des �tapes se d�clineront suivants le nom sp�cifi�.\
            \nPar exemple, si vous entrer X1n, tous les noms seront\
            X1n, X2n, X3n, etc..."
    }
    
    Pref_Add {-group Transition
      -var gred(transition,width) 
      -xres transitionWidth 
      -default 25
      -type LENGTH
      -comment "Largeur d'une transition"
    }
    Pref_Add {-group Transition
      -var gred(transition,showName) 
      -default 1
      -type BOOLEAN
      -comment "Afficher le nom de la transition ?"
      -help "Pr�f�rence p�rmettant d'afficher ou non le nom d'une\
             transition.\nSi cette option est valid�e, le nom de la transition\
             s'affichera � gauche de celle-ci."
    }
    Pref_Add {-group Transition
      -var gred(transition,height) 
      -xres transitionHeight 
      -default 4
      -type LENGTH
      -comment "Hauteur d'une transition"
    } 
    Pref_Add {-group Transition
      -var gred(transition,link) 
      -xres transitionLink 
      -default 5
      -type LENGTH
      -comment "Longueur mini du lien cot� d'une transition"
    } 
    Pref_Add {-group Transition
      -var gred(doubleLine,height) 
      -xres doubleLineHeight 
      -default 4
      -type LENGTH
      -comment "Distance entre les doubles lignes d'une transition"
    }
    Pref_Add { -group Transition
      -type STRING
      -var gred(transition,nameIndex) 
      -default T1
      -comment "Indexation du nom des transitions"
      -help "Les noms des transitions se d�clineront suivants le nom\
            sp�cifi�.\
            \nPar exemple, si vous entrer X1n, tous les noms seront\
            X1n, X2n, X3n, etc..."
    }
    ####################################################################
    ## Groupe Link : gestion et apparence des liens
    ####################################################################
    Pref_Add {-group Link
      -var gred(link,width) 
      -xres linkWidth 
      -default 2
      -type LENGTH
      -comment "Epaisseur des liens"
      -help "Cette dimension est �galement utilis�e pour l'�paisseur\
             des doubles lignes."
    }
    Pref_Add {-group Link
      -var gred(link,handlesize) 
      -xres handleSize 
      -default 3
      -type LENGTH
      -comment "Taille des poign�es d'�dition des liens"
      -help "Cette dimension repr�sente le demi cot� des poign�es\
             lors de l'�dition des liens."
    }
    

    ####################################################################
    ####################################################################
    ####################################################################
    ###### A VIRER BIENTOT
    ####################################################################
    Pref_Add {-group Transition
      -var gred(doubleLine,offset) 
      -xres doubleLineOffset 
      -default 5
      -type LENGTH
      -comment "Longueur min du d�placement lat�rale d'une double ligne"
    } 
    ####################################################################
    ####################################################################
    ####################################################################
    ####################################################################
    
    Pref_Add {-group Transition
      -var gred(doubleLine,xOffset) 
      -xres doubleLineXOffset 
      -default 5
      -type LENGTH
      -comment "Longueur minimale du d�placement lat�ral d'une double ligne"
    } 
    Pref_Add {-group Transition
      -var gred(doubleLine,yOffset) 
      -xres doubleLineYOffset 
      -default 10
      -type LENGTH
      -comment "Longueur minimale du segment de droite entre une\
                transiton et sa double ligne"
    } 

    
    Pref_Add {-group Look
      -var canvas(scrollside) -xres scrollbarSide -default right
      -type ENUM   -typearg {left right}
      -comment "Position de la scrollBar"
      -help "La barre de d�filement verticale d'un widget text ou d'un\
       canvas peut etre plac�e � droit (right) ou � gauche (left)"
    } 
    
    Pref_Add { -group Look
      -type COLOR
      -var gred(look,transitionBackground) 
      -default black
      -comment "Couleur du fond de transition"
    }    
    
    Pref_Add { -group Look
      -type COLOR
      -var gred(look,canvasBackground) 
      -xres canvasBackground 
      -default white
      -comment "Couleur du fond de la fen�tre principale"
    }    
    
    Pref_Add { -group Canvas
      -type COLOR
      -var gred(virtualColor) 
      -xres virtualColor 
      -default red
      -comment "Couleur des objets virtuels"
      -help "Les objets virtuels sont le rectangle de s�lection, les liaisons\
             en cours d'�dition et les \"fant�mes\" d'objet en cours de \
             d�placement."
    }    
    
    Pref_Add {-group Canvas
      -var canvas(overlappingDelta)
      -default 2
      -type LENGTH
      -comment "Distance de s�lection (overlapping)."
      -help "Distance en dessous de laquelle un objet est consid�r�\
             comme �tant \"sous la souris\""
    }
    Pref_Add {-group Canvas
      -var canvas(dragDelta)
      -default 10
      -type LENGTH
      -comment "Distance mini de d�placement souris."
      -help "Distance minimale n�cessaire pour qu'un d�placement de souris\
             soit pris en compte"
    }

    # La taille du canvas devrait �tre A2 mais une imprimante ne pouvant
    # pas imprimer sur les bords d'une page il est plus judicieux de
    # diminuer la taille canvas pour se mettre � l'abrit des problemes !
    # (bidouille...) 
    # 
    # Toute modif d'une de ces valeur doit entrainer la commande
    #   $canvas configure -scrollregion \
    #           [ list 0 0  $gred(canvas,width) $gred(canvas,height) ]
    # 
    Pref_Add {-group Canvas
      -var gred(canvas,width)
      -default 21c 
      -postcommand  {gred:updateCanvasSize ".[g]"}
      -comment "Largeur du canvas"
      -help "Largeur du canvas (A4v: 21c, A3v: 29.7c, ...)"
    }
    Pref_Add {-group Canvas
      -var gred(canvas,height)
      -default 29.7c
      -postcommand  {gred:updateCanvasSize ".[g]"}
      -comment "Hauteur du canvas"
      -help "Hauteur du canvas (A4v: 29.7c, A3v: 42c,  ...)"
    }
    
    option add *draw.c.width 20c
    option add *draw.c.height 10c
    # option add *draw.c.scrollRegion {0 0 42c 59.4c}
    

    Pref_Add {-group Selection
      -var gred(drag,limit)
      -default 5
      -type LENGTH
      -comment "Limite de d�clenchement du mode Drag"
    }
    Pref_Add {-group Selection
      -var gred(sel,color)
      -default red
      -type COLOR
      -comment "Couleur de la s�lection"
    }
    Pref_Add {-group Selection -type ENUM
      -var gred(selectMode)
      -typearg {enclosed overlapping}
      -default enclosed
      -comment "Mode de capture de la s�lection"
      -help "Indique si le rectangle de s�lection doit enti�rement\
             (enclosed) ou partiellement (overlapping) entourer les objets\
             pour les s�lectionner."
    }
    
    global tcl_platform
    switch -exact -- $tcl_platform(platform) {
      macintosh {
        set Meta Command
      } 
      windows {
        set Meta Alt
      } 
      unix {
        set Meta Meta
      } 
    } 
    Pref_Add [subst {-group Bindings
      -type ENUM
      -typearg {Alt Meta Command}
      -var gred(Meta)
      -default $Meta
      -comment "D�finition de la touche Meta"
    }]
    Pref_Add {-group Bindings
      -type ENUM
      -typearg {Shift Control Meta Alt}
      -var gred(shift)
      -default Shift
      -comment "D�finition de la touche Shift"
    }
    Pref_Add {-group Bindings
      -type ENUM
      -typearg {pages units}
      -var gred(arrowScroll)
      -default units
      -comment "Mode de d�placement � l'aide des fl�ches"
      -help "Si vous choisissez \"pages\" le d�placement � l'aide des\
        fl�ches se fera pages par pages.\
        \nSinon il se fera par petits d�placements successifs."
    }
}

## gred:setCanvasSize -- modifie la taille du canvas ra une chain (A4v, A4h...)
# 
# TODO : compl�ter le traitement des arguments
# 
proc gred:setCanvasSize { args } {
global gred
    
    set args [string tolower $args]
    switch -exact -- $args {
        a4 -
        a4v {
            set gred(canvas,width)   21c
            set gred(canvas,height)  29.7c
        }                            
        a4h {                        
            set gred(canvas,width)   29.7c
            set gred(canvas,height)  21c
        }                           
        a3 -
        a3v {
            set gred(canvas,width)   29.7c
            set gred(canvas,height)  42c
        }
        a3h {
            set gred(canvas,width)   42c
            set gred(canvas,height)  29.7c
        }
        a2 -
        a2v {
            set gred(canvas,width)   42c
            set gred(canvas,height)  59.4c
        }
        a2h {
            set gred(canvas,width)   59.4c
            set gred(canvas,height)  42c
        }
        a1 -
        a1v {
            set gred(canvas,width)   59.4c
            set gred(canvas,height)  84c
        }
        a1h {
            set gred(canvas,width)   84c
            set gred(canvas,height)  59.4c
        }
        default {
            error "taille de canvas non reconnue pour l'instant : $size"
        }
    }
    gred:updateCanvasSize ".[g]"
    
}
