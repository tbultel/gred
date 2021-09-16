# Dialog chapter (B. WELCH

# Modif faite par diam
# 15/11/95  fileselectResources : wm geometry .fileselect 400x600+10+10

########################################################################
########################################################################
########################################################################
package provide fileselect 0.1

# 
proc fileselectResources {} {
    # path is used to enter the file name
    option add *Fileselect*path.relief		sunken	startup
    option add *Fileselect*path.background	white	startup
    option add *Fileselect*path.foreground	black	startup
    # Text for the label on pathname entry
    option add *Fileselect*l.text		File:	startup
    # Text for the OK and Cancel buttons
    option add *Fileselect*ok*text		OK	startup
    option add *Fileselect*ok*underline		0	startup
    option add *Fileselect*cancel.text		Cancel	startup
    option add *Fileselect*cancel.underline 	0	startup
    # Size of the listbox
    option add *Fileselect*list.width		30	startup
    option add *Fileselect*list.height		30	startup
    wm geometry .fileselect 400x600+10+10
}

# fileselect returns the selected pathname, or {}
proc fileselect {{why "File Selection"} {default {}} {mustExist 1} } {
	global fileselect

	set t [toplevel .fileselect -bd 4 -class Fileselect]
	fileselectResources
    
	message $t.msg -aspect 1000 -text $why
	pack $t.msg -side top -fill x
    
	# Create a read-only entry for the durrent directory
	set fileselect(dirEnt) [entry $t.dir -width 15 \
		-relief flat -state disabled]
	pack $t.dir -side top -fill x
    
	# Create an entry for the pathname
	# The value is kept in fileselect(path)
	frame $t.top
	label $t.top.l -padx 0
	set e [entry $t.top.path \
		-textvariable fileselect(path)]
	pack $t.top -side top -fill x
	pack $t.top.l -side left
	pack $t.top.path -side right -fill x -expand true

    
	# Create a listbox to hold the directory contents
	set lb [listbox $t.list \
		-yscrollcommand [list $t.scroll set]]
	scrollbar $t.scroll -command [list $lb yview]

	# Create the OK and Cancel buttons
	# The OK button has a rim to indicate it is the default
	frame $t.buttons -bd 10
	frame $t.buttons.ok -bd 2 -relief sunken
	set ok [button $t.buttons.ok.b \
		-command fileselectOK]
	set can [button $t.buttons.cancel \
		-command fileselectCancel]

	# Pack the list, scrollbar, and button box
	# in a horizontal stack below the upper widgets
	pack $t.list -side left -fill both -expand true
	pack $t.scroll -side left -fill y
	pack $t.buttons -side left -fill both
	pack $t.buttons.ok $t.buttons.cancel \
		-side top -padx 10 -pady 5
	pack $t.buttons.ok.b -padx 4 -pady 4

	fileselectBindings $t $e $lb $ok $can

	# Initialize variables and list the directory
	if {[string length $default] == 0} {
		set fileselect(path) {}
		set dir [pwd]
	} else {
		set fileselect(path) [file tail $default]
		set dir [file dirname $default]
	}
	set fileselect(dir) {}
	set fileselect(done) 0
	set fileselect(mustExist) $mustExist

	# Wait for the listbox to be visible so
	# we can provide feedback during the listing 
	tkwait visibility .fileselect.list
	fileselectList $dir

	tkwait variable fileselect(done)
	destroy $t
	return $fileselect(path)
}
proc fileselectBindings { t e lb ok can } {
	# t - toplevel
	# e - name entry
	# lb - listbox
	# ok - OK button
	# can - Cancel button

	# Elimate the all binding tag because we
	# do our own focus management
	foreach w [list $e $lb $ok $can] {
	    bindtags $w [list $t [winfo class $w] $w]
	}
	# Dialog-global cancel binding
	bind $t <Control-c> fileselectCancel

	# Entry bindings
	bind $e <Return> fileselectOK
	bind $e <space> fileselectComplete

	# A single click, or <space>, puts the name in the entry
	# A double-click, or <Return>, selects the name
	bind $lb <space> "fileselectTake $%W ; focus $e"
	bind $lb <Button-1> \
		"fileselectClick %W %y ; focus $e"
	bind $lb <Return> "fileselectTake %W ; fileselectOK"
	bind $lb <Double-Button-1> \
		"fileselectClick %W %y ; fileselectOK"

	# Focus management.  	# <Return> or <space> selects the name.
	bind $e <Tab> "focus $lb ; $lb select set 0"
	bind $lb <Tab> "focus $e"

	# Button focus.  Extract the underlined letter
	# from the button label to use as the focus key.
	foreach but [list $ok $can] {
		set char [string tolower [string index  \
			[$but cget -text] [$but cget -underline]]]
		bind $t <Alt-$char> "focus $but ; break"
	}
	bind $ok <Tab> "focus $can"
	bind $can <Tab> "focus $ok"

	# Set up for type in
	focus $e
}

proc fileselectList { dir {files {}} } {
	global fileselect

	# Update the directory display
	set e $fileselect(dirEnt)
	$e config -state normal
	$e delete 0 end
	$e insert 0 $dir
	$e config -state disabled
	# scroll to view the tail end
	$e xview moveto 1

	.fileselect.list delete 0 end
	set fileselect(dir) $dir
	if ![file isdirectory $dir] {
	    .fileselect.list insert 0 "Bad Directory"
	    return
	}
	.fileselect.list insert 0 Listing...
	update idletasks
	.fileselect.list delete 0
	if {[string length $files] == 0} {
		# List the directory and add an
		# entry for the parent directory
		set files [glob -nocomplain $fileselect(dir)/*]
		.fileselect.list insert end ../
	}
	# Sort the directories to the front
	set dirs {}
	set others {}
	foreach f [lsort $files] {
		if [file isdirectory $f] {
			lappend dirs [file tail $f]/
		} else {
			lappend others [file tail $f]
		}
	}
	foreach f [concat $dirs $others] {
		.fileselect.list insert end $f
	}
}
proc fileselectOK {} {
	global fileselect

	# Handle the parent directory specially
	if {[regsub {^\.\./?} $fileselect(path) {} newpath] != 0} {
		set fileselect(path) $newpath
		set fileselect(dir) [file dirname $fileselect(dir)]
		fileselectOK
		return
	}
    
	set path [string trimright $fileselect(dir)/$fileselect(path) /]
    
	if [file isdirectory $path] {
		set fileselect(path) {}
		fileselectList $path
		return
	}
	if [file exists $path] {
		set fileselect(path) $path
		set fileselect(done) 1
		return
	}
	# Neither a file or a directory.
	# See if glob will find something
	if [catch {glob $path} files] {
		# No, perhaps the user typed a new
		# absolute pathname
		if [catch {glob $fileselect(path)} path] {
			# Nothing good
			if {$fileselect(mustExist)} {
				# Attempt completion
				fileselectComplete
			} elseif [file isdirectory \
				[file dirname $fileselect(path)]] {
				# Allow new name
				set fileselect(done) 1
			}
			return
		} else {
			# OK - try again
			set fileselect(dir) [file dirname $fileselect(path)]
			set fileselect(path) [file tail $fileselect(path)]
			fileselectOK
			return
		}
	} else {
		# Ok - current directory is ok,
		# either select the file or list them.
		if {[llength [split $files]] == 1} {
			set fileselect(path) $files
			fileselectOK
		} else {
			set fileselect(dir) [file dirname [lindex $files 0]]
			fileselectList $fileselect(dir) $files
		}
	}
}
proc fileselectCancel {} {
	global fileselect
	set fileselect(done) 1
	set fileselect(path) {}
}

proc fileselectClick { lb y } {
	# Take the item the user clicked on
	global fileselect
	set fileselect(path) [$lb get [$lb nearest $y]]
}
proc fileselectTake { lb } {
	# Take the currently selected list item
	global fileselect
	set fileselect(path) [$lb get [$lb curselection]]
}

proc fileselectComplete {} {
	global fileselect

	# Do file name completion
	# Nuke the space that triggered this call
	set fileselect(path) [string trim $fileselect(path) \t\ ]

	# Figure out what directory we are looking at
	# dir is the directory
	# tail is the partial name
	if {[string match /* $fileselect(path)]} {
		set dir [file dirname $fileselect(path)]
		set tail [file tail $fileselect(path)]
	} elseif [string match ~* $fileselect(path)] {
		if [catch {file dirname $fileselect(path)} dir] {
			return	;# Bad user
		}
		set tail [file tail $fileselect(path)]
	} else {
		set path $fileselect(dir)/$fileselect(path)
		set dir [file dirname $path]
		set tail [file tail $path]
	}
	# See what files are there
	set files [glob -nocomplain $dir/$tail*]
	if {[llength [split $files]] == 1} {
		# Matched a single file
		set fileselect(dir) $dir
		set fileselect(path) [file tail $files]
	} else {
		if {[llength [split $files]] > 1} {
			# Find the longest common prefix
			set l [expr [string length $tail]-1]
			set miss 0
			# Remember that files has absolute paths
			set file1 [file tail [lindex $files 0]]
			while {!$miss} {
				incr l
				if {$l == [string length $file1]} {
					# file1 is a prefix of all others
					break
				}
				set new [string range $file1 0 $l]
				foreach f $files {
					if ![string match $new* [file tail $f]] {
						set miss 1
						incr l -1
						break
					}
				}
			}
			set fileselect(path) [string range $file1 0 $l]
		}
		fileselectList $dir $files
	}
}
