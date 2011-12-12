# Programmer:	Ryan S Mullins
# Course: 		CMPSC 497A Fall 2011
# Project:		Campus Tour App
# Date:			12/15/2011

printf "Converting filepath to the proper URL...\n\n";
`sed 's/^\(.*\)<filepath>.*\([0-9]*\)\(.*\)<\/filepath>.*$/\1<filepath>http:\/\/collection1.libraries.psu.edu\/maps\/bldgs\/\2\3<\/filepath>/' buildings.xml | cat > fixed_buildings.xml`;
printf "Finished Conversion...\n\n";