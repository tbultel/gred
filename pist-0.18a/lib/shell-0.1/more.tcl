package provide shell 0.1


# Faire une procedure du style more ou pageit

# # >Would something like (I don't have a window to try this code to fix
# # >typos - post what you end up getting to work!)
# # >
# # >:proc pageit {cmd args}
# # >:{
# # >:set loopcount 1
# # >:foreach com [split [$cmd $args]] {
# # >:       puts "$com"
# # >:       incr loopcount
# # >:       if [ $loopcount == 1 ] {
# # >:               puts "press return to continue"
# # >:               read stdin
# # >:               set loopcount 1
# # >:       }
# # >:}
# # >:}
