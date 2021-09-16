# Tcl package index file, version 1.0
# This file is generated by the "pkg_mkIndex" command
# and sourced either when an application starts up or
# by a "package unknown" script.  It invokes the
# "package ifneeded" command to set up package-related
# information so that packages will be loaded automatically
# in response to "package require" commands.  When this
# script is sourced, the variable $dir must contain the
# full path name of this file's directory.

package ifneeded Comm 2.3 [list tclPkgSetup $dir Comm 2.3 {{comm.tcl source {comm commAbort commCollect commConnect commDebug commDestroy commExec commHook commIncoming commInit commLostConn commLostHook commNew commNewConn commSend commShutdown comm_send}}}]
package ifneeded xtcl 0.1 [list tclPkgSetup $dir xtcl 0.1 {{confirme.tcl source confirm} {random.tcl source random} {str.tcl source Str_Dup} {list.tcl source {laddleft lcutleft lexclude lfound llongest lmatch lmult lreverse lsub lsum lunique}} {report.tcl source report}}]