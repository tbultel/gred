package provide xtcl 0.1

# It uses the same syntax as the TclX random number generator.
# If you want it to work on Win/Mac, I suggest adding argv0 as a global
# and replacing /dev/kmem with $argv0.
# -- 
#      Jeffrey Hobbs                           Office: 503/346-3998
#      Univ of Oregon CIS GTF                  email: jhobbs@cs.uoregon.edu
# 		URL: http://www.cs.uoregon.edu/~jhobbs/
proc random {args} {
  global random

  set max 259200
  set argcnt [llength $args]
  if { $argcnt < 1 || $argcnt > 2 } {
    error "wrong # args: random limit | seed ?seedval?"
  }
  if ![string compare [lindex $args 0] seed] {
    if { $argcnt == 2 } {
      set random(seed) [lindex $args 1]
    } else {
      set random(seed) [expr ([pid]+[file atime /dev/kmem])%$max]
    }
    return
  }
  if ![info exists random(seed)] {
    set random(seed) [expr ([pid]+[file atime /dev/kmem])%$max]
  }
  set random(seed) [expr ($random(seed)*7141+54773)%$max]
  return [expr int([lindex $args 0]*($random(seed)/double($max)))]
}

return
########################################################################
########################################################################
########################################################################
# AUTRES POSSIBILITES :

# CELLE CI EST MIEUX MAIS l'adapter a la syntaxe de tclx
#
# random.tcl - very random number generator in tcl.
#
# Copyright 1995 by Roger E. Critchlow Jr., San Francisco, California.
# All rights reserved.  Fair use permitted.  Caveat emptor.
#
# This code implements a very long period random number
# generator.  The following symbols are "exported" from
# this module:
#
#	[random] returns 31 bits of random integer.
#	[random_seed <integer!=0>] reseeds the generator.
#	$random(max) yields the maximum number in the
#	  range of [random] or maybe one greater.
#
# The generator is one George Marsaglia, geo@stat.fsu.edu,
# calls the Mother of All Random Number Generators.
#
# The coefficients in a2 and a3 are corrections to the original
# posting.  These values keep the linear combination within the
# 31 bit summation limit.
#
# And we are truncating a 32 bit generator to 31 bits on
# output.  This generator could produce the uniform distribution
# on [INT_MIN .. -1] [1 .. INT_MAX]
#
# Modifications :
# - 13/06/96 (diam@ensta.fr) utilisation d'ue seule variable globale
#   random(..), 

set random(a1) {  1941 1860  1812  1776 1492  1215  1066 12013 }
set random(a2) {  1111 2222  3333  4444 5555  6666  7777   827 }
set random(a3) {  1111 2222  3333  4444 5555  6666  7777   251 }
set random(m1) { 30903 4817 23871 16840 7656 24290 24514 15657 19102 }
set random(m2) { 30903 4817 23871 16840 7656 24290 24514 15657 19102 }

proc random::srand16 {seed} {
    set n1 [expr $seed & 0xFFFF]
    set n2 [expr $seed & 0x7FFFFFFF]
    set n2 [expr 30903 * $n1 + ($n2 >> 16)]
    set n1 [expr $n2 & 0xFFFF]
    set m  [expr $n1 & 0x7FFF]
    # je suppose qu'il aurait aimÈ pouvoir faire : "for i in 1 to 8" !
    foreach i {1 2 3 4 5 6 7 8} {
        set n2 [expr 30903 * $n1 + ($n2 >> 16)]
        set n1 [expr $n2 & 0xFFFF]
        lappend m $n1
    }
    return $m
}

proc random::rand16 {a m} {
    set n [expr                [lindex $m 0] + \
               [lindex $a 0] * [lindex $m 1] + \
               [lindex $a 1] * [lindex $m 2] + \
               [lindex $a 2] * [lindex $m 3] + \
               [lindex $a 3] * [lindex $m 4] + \
               [lindex $a 4] * [lindex $m 5] + \
               [lindex $a 5] * [lindex $m 6] + \
               [lindex $a 6] * [lindex $m 7] + \
               [lindex $a 7] * [lindex $m 8]]

    return [concat [expr $n >> 16] [expr $n & 0xFFFF] [lrange $m 1 7]]
}

#
# Externals
# 
set random(max) 0x7FFFFFFF

proc random_seed {seed} {
    global random
    set random(m1) [random::srand16 $seed]
    set random(m2) [random::srand16 [expr 4321+$seed]]
    return {}
}

proc random {} {
    global random
    set random(m1) [random::rand16 $random(a1) $random(m1)]
    set random(m2) [random::rand16 $random(a2) $random(m2)]]
    return [expr (([lindex $random(m1) 1] << 16) + \
                   [lindex $random(m2) 1]) & 0x7FFFFFFF]
}

return
########################################################################
########################################################################
########################################################################
# AUTRES POSSIBILITES :



########################################################################
# Here is code adapted from Exploring Expect by Don Libes.  This version
# is written to emulate the one in TclX only if TclX is not available as 
# a dynamically loadable extension to tcl7.5a2.

# if {[catch {load $PREFIX/libtclx.so.7.5 tclx}]} {
#     # if we're not using a tclX extension then emulate random
#     # random from Libes p525
#     set _ran [pid]
#     proc random {range} {
#         global _ran
#         set _ran [expr ($_ran * 9301 + 49297) % 233280]
#         return [expr int($range * ($_ran / double(233280)))]
#     }
# }


########################################################################
########################################################################
########################################################################
# # A pseudo-random number generator
# # Based on code by Mark Eichin, Cygnus. 
# # http://www.cygnus.com/%7Eeichin/random-tcl.html
# 
# global UTIL_rndseed
# set UTIL_rndseed [expr [clock clicks] % 65536]
#  
# proc UTIL_rawrand {} {
#     global UTIL_rndseed
#     # per Knuth 3.6:
#     # 65277 mod 8 = 5 (since 65536 is a power of 2)
#     # c/m = .5-(1/6)\sqrt{3}
#     # c = 0.21132*m = 13849, and should be odd.
#     set UTIL_rndseed [expr (65277 * $UTIL_rndseed +13849)%65536]
#     set UTIL_rndseed [expr ($UTIL_rndseed+65536)%65536]
#     return $UTIL_rndseed
# }
# proc random {arg1 {seed {}}} {
#     if {$arg1 == "seed"} {
#         global UTIL_rndseed
#         set UTIL_rndseed $seed
#         return {}
#     }
#     return [expr ([UTIL_rawrand] * $arg1) / 65536]
# }
