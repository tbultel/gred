########################################################################
# Epsf_Box --
# 
# ATTENTION : VOIR EXEMPLE DE B> WELCH A LA FIN...
# 
# 
# package require prompt
package provide epsf 0.1

proc Epsf_Box {} {
global gred

  # a deplacer dans pref ou ailleurs
  set gred(epsf,default,orient) Portrait
  set gred(epsf,default,mode) Color
  set gred(epsf,default,zone) All
  
  # les variables utiles
  set c $gred(canvas)
  
  global tmp   
  foreach opt {orient mode zone} {
    set tmp($opt) $gred(epsf,default,$opt)
  }

  Prompt_Box -title "Epsf Dialog Box" -parent .epsf 
    
#   Prompt_Box  -title "Epsf Dialog Box" \
#     -parent .epsf \
#     -entries { 
#     {-type SEPARATOR -line down -label "Sélection des paramètres"}
#     {-type SEPARATOR -line down} 
#     {-type RADIOBUTTON -label "Orientation" \
#       -typearg {Portrait Landscape} -variable tmp(orient)}
#     {-type SEPARATOR -line down} 
#     {-type RADIOBUTTON -label "Color Mode" \
#       -typearg {Color Gray Mono} -variable tmp(mode)}
#     {-type SEPARATOR -line down} 
#     {-type RADIOBUTTON -label "Color Mode" \
#       -typearg {All Window} -variable tmp(zone)}
#     {-type SEPARATOR -line down} 
#   }

  # mise a jour des variables "tmp" retournées
  set tmp(mode) [string tolower $tmp(mode)]
  
  switch -- $tmp(orient) {
    Portrait { set tmp(orient) true }
    Landscape { set tmp(orient) false }
    default { set tmp(orient) true }
  }
  
  switch -- $tmp(zone) {
    All { 
      set tmp(width) [ $c cget -width ]
      set tmp(height) [ $c cget -height ]
    }
    Window {
      set geom [wm geometry . ]
      regsub -all {[x\+-]} $geom " " tmp(geometry)
      set tmp(width) [lindex $tmp(geometry) 0]
      set tmp(height) [lindex $tmp(geometry) 1]
    }
  }
  
  # retour du format postscript
  set result [$c postscript \
      -rotate $tmp(orient) \
      -colormode $tmp(mode) \
    -width $tmp(width) \
    -pagewidth 210.m \
    -pageheight 297.m]
  
  unset tmp
  return $result

}


# return 
# ########################################################################
# ########################################################################
# ########################################################################
# # Canvas chapter
# # Postscript example
# proc Setup {} {
#   global fontMap
#   catch { destroy .c}
#   canvas .c
#   pack .c -fill both -expand true
#   set x 10
#   set y 10
#   set last [.c create text $x $y -text "Font sampler" \
#                     -font fixed -anchor nw]
#   foreach family {times courier helvetica} {
#     set weight bold
#     switch -- $family {
#       times { set fill blue; set psfont TimesRoman}
#       courier { set fill green; set psfont Courier }
#       helvetica { set fill red; set psfont Helvetica }
#     }
#     foreach size {10 14 24} {
#       set y [expr 4+[lindex [.c bbox $last] 3]]
#       if {[catch {.c create text $x $y \ 
#                     -text $family-$weight-$size \
#                     -anchor nw  -fill $fill \
#                     -font -*-$family-$weight-*-*-*-$size-*} it] == 0} {
#         set fontMap(-*-$family-$weight-*-*-*-$size-*) \
#             [list $psfont $size ]
#         set last $it
#       }
#     }
#   }
#   set fontMap(fixed) [list Courier 12]
# }
# proc Postscript { c file } {
#   global fontMap
#   set colorMap(blue)  {0.1 0.1 0.9 setrgbcolor}
#   set colorMap(green) {0.0 0.9 0.1 setrgbcolor}
#   $c postscript -fontmap fontMap -colormap colorMap -file $file \
#          -pagex 0.i -pagey 11.i -pageanchor nw
# }

