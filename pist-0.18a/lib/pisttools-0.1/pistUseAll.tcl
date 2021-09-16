

## pist -- gestion du "m�tapackage" qu'est la librairie pist
# 
package provide pist 0.1

# Pist_PackageRequireAll -- d�clare tous les package de pist
# 
# Cette proc�dure simplifie l'utilisation de l'ensemble des 
# packages de pist, car est est (ou SERA) mise � jour automatiquement
# en cas de nouveaux package ou r�organisation (changement de nom 
# de package, ...) 
# 
# exemple :
#   1 - s'assurer que la librairie du r�pertoire de pist est dans 
#       l'auto_path :
#            set auto_path [linsert $auto_path 0 /../pist-0.2/lib]
# 
#   2 - D�clarer ce pr�sent package :
#            package require pist
# 
#   3 - Ex�cuter la proc�dure :
#            Pist_PackageRequireAll
# 
# 
# 
proc Pist_PackageRequireAll {} {

    package require box
    package require canvas
    package require cmdentry
# #     package require epsf
    package require file
    
# #     Il faut revoir hview en temps que package : ne doitcontenir 
# #     que des procedure, ou que des commande TCL (pas de tk tel 
# #      que winfo, ...)
    package require hview
    package require pist_smtp
    
    # package require menu
    package require pref
    package require prompt
    package require shell
    # package require stead
    package require tclx
    # package require text
    # package require util
    package require xtcl
    # package require parsarg
    
}
