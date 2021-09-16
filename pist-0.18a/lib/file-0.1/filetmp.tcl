package provide file 0.1

# proc file:tmpFileName provide a valide temporary file name

################################################################################
# from diam@ensta.fr
# 
# file:tmpFileName   ?-option <value>?
# return a new tmp file name.
# options:
#    -basename <basename> : name to use instead of the appli
#    -suffix <suffix> : suffix of tmp file (default to ".tmp")
#    -dir <dir> : directory of tmp file
#         default dir is platteform dependant:
#          $env(TMPDIR) if it exists else :
#          /tmp         on unix
#          $env(TEMP)   on Macintosh (usualy top level of System HD)
#          /            on windows (by I'm not sure it's good)
# 
# Example :
#    file:tmpFileName    (if the script is called "edit.exe")
#       return /tmp/edit002.tmp
#    file:tmpFileName   -basename stead   -suffix ""   -dir .
#       return ./stead003 
# 
proc file:tmpFileName { args } {
    global env tcl_plateform
    
    # calculate a default Tmp Directory
    if {[info exists env(TMPDIR)]} {
        set defaultTmpDir $env(TMPDIR)
    } else {
        switch -exact -- $tcl_plateform(plateform) {
          macintosh {  set defaultTmpDir   $env(TEMP)  } 
          windows   {  set defaultTmpDir   /           } 
          unix      {  set defaultTmpDir   /tmp        } 
        }
    } 

    # setting default options:
    set arga(-basename) [file basename [file tail [info script]]]
    set arga(-suffix)   ".tmp"
    set arga(-dir)      $defaultTmpDir
    
    # reading user options:
    array set arga $args
    set basename $arga(-basename) 
    set suffix   $arga(-suffix)   
    set dir      $arga(-dir)           

    if {!([file isdirectory $dir] && [file writable $dir])} {
        error "$dir is not a writable directory"
    }

    set uid 0
    set name [format "%s%03d%s" $basename $uid $suffix]
    set tmpfile [file join $dir $name]
    while {[file exists $tmpfile]} {
        if {[incr uid] > 999} {return 0}
        set name [format "%s%03d%s" $basename $uid $suffix]
        set tmpfile [file join $dir $name]
    }
    return $tmpFileName
} ;# endproc file:tmpFileName

