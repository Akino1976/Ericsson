#!/usr/bin/env bash
###################################################################################
#:         Title: ericsson
#:      Synopsis: ericsson [--main][--pre][--post]
#:          Date: 2014-Maj
#:       Options:   -m|--main   - Include xls data file
#:                                used for correcting the test
#:                  -u|--update  - Will update pre and post data
#: ex -> find ./DataInput -iname '*.xls' -print
scriptname=${0##*/}
description="Ericsson Core 3 test"
usage="$scriptname  [--main|-m] [--update|-u]"
date_of_creation=2014-05
version=1.0
author="Serdar Akin"
#: This script executes the Erisson Core3 testing procedure
#: Either only the script corrects the main results given by
#: the -m|--main option and hence outputs everything in the
#: directory
###################################################################################
## The first dir where to keep the under dir
Home=$PWD
DATAINPUT1=$Home/DataInput
## Here is where Main survey data is stored
MAIN=$DATAINPUT1/MainSurvey
## Here is where Pre/post survey data is stored
SUB_pre=$DATAINPUT1/PreSurvey
SUB_post=$DATAINPUT1/PostSurvey
COLLECT="$Home/MainTest"
COLLECT_SUB="$Home/PrePostTest"
GRAF="$Home/graf"
NAME="dataAnalysis"
NAME1="PrePostSurvey"
## temporary data
TMP=$Home/tmpData
SRC=$Home/src
GREEN="\033[32m"
NO_COLOUR="\033[0m"
RED="\033[31m"
_PRES="presentation.Rnw"
_PRESDATA="Data/presentation.txt"
## Rm files
dirtFile="*.lof *.toc *.lot *.fls *.fdb.* *.out *.nav *.snm *.aux"

############################################################################
## Programs and function
############################################################################
RR="/usr/bin/Rscript --verbose"
#: This will create an pdf file by
#: compiling and moving the pdf file
#: to the location where specified
#: USAGE: compileDok <file.Rnw> <dir>
compileDok()    #@ DESCRIPTION: Compile LaTeX files and move to dir
{               #@ USAGE: usage
                #@ REQUIRES: <file.Rnw|tex>
                #@ NOT REQUIRES: <dirname> <FileOutPutName>
    DOK=${2:-Dokument}
    test -d $DOK || mkdir ${DOK}
    Step1=${1//\"/}
    FirstName=${Step1%%.*}
    ## Get the file extension e.g Rnw
    LastName=${Step1#*.}
    name=${3:-$FirstName}
    if [ ! -e $Step1 ]; then
        echo "###################################################"
        printf "# Dont exits file (%s) \n" "$Step1"
        echo "###################################################"
        exit 1
    fi
    ## make lowercase cmp
    if [ $( echo $LastName | tr '[:upper:]' '[:lower:]' ) = "rnw" ];then
        R CMD Sweave --encoding=utf8 ${FirstName}.${LastName}
        clear
    fi
    latexmk -g -f -lualatex ${FirstName}.tex
    mv ${FirstName}.pdf ${DOK}/$name.pdf
}


compilePre()    #@ DESCRIPTION: Compile Beamer presentation to dir
{               #@ USAGE: compilePre <file.tex> [DIR]
                #@ REQUIRES: <file.Rnw|tex>
                #@ NOT REQUIRES: <dirname> <FileOutPutName>
    DOK=${2:-Dokument}
    test -d $DOK || mkdir ${DOK}
    _FILE=$1
    FirstName=${_FILE%%.*}
    if [ ! -e "$_FILE" ]; then
        echo "###################################################"
        printf "${GREEN}## File dont exists (%s) ${NO_COLOUR}" "$_FILE"
        echo "###################################################"
        exit 0
    fi
    
    R CMD Sweave --encoding=utf8 "$_FILE"
    latexmk -g -f -lualatex ${FirstName}.tex
    mv ${FirstName}.pdf $DOK
    clear
}
die()
{
    error=$1
    shift
    [ -n "$*" ] printf "%s\n" "$*" >&2
    exit "$error"
}

usage()  #@ DESCRIPTION: print usage information
{        #@ USAGE: usage
         #@ REQUIRES: variable defined: $scriptname
    printf "%s - %s\n" "$scriptname" "$description"
    printf "USAGE: %s\n" "$usage"
}

version()    #@ DESCRIPTION: print version information
{            #@ USAGE: version
             #@ REQUIRES: variables defined: $scriptname, $author and $version
    printf "%s version %s\n" "$scriptname" "$version"
    printf "by %s, %d\n" "$author"  "${date_of_creation%%-*}"
}

_repeat() { #@ USAGE: _repeat string number
    _REPEAT=$1
    while [ ${#_REPEAT} -lt $2 ]
        ## Loop until string exceeds desired length
    do
    _REPEAT=$_REPEAT$_REPEAT$_REPEAT
    ## 3 seems to be the optimum number
    done
    _REPEAT=${_REPEAT:0:$2}
    ## Trim to desired length
}

alert() #@ USAGE: alert message border
{
    _repeat "${2:-#}" $(( ${#1} + 8 ))
    printf '\a%s\n' "$_REPEAT" ## \a = BEL
    printf '%2.2s  %s  %2.2s\n' "$_REPEAT" "$1" "$_REPEAT"
    printf '%s\n' "$_REPEAT"
}

#------------------------------------------------------------
# Parse command line options/arguments
#------------------------------------------------------------
if (! getopts "hvmuo:" name); then
    echo "Usage: ${0##*/} script, options [-(m|u)] [-(o) value] or -h for help"
    exit $E_OPTERROR
fi

while getopts hvmuo: option
do 
    case ${option} in 
	h) usage; 
	    exit;;
	v) version;
	    exit ;;
	m) updateTest="yes"
	    ;;
	u) update="yes"
	    ;;
	o) OARG=$OPTARG ## Returns the argumen -o "Serdar"
	    ;;
	\?) Syntax;
	    alert "${scriptname}: usage: [-m (run Test) ] | [-u (run survey)]"
	    exit 2
	    ;;
	esac
done
shift "$(( OPTIND - 1 ))"




#########################################################

## Make dir that is not there
for i in $TMP $MAIN $SUB_pre $SUB_post $COLLECT; do
    test -d $i && mkdir $i
##
done
##Remove files in tmpData dir
find $TMP -type f -exec rm -f {} \;

### Command line options
### Cannot be empty nor start with "-"


## Test if empty argument for -m or --main, if empty
## then skip this whole section
if [ "$updateTest" = "yes" ]
then

        $RR $SRC/Test.R
        clear
        echo "============================================================="
        echo  "Have updated the main file in R"
        echo "============================================================="
        sleep 1s

    ## Put the email into arrays
    ## In email line we remove all characters
    ## before the / character
    while read line; do
        Fullpath+=("$line")
    done < Data/Email.txt


echo "============================================================="
printf "##${RED} %s ${NO_COLOUR} ##\n"  "${Fullpath[@]}"
echo "============================================================="

printf "Should all (%d) these emails be processed (\033[36my/n\033[0m)?: \n" "${#Fullpath[@]}"
read x
if [ "$x" = "y" ] || [ "$x" = "Y" ]
    then
    for ((i=0; i <${#Fullpath[*]}; i++ ))
        do
        [ "${#Fullpath[@]}" -eq 0 ] && continue
        name="${Fullpath[i]}"
        nr=("${name//*\//}") ##Email
        clear
        echo "============================================================="
        printf "\033[32m## Will run email: [%s] ##\033[0m\n" "${nr}"
        printf "\033[36m## and the output to: [%s] ##\033[0m\n" "$name"
        echo "============================================================="
        sleep 1s
R --no-restore --slave<<EOR
library( data.table )
DATA    <- getwd()
FILE    <- file.path(DATA, 'Data', 'Latex.RData')
FILE1   <- file.path(DATA, 'Data', 'Correct.RData')
if( file.exists( FILE )){
cat(basename(FILE), " exists and will be removed ", "\n" )
file.remove( file = FILE )
}
load( file = FILE1 )
setkeyv(Correct1, 'E.post' )
DataPer <- Correct1[J("${nr}"),]
head(DataPer)
save( DataPer, file = FILE )
EOR
sleep 1s
clear
## Compile each document
compileDok ${NAME}.Rnw $COLLECT $name
rm -f ${dirtFile}
echo "============================================================="
printf "## Email (%s) [%s/%s] done is completed ##\n" "$nr" "$((i+1))" "${#Fullpath[@]}"
echo "============================================================="
sleep 1s
    done ##end For Loop
    elif [ -z "$update" -a "$update" == " " ] ;
    then
       exit 1
    fi ## End ifExpr yes for printf
fi #end If --main in line approximately 98

######################################################################
# If just need to update the evaluation data then firsta update the 
# R-file in src directory for evaluation.R. Then compile dokuments 
# based from presentation.txt
######################################################################
if [[ "$update" = "yes" && -f "$_PRESDATA" ]]
then
    ## Execute R script for graph and data
    $RR $SRC/evaluation.R
    ## Read in each directory to update, which has been
    ## updated in R-script
while read line
do
    dirs+=("$line")
done < "$_PRESDATA"
## Change to PrePostTest directory
cd ${COLLECT_SUB}
echo "============================================================="
printf "${GREEN}## Number of presentations to run: [%s] ##${NO_COLOUR}\n" "${#dirs[@]}}"
echo "============================================================="
## For each dir given by array dirs
count=1
for i in ${dirs[@]}
do
    ## Check if dir exist
    if [ -d $i ]
	then
	echo "============================================================="
	printf "${GREEN}## Presentation for: [%s] in progress (%s/%s) ##${NO_COLOUR}\n" "$i" "$count" "${#dirs[@]}"
	echo "============================================================="
	## Cd to that dir and compile presentation 
	cd "$i"	
	ls
        [ -f "$_PRES" ] && compilePre "$_PRES" || continue
	rm -f $dirtFile
	(( count++ ))
	## Back to 	 
	cd ${COLLECT_SUB}
    fi ## End If dir check
done ## End ForLoop dirs array
## remove dirs that are empty
find . -type d -empty -delete
fi ## End If update 





