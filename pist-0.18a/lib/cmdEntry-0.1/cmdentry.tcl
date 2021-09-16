
package provide cmdentry 0.1

# A RENOMMER EN CommandLine_Init

# Proc tk_CmdEntry parent 
# Cree un entree pour taper des commandes TCL dans l'interpreteur courant.
# 
# globales utilisables tkCmdEntry :
#  tkCmdEntry(label) : nom du label 
#     peut etre changé par $tkCmdEntry(label) -config -text "New text"
#  tkCmdEntry(entry) : nom de l'entry
#  tkCmdEntry(result) : resultat de la commande (peut etre exploiter par 
#     une travace de cette variable en lecture)
#  tkCmdEntry(resultCmd) : doit etre affecte par l'appli comme procedure 
#     devant afficher le resultat
#     UTILISER la procedure tk_CmdEntrySetResultProc pour cela.

# BUG :
# 
# ivide by zero
#     while executing
# "expr ($tkCmdEntry(histCurrentId) - 1) % $tkCmdEntry(histLastId)"
#     invoked from within
# "set tkCmdEntry(histCurrentId)  [expr ($tkCmdEntry(histCurrentId) - 1) % $tkCmdEntry(histLastId)]..."
#     (command bound to event)
proc tk_CmdEntryInit {} {
global tkCmdEntry tcl_interactive
   set tcl_interactive 1
   set tkCmdEntry(histCurrentId) 0
   set tkCmdEntry(histLastId)    0
   set tkCmdEntry(histMax)      40
   set tkCmdEntry(histTmp)      ""
   if {[string length [info proc tkDefaultResultProc]]} {
      proc tkDefaultResultProc args {
          puts stdout $args
      }
      set tkCmdEntry(resultCmd) tkDefaultResultProc
   }
}
# # # CETTE PROCédure sera virée et remplacer par la suivante
# # proc tk_CmdSetResultProc {{procName ""}} {
# # global tkCmdEntry 
# #    eval set tkCmdEntry(resultCmd) $procName
# # }

# procName peut etre due la forme "puts toto.log" (i.e. en deux mots)

proc tk_CmdEntrySetResultProc {{procName ""}} {
global tkCmdEntry 
   eval set tkCmdEntry(resultCmd) $procName
}

proc tk_CmdEntry {{parent .cmd}} {
global tkCmdEntry tcl_interactive

   tk_CmdEntryInit
   
   frame $parent
   set e  [entry $parent.e  -relief sunken]
   set l  [label $parent.l  -text "Tcl:" -padx 0]
   grid $l $e -sticky we
   grid columnconfigure $parent 1 -weight 1
   
   set tkCmdEntry(entry) $e
   set tkCmdEntry(label) $l
   
   bind  $e <Return> {tk_CmdInvoque}
   bind  $e <Up> {
      # set tkCmdEntry(histTmp) [$tkCmdEntry(entry) get 0 end]
      set tkCmdEntry(histCurrentId) \
          [expr ($tkCmdEntry(histCurrentId) - 1) %% $tkCmdEntry(histLastId)]
      if {$tkCmdEntry(histCurrentId) < 0} {
          set tkCmdEntry(histCurrentId) 0
      }
      $tkCmdEntry(entry) delete 0 end
      $tkCmdEntry(entry) insert 0 \
          [set tkCmdEntry(hist_[set tkCmdEntry(histCurrentId)])]
   }
   bind  $e <Down> {
      # set tkCmdEntry(histTmp) [$tkCmdEntry(entry) get 0 end]
      set tkCmdEntry(histCurrentId) \
          [expr ($tkCmdEntry(histCurrentId) + 1) %% $tkCmdEntry(histLastId)]
      if {$tkCmdEntry(histCurrentId) > $tkCmdEntry(histLastId)} {
          set tkCmdEntry(histCurrentId) $tkCmdEntry(histLastId)
      }
      $tkCmdEntry(entry) delete 0 end
      $tkCmdEntry(entry) insert 0 \
          [set tkCmdEntry(hist_[set tkCmdEntry(histCurrentId)])]
   }
   return $tkCmdEntry(entry)
}

proc tk_CmdInvoque {} {
global tkCmdEntry tcl_interactive

   set script [$tkCmdEntry(entry) get]
   set tkCmdEntry(result) ""
   if {"x$script" != "x"} {
      if [info complete $script] {
          set tkCmdEntry(hist_[set tkCmdEntry(histLastId)]) $script
          set tkCmdEntry(histCurrentId) $tkCmdEntry(histLastId)
          set tkCmdEntry(result) [uplevel #0 $script]
          
          # affichage du resultat :
          eval $tkCmdEntry(resultCmd) $tkCmdEntry(result)
          
          set tkCmdEntry(hist_[set tkCmdEntry(histCurrentId)]) $script
          report -v tkCmdEntry(histCurrentId) \
             tkCmdEntry(hist_[set tkCmdEntry(histCurrentId)])
          incr tkCmdEntry(histLastId)
          $tkCmdEntry(entry) delete 0 end
          # gred:status $result
          # focus $tkCmdEntry(entry)
      } else {
          set tkCmdEntry(result)  "commande incomplete !"
      }
   }
   return $tkCmdEntry(result)
}

