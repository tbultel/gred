console for Unix

From a news:comp.lang.tcl posting by Donald Porter:

On Windows (and presumably on Mac), the [console show] command will add an
interactive console to any script. For example:

 # BEGIN demo.tcl
 pack [button .b -command exit -text Exit]
 console show
 # END demo.tcl

Unfortunately the [console] command is not part of Tk on Unix, where you
appear to be working.

*But* you can fake it, since the console command is supported almost
entirely in Tcl code which is part of Tk's script library and is available
on Unix. Source the script below in a Tk-enabled interpreter on Unix and you
will get a console window:
  ------------------------------------------------------------------------

 # FILE: console.tcl
 #
 #       Provides a console window.
 #
 # Last modified on: $Date: 2000/05/15 20:14:12 $
 # Last modified by: $Author: dgp $
 #
 # This file is evaluated to provide a console window interface to the
 # root Tcl interpreter of an OOMMF application.  It calls on a script
 # included with the Tk script library to do most of the work, making  use
 # of Tk interface details which are only semi-public.  For this reason,
 # there is some risk that future versions of Tk will no longer support
 # this script.  That is why this script has been isolated in a file of
 # its own.

 #######################################################################
 # If the Tcl command 'console' is already in the interpreter, our work
 # is done.
 #######################################################################
 if {![catch {console show}]} {
    return
 }

 #######################################################################
 # Check Tcl/Tk support
 #######################################################################
 if {[catch {package require Tcl 8}]} {
    package require Tcl 7.5
 }

 if {[catch {package require Tk 8}]} {
    if {[catch {package require Tk 4.1}]} {
        return -code error "Tk required but not loaded."
    }
 }

 set _ [file join $tk_library console.tcl]
 if {![file readable $_]} {
    return -code error "File not readable: $_"
 }

 ########################################################################
 # Provide the support which the Tk library script console.tcl assumes
 ########################################################################
 # 1. Create an interpreter for the console window widget and load Tk
 set consoleInterp [interp create]
 $consoleInterp eval [list set tk_library $tk_library]
 $consoleInterp alias exit exit
 load "" Tk $consoleInterp

 # 2. A command 'console' in the application interpreter
 ;proc console {sub {optarg {}}} [subst -nocommands {
    switch -exact -- \$sub {
        title {
            $consoleInterp eval wm title . [list \$optarg]
        }
        hide {
            $consoleInterp eval wm withdraw .
        }
        show {
            $consoleInterp eval wm deiconify .
        }
        eval {
            $consoleInterp eval \$optarg
        }
        default {
            error "bad option \\\"\$sub\\\": should be hide, show, or title"
        }
    }
 }]

 # 3. Alias a command 'consoleinterp' in the console window interpreter
 #       to cause evaluation of the command 'consoleinterp' in the
 #       application interpreter.
 ;proc consoleinterp {sub cmd} {
    switch -exact -- $sub {
        eval {
            uplevel #0 $cmd
        }
        record {
            history add $cmd
            catch {uplevel #0 $cmd} retval
            return $retval
        }
        default {
            error "bad option \"$sub\": should be eval or record"
        }
    }
 }
 if {[package vsatisfies [package provide Tk] 4]} {
    $consoleInterp alias interp consoleinterp
 } else {
    $consoleInterp alias consoleinterp consoleinterp
 }

 # 4. Bind the <Destroy> event of the application interpreter's main
 #    window to kill the console (via tkConsoleExit)
 bind . <Destroy> [list +if {[string match . %W]} [list catch \
        [list $consoleInterp eval tkConsoleExit]]]

 # 5. Redefine the Tcl command 'puts' in the application interpreter
 #    so that messages to stdout and stderr appear in the console.
 rename puts tcl_puts
 ;proc puts {args} [subst -nocommands {
    switch -exact -- [llength \$args] {
        1 {
            if {[string match -nonewline \$args]} {
                if {[catch {uplevel [linsert \$args 0 tcl_puts]} msg]} {
                    regsub -all tcl_puts \$msg puts msg
                    return -code error \$msg
                }
            } else {
                $consoleInterp eval [list tkConsoleOutput stdout \
                        "[lindex \$args 0]\n"]
            }
        }
        2 {
            if {[string match -nonewline [lindex \$args 0]]} {
                $consoleInterp eval [list tkConsoleOutput stdout \
                        [lindex \$args 1]]
            } elseif {[string match stdout [lindex \$args 0]]} {
                $consoleInterp eval [list tkConsoleOutput stdout \
                        "[lindex \$args 1]\n"]
            } elseif {[string match stderr [lindex \$args 0]]} {
                $consoleInterp eval [list tkConsoleOutput stderr \
                        "[lindex \$args 1]\n"]
            } else {
                if {[catch {uplevel [linsert \$args 0 tcl_puts]} msg]} {
                    regsub -all tcl_puts \$msg puts msg
                    return -code error \$msg
                }
            }
        }
        3 {
            if {![string match -nonewline [lindex \$args 0]]} {
                if {[catch {uplevel [linsert \$args 0 tcl_puts]} msg]} {
                    regsub -all tcl_puts \$msg puts msg
                    return -code error \$msg
                }
            } elseif {[string match stdout [lindex \$args 1]]} {
                $consoleInterp eval [list tkConsoleOutput stdout \
                        [lindex \$args 2]]
            } elseif {[string match stderr [lindex \$args 1]]} {
                $consoleInterp eval [list tkConsoleOutput stderr \
                        [lindex \$args 2]]
            } else {
                if {[catch {uplevel [linsert \$args 0 tcl_puts]} msg]} {
                    regsub -all tcl_puts \$msg puts msg
                    return -code error \$msg
                }
            }
        }
        default {
            if {[catch {uplevel [linsert \$args 0 tcl_puts]} msg]} {
                regsub -all tcl_puts \$msg puts msg
                return -code error \$msg
            }
        }
    }
 }]
 $consoleInterp alias puts puts

 # 6. No matter what Tk_Main says, insist that this is an interactive  shell
 set tcl_interactive 1

 #######################################################################
 # Evaluate the Tk library script console.tcl in the console interpreter
 #######################################################################
 $consoleInterp eval source [list [file join $tk_library console.tcl]]

 unset consoleInterp

 console title "[wm title .] Console"

  ------------------------------------------------------------------------

 | Don Porter, D.Sc. Mathematical and Computational Sciences Division
 | donald.porter@nist.gov          Information Technology Laboratory |
 | [http://math.nist.gov/mcsd/Staff/DPorter/]                   NIST |

  ------------------------------------------------------------------------
Updated on 6 Aug 2000, 00:34 GMT   -   Edit console for Unix
Search - Changes - Expand - About WiKit - Go to The Tcl'ers Wiki
