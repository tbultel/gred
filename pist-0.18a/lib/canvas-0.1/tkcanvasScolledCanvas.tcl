
package provide canvas 0.1


# tkCanvasScrolledCanvas ?parent? args: crée un canvas avec scrollbars
#     retourne le non du canvas (defaut : .draw.c)
#  parent : la fram créée par cette proc qui contiendra le canvas 
#           (defaut : .draw)
#  args : option de configuration pour le canvas ($parent.c)
#  

proc tkCanvasScrolledCanvas {{parent .draw} args} {
  global canvas
  # On peut utiliser canvas(scrollside)
  
  frame $parent
  
  set c [canvas $parent.c -relief sunken\
  	-xscrollcommand "$parent.xs set" \
  	-yscrollcommand "$parent.ys set" ]
  lappend canvas(canvas) $c
  
  scrollbar $parent.ys -command "$c yview"
  scrollbar $parent.xs -command "$c xview"  -orient horizontal

  # radiobutton $parent.rd -variable mud(modified)
  if ![info exists canvas(scrollside)] {set canvas(scrollside) right}
  switch -exact $canvas(scrollside) {
    right {
      grid $c         -column 0 -row 0 -padx 1 -pady 1 -sticky news
      grid columnconfigure $parent 0 -weight 1
      grid rowconfigure    $parent 0 -weight 1
      grid $parent.ys -column 1 -row 0 -padx 1 -pady 1 -sticky ns
      grid $parent.xs -column 0 -row 1 -padx 1 -pady 1 -sticky we
    }
    left {
      grid $c         -column 1 -row 0 -padx 1 -pady 1 -sticky news
      grid columnconfigure $parent 1 -weight 1
      grid rowconfigure    $parent 0 -weight 1
      grid $parent.ys -column 0 -row 0 -padx 1 -pady 1 -sticky ns
      grid $parent.xs -column 1 -row 1 -padx 1 -pady 1 -sticky we
    }
  }
  # grid $parent.rd -in $parent -column 0 -row 3 -sticky we -padx 1 -pady 1
  eval $c configure -cursor tcross $args
  
  # # # Should be use by the application as :
  # # # event add <<scanMark>> <Button2>
  # # # event add <<scanMotion>> <Button2-Motion>
  # # bind $c <<scanMark>>   "$c scan mark %x %y"
  # # bind $c <<scanMotion>> "$c scan dragto %x %y"
  return $c
}
