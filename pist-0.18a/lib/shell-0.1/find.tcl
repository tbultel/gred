package provide shell 0.1

## find -- 
# 
# 
# Example usage: 
# 
# All *.txt files: 
# 
#     find . {string match *.txt}
# 
# All ordinary files: 
# 
#     find . {file isfile}
# 
# All readable files: 
# 
#     find . {file readable}
# 
# All non-empty files: 
# 
#     find . {file size}
# 
# All ordinary, non-empty, readable, *.txt files: 
# 
#     proc criterion filename {
#         expr {
#             [file isfile $filename]   && [file size $filename] &&
#             [file readable $filename] && [string match *.txt $filename]
#         }
#     }
#     find . criterion
# 
# All directories containing a description.txt file: 
# 
#     proc isDirWithDescription filename {
#         if {![file isdirectory $filename]} {return -code continue {}}
#         cd $filename
#         set l [llength [glob -nocomplain description.txt]]
#         cd ..
#         return $l
#     }
#     find . isDirWithDescription
# 
# ATTENTION : voir la version de tcllib :
# 
#     package require tcllib
#     set listOfFiles [fileutil::find $_basedir $_filterScript]
# 
proc find {{basedir .} {filterScript {}}} {
    set oldwd [pwd]
    cd $basedir
    set cwd [pwd]
    set filenames [glob -nocomplain * .*]
    set files {}
    set filt [string length $filterScript]
    foreach filename $filenames {
        if {!$filt || [eval $filterScript [list $filename]]} {
            lappend files [file join $cwd $filename]
        }
        if {[file isdirectory $filename]} {
            set files [concat $files [find $filename $filterScript]]
        }
    }
    cd $oldwd
    return $files
}
