########################################################################
# fichier pref.tcl
# initialement fourni en exemple du livre de Brent WELCH
# 
# Voir le fichier pref2.tcl pour les proc»dures compl»mentaires, la  
# documentation et un exemple
########################################################################
package provide pref 0.2

proc PrefStatus { args } {
    global pref
    set args [join $args]

    set pref(status) $args
    
    catch {
        # Le widget text pref(status_text) peut ne pas etre encore cr»» !
        $pref(status,text) configure -state normal
        update idletask
        $pref(status,text) delete 0.0 end
        $pref(status,text) insert 0.0 $args
        $pref(status,text) configure -state disabled
        update idletask
    }
}


proc Pref_Init {appPrefsDefault userPrefsDefault args} {

    global pref
    catch {unset pref}
    catch {destroy .pref}
    
    # initialisation of the options
    array set arga {
        -reportProc PrefStatus
        -groupmode listbox
    }
    # reading options
    array set arga $args
    
    # type of dialog to display (listbox, popup, buttons, auto)
    set pref(groupMode) $arga(-groupmode)
    
    # for a unique identifier for groups, prefs or widget 
    set pref(uid) 0

    set pref(userPrefsDefault) $userPrefsDefault
    set pref(appPrefsDefault)  $appPrefsDefault

    set pref(null)       "pref_null_value"  ;# for using instead ""
    set pref(groupNames) {} 
    set pref(varNames)   {}
    set pref(defaultGroupName) "Group1"
    
    if [catch {$arga(reportProc)} "initialising Prefs"] {
        set pref(reportProc) PrefStatus
    } else {
        set pref(reportProc) $arga(reportProc)
    }

    # Quelques constantes d'affichage :
    set pref(msg,source_file_error) "Error in source file"
    # set pref(msg,no_comment) "No comment available for this pref"
    set pref(msg,no_help) "No help available for this pref"
    
    PrefSourceFile $appPrefsDefault 
    PrefSourceFile $userPrefsDefault 
}

# # proc PrefType    { item } { lindex $item 0 }
# proc PrefType    { item } { lindex [lindex $item 0] 0 }
# proc PrefTypeArg { item } { lindex [lindex $item 0] 1 }
# proc PrefGroup   { item } { lindex $item 1 }
# proc PrefVar     { item } { lindex $item 2 }
# proc PrefXres    { item } { lindex $item 3 }
# proc PrefDefault { item } { lindex $item 4 }
# proc PrefComment { item } { lindex $item 5 }
# proc PrefHelp    { item } { lindex $item 6 }

proc PrefSourceFile { filename } {
    global pref
    if [catch {uplevel #0 "source $filename"} err] {
        $pref(reportProc) "$pref(msg,source_file_error) $filename: $err"
    }
}
# Pref_Add {prefs ...}
# -var      Variable name (eg. GRED(admin), FILENAME, ...)
# -xres     resource name associated with varName
# -group    group names of this pref (default is the last choosen group)
# -type     type of the var eg. : ENUM   (default = STRING)
# -typeargs argument for type eg : {blue green red} (default undefined)
# -default  default value for var {default to "")
# -comment  label for var {default to "")
# -help     help about var (default: $pref(msg,no_help))

proc Pref_Add { prefSpecif } {
    global pref

    # init of the param.
    array set arga "
        -var          pref(null)
        -xres         $pref(null)
        -type         STRING
        -typearg      {}
        -default      {}
        -group        [list $pref(defaultGroupName)]
        -postcommand  {}
        -comment      {}
        -help         [list $pref(msg,no_help)]
    "
    # reading arguments in array "arga"
    array set arga $prefSpecif       
    set gn $arga(-group)              ;# group name
    
    # "var" can be pref(null) if we only want a separator in the group, so
    # we generate an unique identifier for a foo varName like "pref(null32)"
    if {"$arga(-var)" == "pref(null)"} {
        set vn pref(null[incr pref(uid)])
    } else {
        set vn $arga(-var)
    }
    lappend pref(varNames) $vn
    
    # find the groupName of this pref:
    set gn $arga(-group)
    if {[lsearch -exact $pref(groupNames) $gn] == -1} {
        # create the new groupName
        set pref(gn$gn,varNames) {}  ;# in Pref_Dialog ???
        lappend pref(groupNames) $gn
    }
    # record this groupName as future default groupName
    set pref(currentGroupName) $gn
    
    lappend pref(gn$gn,varNames) $vn   ;# in Pref_Dialog ???
    
    # record all info for this varName:
    set pref(vn$vn,group)           $gn
    set pref(vn$vn,type)            [string toupper $arga(-type)]
    set pref(vn$vn,typearg)         $arga(-typearg)
    set pref(vn$vn,xres)            $arga(-xres)
    set pref(vn$vn,default)         $arga(-default)
    set pref(vn$vn,postcommand)     $arga(-postcommand)
    set pref(vn$vn,comment)         $arga(-comment)
    set pref(vn$vn,help)            $arga(-help)
                    
    PrefValueSetIfUndefined $vn 
}
proc PrefValueSet { varName args } {
    if {[llength $args] == 0} {
        return [uplevel #0 [list set $varName] ]
    } else {
        return [uplevel #0 [list set $varName $args] ]
    }
    # eval uplevel #0 [list set $varName] [list $args]  ;# ˝ tester]
}
proc PrefValueGet { varName } {
    return [uplevel #0 [list set $varName] ]
}
proc PrefValueSetIfUndefined { vn } {
    global pref
    upvar #0    $vn    var
    set default $pref(vn$vn,default)
    set xres    $pref(vn$vn,xres)
    
    # Set variables that are still not set
    if ![info exist var] {
        set value [option get . $xres {}]
        if {"$value" != ""} {
            set var $value
        } else {
            set var $default
        }
    } 
}

