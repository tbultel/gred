# Tcl package index file, version 1.1
# This file is generated by the "pkg_mkIndex" command
# and sourced either when an application starts up or
# by a "package unknown" script.  It invokes the
# "package ifneeded" command to set up package-related
# information so that packages will be loaded automatically
# in response to "package require" commands.  When this
# script is sourced, the variable $dir must contain the
# full path name of this file's directory.

package ifneeded shell 0.1 [list source [file join $dir mkindex.tcl]]\n[list source [file join $dir dump.tcl]]\n[list source [file join $dir grep.tcl]]\n[list source [file join $dir more.tcl]]\n[list source [file join $dir utilshell.tcl]]\n[list source [file join $dir shell.tcl]]\n[list source [file join $dir showproc.tcl]]\n[list source [file join $dir edit.tcl]]\n[list source [file join $dir debug.tcl]]\n[list source [file join $dir find.tcl]]\n[list source [file join $dir sed.tcl]]\n[list source [file join $dir sort.tcl]]
