package provide shell 0.1

# Emulation multiplateforme de la commande unix grep
# Attention args est une LISTE de PATTERNES !!
# 
# ATTENTION : voir la version de tcllib :
# 
#     package require tcllib
#     set listOfMatches [fileutil::grep $_pattern]            ;# (stdin input)
#     set listOfMatches [fileutil::grep $_pattern $_fileList]
# 
proc Grep {pat args} {
    set mode -regexp
    
    if {[llength $args] == 0} {set args ".* *"}
    
    set files [eval glob $args]
    
    foreach file $files {
        if {![file isfile $file]} { continue }
        for_file line $file {
            switch $mode -- $line $pat {
                puts "$file : $line"
            }             
        }
    }
} ;#endproc file:grep
