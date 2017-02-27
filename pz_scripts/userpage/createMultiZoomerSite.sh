#!/bin/bash

# Author: Sebastian Schmittner (stp.schmittner@gmail.com)
# Date: 2014.11.24 23:40:07 (+01:00)
# LastAuthor: Sebastian Schmittner (stp.schmittner@gmail.com)
# LastDate: 2016.03.13 21:58:00 (+01:00)
# Version: 0.1.1

# Requirements:  Directories must be labeled according to the following scheme
#		 PATIENTIDPATIENTNUMBER_CHANNELNAME_ARBITRARYSTRING
#	         e.g. P02_Cycline_arbitrarytext
#
# Change log
# 0.1 Initial version
# 0.2 Visualization works (except sync)
# 0.3 Check hashtable and livesync for presence of *processed* 
# 0.6 Move files instead of copying (DO_FILES switch)
# 0.7 -maxdepth 2 added to ZOOMFILES - speed increase * 100
# 0.8 Adaption of paths to fit to the polyzoomer server
# 0.9 Add the copying of the dependencies from /templates/*
# 1.0 Remove tiling
# 1.1 Remove deepzoom    

DO_FILES=1 
DO_WEBSITE=1
PATH_TO_INSTALL_PACKAGE="/var/www/pz_scripts/userpage/"
WEBDIRECTORY="page"
#VIEWERNAME="poly"
WEBSERVERURLPREFIX="./" #e.g. polyzoomer
EXCLUDEFILES='-and ! -name *blocks* -and ! -name *template* -and ! -name . -and ! -wholename *${WEBDIRECTORY}* -and ! -name css -and ! -name static -and ! -name images -and ! -name blocks'
LINKSUFFIX="processed" # e.g. P02_HEprocessed  will be sync'ed with P02_HE

##################################################

# create polyzoomer directory structure

if [ $DO_FILES -eq "1" ]; then
  if [ ! -d "$WEBDIRECTORY" ]; then  #don't overwrite already existing website
    echo "Start creating filestructure for website ..."
    mkdir "$WEBDIRECTORY"
    cp -r "$PATH_TO_INSTALL_PACKAGE"/templates/* "$WEBDIRECTORY"
  fi
else
  echo "[ERROR]: Website directory already exists!"
fi


# create website
VIEWERCOUNTER=0
if [ $DO_WEBSITE -eq "1" ]; then
	echo "Start generating website ..."
	cd "$WEBDIRECTORY"

	COLS=`sed '1q;d' ../setup.cfg`
	ROWS=`sed '2q;d' ../setup.cfg`
	EMAIL=`sed '3q;d' ../setup.cfg`
	ITEMS=`expr $COLS \* $ROWS`

	echo "Processing ${f}"
	echo "" > _tmpviewer #create tmp viewer html file
	echo "" > _tmpbody2  #create tmp hashtable html file

	mkdir "./INDEX"
	PATHTOINDEX="./INDEX/index.html"
	echo "./INDEX/index.html" >> "./indexes"

	cat ./blocks/header.block > ${PATHTOINDEX} #create index file
	#replace tags
	sed -i "s/_PATH_TO_CSS_/..\/css/g" "${PATHTOINDEX}" 
	sed -i "s/_PATH_TO_POLYZOOMER_/../g" "${PATHTOINDEX}"   
	
	ALPHAVIEWER="contentDiv0"
	
	for Y in `seq 1 $ROWS`;
	do
  
		echo "<tr>" >> _tmpviewer
		
		for X in `seq 1 $COLS`;
		do

			CONTENTID="contentDiv${VIEWERCOUNTER}"
			
			ITEMSPERROW=2
			X1=`expr $X - 1`
			Y1=`expr $Y - 1`
			XI=`expr $ROWS \* $X1 \* $ITEMSPERROW`
			YI=`expr 4 + $Y1 \* $ITEMSPERROW`
			
			INDEXDZI=`expr $XI + $YI`
			INDEXALPHA=`expr $INDEXDZI + 1`
			
			DZI=`sed "${INDEXDZI}q;d" ../setup.cfg`
			ALPHA=`sed "${INDEXALPHA}q;d" ../setup.cfg`
	
			if [[ -z $DZI ]]
			then
				echo "<td></td>" >> _tmpviewer
				continue
			fi
				
			if [[ $ALPHA == *1* ]]
			then
				ALPHAVIEWER=$CONTENTID
			fi
			
			echo "LiveSync(${CONTENTID});" >> "${PATHTOINDEX}"   # corresponding PROCESSED file found	      
			#echo "addColorPicker(document.getElementById('${CONTENTID}'), ${CONTENTID});" >> "${PATHTOINDEX}"  
			#echo "addPrintHandler(${CONTENTID});" >> "${PATHTOINDEX}" 

			VIEWERNAME=`basename "${DZI}"`
			NDPIKEY=".ndpideepzoom.dzi"
			KEYUNKNOWN="UNKNOWNPAT0001_UNKNOWNCHANNEL0001_"
			VIEWERNAME="${VIEWERNAME/$NDPIKEY}"
			VIEWERNAME="${VIEWERNAME/$KEYUNKNOWN}"
			
			# read: get the _ positions, get the numbers infront of the : and get the second in the list
			#SECONDUNDERSCORE=`echo $VIEWERNAME | grep -b -o '_' | cut -d: -f1 | sed '2!d;q'`

			#if [[ $VIEWERNAME == *"UNKNOWN"* ]]
			#then
				# get the file name part
				#VIEWERNAME=${VIEWERNAME:$SECONDUNDERSCORE + 1}
			#else
				# get the detected patient and channel id
				#VIEWERNAME=${VIEWERNAME:0:$SECONDUNDERSCORE}
			#fi
			
			cat ./blocks/viewer.block >> "_tmpviewer"
			##
			#not stored in header but pre-created to concat to body afterwards
			##
			PATHTOVIEWERIMAGE="..\/images\/"
			PATHTODZI="/${WEBDIRECTORY}/${PAT_ID}/${CHANNEL_ID}"
			#replace tags
			sed -i "s/_CONTENTID_/${CONTENTID}/g" "_tmpviewer"     
			sed -i "s/_REL_PATH_TO_VIEWERIMAGES_/${PATHTOVIEWERIMAGE}/g" "_tmpviewer"
			sed -i "s|_REL_PATH_TO_DZI_|${DZI}|g" "_tmpviewer"
			sed -i "s/_VIEWERNAME_/${VIEWERNAME}/g" "_tmpviewer"
			sed -i "s/_VIEWER_VARNAME_/${CONTENTID}/g" "_tmpviewer"  #important for hash table later    
			let VIEWERCOUNTER=VIEWERCOUNTER+1      
			
			if [[ $ALPHA != *1* ]]
			then
				echo "ViewerHash['_VIEWERID_'] = _VIEWERVARNAME_;" >> _tmpbody2
				sed -i "s/_VIEWERID_/${CONTENTID}/g" "_tmpbody2"     
			fi

			#replace tags
			#sed -i "s/_VIEWERVARNAME_/${PAT_ID}${CHANNEL_ID}${LINKSUFFIX}/g" "_tmpbody2"

		done

		echo "</tr>" >> _tmpviewer
	
	done
	
	sed -i "s/_VIEWERVARNAME_/${ALPHAVIEWER}/g" "_tmpbody2"
  
	cat ./blocks/body1.block >> "${PATHTOINDEX}"

	#add viewer scripts
	cat ./_tmpviewer >> "${PATHTOINDEX}"
		
	#echo "</tr>" >> "${PATHTOINDEX}"
	echo "</table>" >> "${PATHTOINDEX}"
	echo "<script type="text/javascript">" >> "${PATHTOINDEX}"
	echo "var ViewerHash = new Object();"  >> "${PATHTOINDEX}"
	cat ./_tmpbody2 >> "${PATHTOINDEX}" 
	echo "</script>" >> "${PATHTOINDEX}"
	echo "</body>" >> "${PATHTOINDEX}"
fi

 # FILES=`find . -maxdepth 1 -type d ${EXCLUDEFILES}`  
#  for f in $FILES
  #do

	


    #for c in $CHANNELS; do

      #search for DZI files (could be png or jpg)
#	  TMPDZI=`find . -name "*.dzi" -type f -print -quit` 
	  #DZINAME=`basename "$TMPDZI"`   

		
	  #echo $TMPDZI
	  #echo $DZINAME
	  
	  #CHANNEL_ID=`echo ${c} | egrep -i -o '*_[a-z]+[0-9]*' | head -1`  #e.g. _CyclineA
      
      #check if current image has a corresponding processed one
 #     HASPROCESSED=$(checkIfProcessedFileAvailable ${PAT_ID}${CHANNEL_ID})
      #HASPROCESSED=`echo $HASPROCESSED | sed 's/[^0-9]//g'` #remove spaces      
      #if [ $HASPROCESSED -eq "1" ]; then
        #echo "${PAT_ID}${CHANNEL_ID} has processed image ${PAT_ID}${CHANNEL_ID}processed"      	      
        #echo "LiveSync(${PAT_ID}${CHANNEL_ID})" >> "${PATHTOINDEX}"   # corresponding PROCESSED file found	      
      #else
        #echo "//LiveSync(${PAT_ID}${CHANNEL_ID})" >> "${PATHTOINDEX}"      	      
      #fi            
#      
	  #echo "addColorPicker(document.getElementById('${PAT_ID}${CHANNEL_ID}'), ${PAT_ID}${CHANNEL_ID});" >> "${PATHTOINDEX}"  
	  #
	  #write to tmp html file that is concated later to the body of the file
      #cat ./blocks/viewer.block >> "_tmpviewer"
      ##
      #not stored in header but pre-created to concat to body afterwards
      ##
      #PATHTOVIEWERIMAGE="..\/images\/"
      #PATHTODZI="/${WEBDIRECTORY}/${PAT_ID}/${CHANNEL_ID}"
      #replace tags
#      sed -i "s/_CONTENTID_/${PAT_ID}${CHANNEL_ID}/g" "_tmpviewer"     
      #sed -i "s/_REL_PATH_TO_VIEWERIMAGES_/${PATHTOVIEWERIMAGE}/g" "_tmpviewer"
      #sed -i "s|_REL_PATH_TO_DZI_|./${CHANNEL_ID}/${DZINAME}|g" "_tmpviewer"
      #sed -i "s/_VIEWERNAME_/${PAT_ID}${CHANNEL_ID}/g" "_tmpviewer"
      #sed -i "s/_VIEWER_VARNAME_/${PAT_ID}${CHANNEL_ID}/g" "_tmpviewer"  #important for hash table later    
      #let VIEWERCOUNTER=VIEWERCOUNTER+1      
      
	  ##
      # hash tables for linking
      ##
      #if [ $HASPROCESSED -eq "1" ]; then      
      	      #echo "ViewerHash['_VIEWERID_'] = _VIEWERVARNAME_;" >> _tmpbody2
      	      ##replace tags
      	      #sed -i "s/_VIEWERID_/${PAT_ID}${CHANNEL_ID}/g" "_tmpbody2"     
      	      #sed -i "s/_VIEWERVARNAME_/${PAT_ID}${CHANNEL_ID}${LINKSUFFIX}/g" "_tmpbody2"
      #else
      	      #echo "//ViewerHash['_VIEWERID_'] = _VIEWERVARNAME_;" >> _tmpbody2
      	      ##replace tags
      	      #sed -i "s/_VIEWERID_/${PAT_ID}${CHANNEL_ID}/g" "_tmpbody2"     
      	      #sed -i "s/_VIEWERVARNAME_/${PAT_ID}${CHANNEL_ID}${LINKSUFFIX}/g" "_tmpbody2"      	      
      #fi
      	      #

    #done
  #close header
#  echo "}" >> "${PATHTOINDEX}"
#  echo "</script>" >> "${PATHTOINDEX}"
#  echo "</head>" >> "${PATHTOINDEX}"

  #cat ./blocks/body1.block >> "${PATHTOINDEX}"

  #add viewer scripts
  #cat ./_tmpviewer >> "${PATHTOINDEX}"

  #add last part (hash)
#  echo "</tr>" >> "${PATHTOINDEX}"
  #echo "</table>" >> "${PATHTOINDEX}"
  #echo "<script type="text/javascript">" >> "${PATHTOINDEX}"
  #echo "var ViewerHash = new Object();"  >> "${PATHTOINDEX}"
  #cat ./_tmpbody2 >> "${PATHTOINDEX}" 
  #echo "</script>" >> "${PATHTOINDEX}"
  #echo "</body>" >> "${PATHTOINDEX}"
  #done

#fi
