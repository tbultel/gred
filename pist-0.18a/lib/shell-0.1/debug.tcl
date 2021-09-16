package provide shell 0.1


# Quelques procédure destinées à faciliter le débogage en interactif



## try_regexp -- facilite la mise au point de regexp
# 
# creation :
# 
#   17/07/00 (diam)
# 
# exemple :
# 
#   set txt " <record> AAA </record> BBB <record> CCC </record> "
#   try_regexp {<\s*record(?:[^>]*)?>(.*?)</record>()}  $txt
#   try_regexp {<\s*?record(?:[^>]*)?>(.*?)</record>()}  $txt
# 
proc try_regexp {pat txt} {
    puts "txt=$txt"
    puts "pat=$pat"
    puts "=> [regexp $pat $txt -]"
    puts "=> ${-}"
}

