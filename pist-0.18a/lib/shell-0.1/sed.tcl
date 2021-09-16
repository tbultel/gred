package provide shell 0.1

## sed -- 
# 
# From wikit
# 
# Example usage: 
# 

# Doing a full sed replacement is hard. It is better to just write a
# Tcl program/procedure from scratch that implements the
# functionality. This is probably easier though if someone implements
# some kind of line iterator (suitable for most simple uses of sed
# where all you want to do is apply a substitution to each line of a
# file/stream or only print some lines.) It is probably easier to
# just run sed externally (with [exec]) for anything that is very
# complex and where you've not the time to reimplement. 
# 
# However, as a little goodie, here are some alternatives to very
# common sed commands... 
# 

## sed:substFile -
# 
# sed "s/RE/replacement/" <inputFile >outputFile 
# 
proc sed:substFile {regexp replacement inputFile outputFile} {
    set fin [open $inputFile r]
    set fout [open $outputFile w]
    while {[gets $fin linein] >= 0} {
        regsub $regexp $linein $replacement lineout
        puts $fout $lineout
    }
    close $fin
    close $fout
}


## sed:substGlobalFile --
# 
# sed "s/RE/replacement/g" <inputFile >outputFile 
# 
proc sed:substGlobalFile {regexp replacement inputFile outputFile} {
    set fin [open $inputFile r]
    set fout [open $outputFile w]
    while {[gets $fin linein] >= 0} {
        regsub -all $regexp $linein $replacement lineout
        puts $fout $lineout
    }
    close $fin
    close $fout
}

## sed:transformFile --
# 
# sed "y/abc/xyz/" <inputFile >outputFile
# 
proc sed:transformFile {from to inputFile outputFile} {
    set map {}
    foreach f [split $from {}] t [split $to {}] {
        lappend map $f $t
    }
    set fin [open $inputFile r]
    set fout [open $outputFile w]
    while {[gets $fin line] >= 0} {
        puts $fout [string map $map $line]
    }
    close $fin
    close $fout
}
  
  