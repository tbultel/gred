 
# Makefile minimaliste pour la sauvegarde du repertoire courant 
#
# Les cibles suivantes creent un fichier compress'e et dat'e du r'ep'ertoire courant
# dans le r'ep'ertoire parent.
#
#   tgz : fichier de suffixe .tgz (au format .tar.gz)
#   tbz : idem, mais compresser avec bzip2
#   zip : fichier au format zip
#   arc : une des précédentes (valeur par défaut)
#   
#   



########################################################################
#
# Archivage du répertoire courant dans le répertoire parent
# 
arc:    tbz

# Compression avec gzip
tgz:
	# $(MAKE) clean
	date=`date +%Y%m%d-%Hh%Mmn` 			&& \
	lpath=`pwd`					&& \
	bname=`basename $$lpath`			&& \
	datename=$$bname-$$date				&& \
	cd ..						&& \
	cp -pR $$bname $$datename 			&& \
	tar cf - $$datename | gzip > $$datename.tgz	&& \
	\rm -rf $$datename
	
# Compression avec bzip2
tbz:
	# $(MAKE) clean
	date=`date +%Y%m%d-%Hh%Mmn` 			&& \
	lpath=`pwd`					&& \
	bname=`basename $$lpath`			&& \
	datename=$$bname-$$date				&& \
	cd ..						&& \
	cp -pR $$bname $$datename 			&& \
	tar cf - $$datename | bzip2 > $$datename.tbz	&& \
	\rm -rf $$datename
	
# Compression avec zip
zip:
	# $(MAKE) clean
	date=`date +%Y%m%d-%Hh%Mmn` 			&& \
	lpath=`pwd`					&& \
	bname=`basename $$lpath`			&& \
	datename=$$bname-$$date				&& \
	cd ..						&& \
	cp -pR $$bname $$datename 			&& \
	zip -r -y -o -q -9  $$datename.zip $$datename	&& \
	\rm -rf $$datename
	
#./
