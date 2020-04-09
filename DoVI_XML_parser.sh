#!/bin/bash

#---INPUT PARAMETER $1 IS A VALID PATH TO A VALID DOLBY VISION METADATA XML FILE
INPUTXML=$1
XML=$(cat $INPUTXML)
#---ARRAY POPULATE MADE WITH \n PARSING
OLDIFS="$IFS"

# FUNCTIONS
# parseXML embeds xmllint function to return XML elements and values based on Xpath syntax
parseXML()
{
  local XPATH=$1
  echo "$XML" | xmllint --xpath "$XPATH" -
}
# populateDoVIMetaList populates an array with all columns (separated by semicolumns ";") and lines (based on frame number) prior to its editions on an .csv file. 
function populateDoVIMetaList()
{
local ARG2=$2
local INDEX=$1
local SHOTN=INDEX+1
if [[ "$INDEX" == "init" ]]; then
  CSVARRAY[0]=$(echo "MetaScope;Shot#;FrameIn;FrameOut;Duration;L1 Status;minPQ;avgPQ;maxPQ;L2 Status;L1 min offset;L1 avg offset;L1 max offset;Lift;Gain;Gamma;Saturation;Chrome;Tone Detail;IssueFound")
else
  if [[ $ARG2 == "Shot" ]]; then
  CSVARRAY[((${FRAMEINS[$INDEX]}+1))]=$(echo "Shot;$INDEX;${FRAMEINS[$INDEX]};${FRAMEOUTS[$INDEX]};${FRAMEDURATIONS[$INDEX]};${L1Status[$INDEX]};${MINPQ[$INDEX]};${AVGPQ[$INDEX]};${MAXPQ[$INDEX]};${LE2TID1Status[$INDEX]};${L2TIDl1minoffset[$INDEX]};${L2TIDl1avgoffset[$INDEX]};${L2TIDl1maxoffset[$INDEX]};${L2TIDlift[$INDEX]};${L2TIDgain[$INDEX]};${L2TIDgamma[$INDEX]};${L2TIDsaturation[$INDEX]};${L2TIDchroma[$INDEX]};${L2TIDToneDetail[$INDEX]};${SHOTISSUES[$INDEX]}")
  elif [[ $ARG2 == "FrameOffset" ]]; then
  CSVARRAY[((${XFADEFRAMEINS[$INDEX]}+1))]=$(echo "Frame;;${XFADEFRAMEINS[$INDEX]};;;${XL1Status[$INDEX]};${XMINPQ[$INDEX]};${XAVGPQ[$INDEX]};${XMAXPQ[$INDEX]};${XLE2TID1Status[$INDEX]};${XL2TIDl1minoffset[$INDEX]};${XL2TIDl1avgoffset[$INDEX]};${XL2TIDl1maxoffset[$INDEX]};${XL2TIDlift[$INDEX]};${XL2TIDgain[$INDEX]};${XL2TIDgamma[$INDEX]};${XL2TIDsaturation[$INDEX]};${XL2TIDchroma[$INDEX]};${XL2TIDToneDetail[$INDEX]};${FRAMEISSUES[$INDEX]}")
  fi
fi
}
# doViMetaListToCSV edits a new .csv file based on $CSVARRAY array
function doViMetaListToCSV (){
CSVFILE="$METADATANAME""_DoVIMeta.csv"
[[ -n "$CSVFILE" ]] && rm "$CSVFILE"
for LINE in ${!CSVARRAY[@]}
do
  echo "${CSVARRAY[$LINE]}">>"$CSVFILE"
done
}

function editReport (){
NEWMESSAGE=$1
if [[ "$NEWMESSAGE" = "INIT" ]]; then
  ((NEWLINE=0))
else
  REPORT[$NEWLINE]="$NEWMESSAGE"
  echo -e "${REPORT[$NEWLINE]}"
  ((NEWLINE=$NEWLINE+1))
fi
}
editReport INIT

function createReport (){
REPORTFILE="$METADATANAME""_Report.txt"
[[ -n "$REPORTFILE" ]] && rm "$REPORTFILE"
echo "">"$REPORTFILE"
for REPORTLINE in ${!REPORT[@]}
do
echo -e "${REPORT[$REPORTLINE]}">>"$REPORTFILE"
done
./$REPORTFILE
}

# function exractXMLElements (){
# XMLPART=$1
# BALISE=$2
# local RETURN=$(echo "$XMLPART" | sed -z 's/.*<\$BALISE>\(.*\)<\/\$BALISE>.*/\1/')
# echo $RETURN
# }


#---------------------------------------- Revision history -----------------------------------------------------------#
#number of revision
REVISIONCOUNT=$(parseXML "count(/DolbyLabsMDF/RevisionHistory/Revision)")

# for each revision, returns Software, Date, Author, Software & Software version
IFS=$'\n'
SOFTWAREVS=($(parseXML "/DolbyLabsMDF/RevisionHistory/Revision/Software/text()"))
MODIFIEDDATEVS=($(parseXML "/DolbyLabsMDF/RevisionHistory/Revision/DateTime/text()"))
AUTHORVS=($(parseXML "/DolbyLabsMDF/RevisionHistory/Revision/Author/text()"))
SOFTWAREVS=($(parseXML "/DolbyLabsMDF/RevisionHistory/Revision/Software/text()"))
SOFTWAREVERSIONVS=($(parseXML "/DolbyLabsMDF/RevisionHistory/Revision/SoftwareVersion/text()"))
IFS=$OLDIFS

#---- is this a revised version ? (number of <revision> node. if 1 it is the fisrt version ever generated
#---- if not, display last history by DATE/AUTHOR/SOFTWARE/SOFTWAREVERSION
let I=1
if [ $REVISIONCOUNT > 1 ]; then
  editReport "REVISION HISTORY\nThere are $REVISIONCOUNT versions:"
  while [ $I -le $REVISIONCOUNT ]
    do
    editReport "DoVI metadata XML's version file number $I generated on ${MODIFIEDDATEVS[((I-1))]} by: ${AUTHORVS[((I-1))]} -- ${SOFTWAREVS[((I-1))]} -- ${MODIFIEDDATEVS[((I-1))]}"
    let I=I+1
    done
  else
  #---- if it is, display all history by HISTORYNUMBER/DATE/AUTHOR/SOFTWARE/SOFTWAREVERSION
  editReport " This is the first version of the DoVI metadata XML's file:\n${MODIFIEDDATEVS[last()]} by: ${AUTHORVS[last()]} -- ${SOFTWAREVS[last()]} -- ${MODIFIEDDATEVS[last()]}"
fi


#------------------------------------------------------------ GENERIC METADATA INFORMATION-----------------------------------------------------#

# Source display
# nom de la metadata Outputs/Output[name=.*]
METADATANAME=$(parseXML "/DolbyLabsMDF/Outputs/Output/@name" | sed 's/name="\(.*\)"$/\1/')
editReport "GENERIC METADATA INFORMATION\nDoVi CM metadata filename is: $METADATANAME"
# version de la metadata (2.0.5, 4.0.2 ...)
CMV=$(parseXML "/DolbyLabsMDF/@version" | sed 's/.*="\([0-9.]*\)".*/\1/')
editReport "Metadata version is CMv=$CMV"
# param cadre diffuser (à afficher et convertir en ligne*pix) Outputs/output/CanvasAspectRatio
CANVASASPECTRATIO=$(parseXML "/DolbyLabsMDF/Outputs/Output/CanvasAspectRatio/text()")
editReport "Canvas aspect ratio is: $CANVASASPECTRATIO"  
# param cadre util (à afficher et convertir en ligne*pix) Outputs/output/ImageAspectRatio
IMAGEASPECTRATIO=$(parseXML "/DolbyLabsMDF/Outputs/Output/ImageAspectRatio/text()")
editReport "Image aspect ratio is: $IMAGEASPECTRATIO" 
# Outputs/Output/video/rate   cadence image de la metadata(<n>f</n>p<d>s</d>)
METAFRAMERATEN=$(parseXML "/DolbyLabsMDF/Outputs/Output/Video/Track/Rate/n/text()")
METAFRAMERATED=$(parseXML "/DolbyLabsMDF/Outputs/Output/Video/Track/Rate/d/text()")
let METAFRAMERATE="METAFRAMERATEN / METAFRAMERATED"
editReport "DoVi metadatas' framerate  is set at $METAFRAMERATE fps"
#Outputs/Output/video/ColorEncoding/Primaries/Red /Green /Blue (arg: x,y) déclaration des extremes colorimétriques du VDM
SOURCECOLORSPACE=$(parseXML "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/Primaries")
# SOURCECOLORSPACER=$(exractXMLElements "$SOURCECOLORSPACE" "Red")
# SOURCECOLORSPACEG=$(exractXMLElements "$SOURCECOLORSPACE" "Green")
# SOURCECOLORSPACEB=$(exractXMLElements "$SOURCECOLORSPACE" "Blue")
SOURCECOLORSPACER=$(parseXML "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/Primaries/Red/text()")
SOURCECOLORSPACEG=$(parseXML "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/Primaries/Green/text()")
SOURCECOLORSPACEB=$(parseXML "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/Primaries/Blue/text()")
#4 Scenaris based on 3 color space REC703, P3, REC 2020, Unknown
SOURCECOLORSPACERx=$(echo $SOURCECOLORSPACER | sed 's/\([0-9\.]\),.*/\1/' | sed 's/^\(0,[0-9]*[1-9]\)0*$/\1/')
SOURCECOLORSPACERy=$(echo $SOURCECOLORSPACER | sed 's/.*,\([0-9\.]\)/\1/' | sed 's/^\(0,[0-9]*[1-9]\)0*$/\1/')
SOURCECOLORSPACER="$SOURCECOLORSPACERx"",""$SOURCECOLORSPACERy"

SOURCECOLORSPACEGx=$(echo $SOURCECOLORSPACEG | sed 's/\([0-9\.]\),.*/\1/' | sed 's/^\(0,[0-9]*[1-9]\)0*$/\1/')
SOURCECOLORSPACEGy=$(echo $SOURCECOLORSPACEG | sed 's/.*,\([0-9\.]\)/\1/' | sed 's/^\(0,[0-9]*[1-9]\)0*$/\1/')
SOURCECOLORSPACEG="$SOURCECOLORSPACEGx"",""$SOURCECOLORSPACEGy"

SOURCECOLORSPACEBx=$(echo $SOURCECOLORSPACEB | sed 's/\([0-9\.]\),.*/\1/' | sed 's/^\(0,[0-9]*[1-9]\)0*$/\1/')
SOURCECOLORSPACEBy=$(echo $SOURCECOLORSPACEB | sed 's/.*,\([0-9\.]\)/\1/' | sed 's/^\(0,[0-9]*[1-9]\)0*$/\1/')
SOURCECOLORSPACEB="$SOURCECOLORSPACEBx"",""$SOURCECOLORSPACEBy"
editReport "Picture source declared primaries chromaticities coordinates are:\nR(x,y) $SOURCECOLORSPACER\nG(x,y) $SOURCECOLORSPACEG\nB(x,y) $SOURCECOLORSPACEB"
[ "$SOURCECOLORSPACER" == "0.64,0.33" ] && [ "$SOURCECOLORSPACEG" == "0.3,0.6" ] && [ "$SOURCECOLORSPACEB" == "0.15,0.06" ] && SOURCECOLORSPACE="REC709" && editReport "Picture source is declared for a REC.709 master target display.\n this is an odd value based on Dolby Vision's best practice guide, color gammut should be wider than REC709" 
[ "$SOURCECOLORSPACER" == "0.68,0.32" ] && [ "$SOURCECOLORSPACEG" == "0.265,0.69" ] && [ "$SOURCECOLORSPACEB" == "0.15,0.06" ] && SOURCECOLORSPACE="P3" && editReport "Picture source is declared for a P3 master target display." 
[ "$SOURCECOLORSPACER" == "0.708,0.292" ] && [ "$SOURCECOLORSPACEG" == "0.17,0.797" ] && [ "$SOURCECOLORSPACEB" == "0.131,0.046" ] && SOURCECOLORSPACE="REC2020" && editReport "Picture source is declared for a REC.2020 master target display."

# à determiner par rapport au diagramme de chromaticité 1331 (P3 BT.2020 REC.709, Unknown)
#Outputs/Output/video/ColorEncoding/WhitePoint coordonée point blanc (arg:x,y) à pointer et determiner selon Chrom 1331 (D65,D60, DCI, unknown)
SOURCEWHITEPOINT=$(parseXML "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/WhitePoint/text()")
SOURCEWHITEPOINTx=$(echo $SOURCEWHITEPOINT | sed 's/\([0-9\.]\),.*/\1/' | sed 's/^\(0,[0-9]*[1-9]\)0*$/\1/')
SOURCEWHITEPOINTy=$(echo $SOURCEWHITEPOINT | sed 's/.*,\([0-9\.]\)/\1/' | sed 's/^\(0,[0-9]*[1-9]\)0*$/\1/')
SOURCEWHITEPOINTxy="$SOURCEWHITEPOINTx"",""$SOURCEWHITEPOINTy"
editReport "Picture source declared white point chromaticities coordinates are: $SOURCEWHITEPOINT"
[ "$SOURCEWHITEPOINTxy" == "0.3127,0.329" ] && SOURCEWHITEPOINT="D65" && editReport "Picture source is declared for a D65 white point master target display."
#Outputs/Output/video/ColorEncoding/Encoding doit être identifié en "PQ" (Perceptual Quantizer)
SOURCEEOTF=$(parseXML "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/Encoding/text()")
editReport "Picture source declared EOTF is: $SOURCEEOTF"
[ "$SOURCEEOTF" = "pq" ] && SOURCEEOTF="ST.2084" || editReport "Picture source declared EOTF ($SOURCEEOTF) is not compliant with Dolby Vision CM workflow."
#Outputs/Output/video/ColorEncoding/<MinimumBrightness>0 (echelle absolue de la dynamique du luminance idéale dit être inférieur à 1nits)
#Outputs/Output/video/ColorEncoding/<PeakBrightness>10000 (echelle absolue de la dynamique du luminance idéale doit être égale à 10000nits)
SOURCEMINBRT=$(parseXML "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/MinimumBrightness/text()")
SOURCEMAXBRT=$(parseXML "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/PeakBrightness/text()")
editReport "Picture source theoritical min,max brightness: $SOURCEMINBRT,$SOURCEMAXBRT nits"

#Outputs/Output/video/ColorEncoding/<BitDepth>16 résolution de la dynamique du signal, doit coresspondre au fichier source
SOURCEBITDEPTH=$(parseXML "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/BitDepth/text()")
editReport "Source declared bit depth: $SOURCEBITDEPTH"
#Outputs/Output/video/ColorEncoding/<ColorSpace>rgb interpretation chromatique des composantes colorimétriques de la source image (doit correspondre au fichier source)
SOURCECOLORCOMP=$(parseXML "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/ColorSpace/text()")
editReport "Source declared color components: $SOURCECOLORCOMP"
#Outputs/Output/video/ColorEncoding/<ChromaFormat>444 quantification (si RGB doit être 444 & doit correspondre au fichier source dans tous les cas doit être 444)
SOURCECHROMAFORMAT=$(parseXML "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/ChromaFormat/text()")
editReport "Source declared chromat quantification is: $(echo "$SOURCECHROMAFORMAT" | sed 's/\([0-9]\)\([0-9]\)\([0-9]\)/\1:\2:\3/g')"
#Outputs/Output/video/ColorEncoding/<SignalRange>computer (paramètre indéfinit, doit correspondre au fichier source et dans l'idéal doit toujours être en full (0N à 1024B)
SOURCESIGRANGE=$(parseXML "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/SignalRange/text()")
editReport "Source declared signal range is: $SOURCESIGRANGE"
# level 6 optionnel, valeur MaxFALL (Frame Average Light Level) MaxCLL (Max Constant Light Level), simplement afficher, si 0 0  MaxFALL > MaxCLL & Max FALL MaxCLL < Mastering display PK brt
OPTMAXFALL=$(parseXML "/DolbyLabsMDF/Outputs/Output/Video/Track[@name]/Level6/MaxFALL/text()")
OPTMAXCLL=$(parseXML "/DolbyLabsMDF/Outputs/Output/Video/Track[@name]/Level6/MaxCLL/text()")
editReport -e "Level6 = Optionnal Max FALL & Max CLL measurement for the whole program duration:\nMaxFall = $OPTMAXFALL\nMaxCLL = $OPTMAXCLL"
[ "$OPTMAXFALL" = 0 ] && [ "$OPTMAXCLL" = "$OPTMAXFALL" ] && editReport "Max FLL and Max CLL values haven't been injected into Dolby Vision CM metadata as per level 6" 
[ "$OPTMAXFALL" != 0 ] && [ "$OPTMAXFALL" -ge "$OPTMAXCLL" ] && editReport "non-coherent Max FALL and Max CLL value declaration. MaxFALL cannot bu greater or equal to MaxCLL"
# [ "$OPTMAXCLL" -gt "$MDMAXBRT" ] && echo "Measured max CLL (maximum peak brightness ever measured on whole program for a given pixel cannot be greater than the declared maximum peak brightness value of the mastering display"

#Declaration Mastering Display


#/DolbyLabsMDF/Outputs/Output/Video/Track[@name]/PluginNode/DolbyEDR/Characteristics level="0"/<MasteringDisplay level="0">/<Name>
# afficher et garder en mémoire les caracteristiques du mastering display: 
MD=$(parseXML "/DolbyLabsMDF/Outputs/Output/Video/Track[@name]/PluginNode/DolbyEDR/Characteristics [@level ='0']/MasteringDisplay [@level = '0']/Name/text()")
editReport "Mastering display signature: $MD"
MDMAXNIT=$(echo "$MD" | sed 's/\([0-9]*\)-nit.*$/\1/')
editReport "Mastering display maximum brightness is: $MDMAXNIT nits."
MDCOLORSPACE=$(echo "$MD" | sed 's/.*-nit,\s\([^,]*\),.*$/\1/ ')
editReport "Mastering display color space is: $MDCOLORSPACE."
MDWHITEPOINT=$(echo "$MD" | sed 's/.*-nit,\s[^,]*,\s\([^,]*\),.*$/\1/ ')
editReport "Mastering display white point is: $MDWHITEPOINT."
MDEOTF=$(echo "$MD" | sed 's/.*-nit,\s[^,]*,\s[^,]*,\s\([^,]*\),.*$/\1/ ')
editReport "Mastering display EOTF is: $MDEOTF."
MDSIGRANGE=$(echo "$MD" | sed 's/.*-nit,\s[^,]*,\s[^,]*,\s[^,]*,\s\([^,]*\)$/\1/')
editReport "Mastering display signal range is: $MDSIGRANGE."

#Déclaration Target Display

#Compter le nombre de target display. Si il y en a qu'un vérifier qu'il s'agit bien du TID=1 (100-nit, BT.709, BT.1886, Full).
#count(/DolbyLabsMDF/Outputs/Output/Video/Track[@name]/PluginNode/DolbyEDR/Characteristics level="0"/TargetDisplay level="0")

TID1=$(parseXML "/DolbyLabsMDF/Outputs/Output/Video/Track[@name]/PluginNode/DolbyEDR/Characteristics [@level ='0']/TargetDisplay [@level = '0'] [ID="1"]/Name/text()")
editReport "Target display number 1 (SDR target) signature: $TID1"
TID1MAXNIT=$(echo "$TID1" | sed 's/\([0-9]*\)-nit.*$/\1/')
editReport "Target display number 1 (SDR target) maximum brightness is: $TID1MAXNIT nits."
TID1COLORSPACE=$(echo "$TID1" | sed 's/.*-nit,\s\([^,]*\),.*$/\1/ ')
editReport "Target display number 1 (SDR target) color space is: $TID1COLORSPACE."
TID1EOTF=$(echo "$TID1" | sed 's/.*-nit,\s[^,]*,\s\([^,]*\),.*$/\1/ ')
editReport "Target display number 1 (SDR target) EOTF is: $TID1EOTF."
TID1SIGRANGE=$(echo "$TID1" | sed 's/.*-nit,\s[^,]*,\s[^,]*,\s\([^,]*\)$/\1/')
editReport "Target display number 1 (SDR target) signal range is: $TID1SIGRANGE."

TID1WHITEPOINT=$(parseXML "/DolbyLabsMDF/Outputs/Output/Video/Track[@name]/PluginNode/DolbyEDR/Characteristics [@level ='0']/TargetDisplay [@level = '0']/WhitePoint/text()" )
TID1WHITEPOINTx=$(echo $TID1WHITEPOINT | sed 's/\([0-9\.]\),.*/\1/' | sed 's/^\(0,[0-9]*[1-9]\)0*$/\1/')
TID1WHITEPOINTy=$(echo $TID1WHITEPOINT | sed 's/.*,\([0-9\.]\)/\1/' | sed 's/^\(0,[0-9]*[1-9]\)0*$/\1/')
TID1WHITEPOINT="$TID1WHITEPOINTx"",""$TID1WHITEPOINTy"



#--------------------------------------------------- SHOTS METADATA DOLBY VISION CMv2.0.5 METADATA ---------------------------------------------------------#
# METADATA SHOT COUNTS
CMSHOTS=$(parseXML "count(//Shot)")
editReport "Number of metadatashot: $CMSHOTS".
# CSV print of all shots (FRAMESTART;FRAME DURATION;FRAMEEND;TCIN;TCOUT;MinPQ;AvgPQ;MaxPQ;TID;...WIP
IFS=$'\n'
SHOTUUID=($(parseXML "//Shot/UniqueID/text()"))
FRAMEINS=($(parseXML "//Shot/Record/In/text()"))
FRAMEDURATIONS=($(parseXML "//Shot/Record/Duration/text()"))
IMAGECHARACTERISTICS=($(parseXML "//Shot/PluginNode/DolbyEDR [@level="1"]/ImageCharacter/text()"))
L2TID1=($(parseXML "//Shot/PluginNode/DolbyEDR [@level="2"] [TID=1]/Trim/text()"))
# L2 param: L1minOffset,L1avgOffset,L&MaxOffset,Lift,Gain,Gamma,Saturation,Chroma,Tone Detail
IFS="$OLDIFS"

populateDoVIMetaList init
for SHOTN in "${!SHOTUUID[@]}"; do
  ((FRAMEOUTS[$SHOTN]=${FRAMEINS[$SHOTN]}+${FRAMEDURATIONS[$SHOTN]}-1)) 
  if [[ -z ${IMAGECHARACTERISTICS[$SHOTN]} ]]; then
    L1Status[$SHOTN]="Not Defined"
    MINPQ[$SHOTN]=""
    AVGPQ[$SHOTN]=""
    MAXPQ[$SHOTN]=""
  elif [[ ${IMAGECHARACTERISTICS[$SHOTN]} =~ ([0-9.]*),([0-9.]*),([0-9.]*) ]]; then
      MINPQ[$SHOTN]=${BASH_REMATCH[1]}
      AVGPQ[$SHOTN]=${BASH_REMATCH[2]}
      MAXPQ[$SHOTN]=${BASH_REMATCH[3]}
  fi
  if [[ -z ${L2TID1[$SHOTN]} ]]; then
    LE2TID1Status[$SHOTN]="Not Defined"
    L2TIDl1minoffset[$SHOTN]=""
    L2TIDl1avgoffset[$SHOTN]=""
    L2TIDl1maxoffset[$SHOTN]=""
    L2TIDlift[$SHOTN]=""
    L2TIDgain[$SHOTN]=""
    L2TIDgamma[$SHOTN]=""
    L2TIDsaturation[$SHOTN]=""
    L2TIDchroma[$SHOTN]=""
    L2TIDToneDetail[$SHOTN]=""
  elif [[ ${L2TID1[$SHOTN]} =~ ([0-9.\-]*),([0-9.\-]*),([0-9.\-]*),([0-9.\-]*),([0-9.\-]*),([0-9.\-]*),([0-9.\-]*),([0-9.\-]*),([0-9.\-]*) ]]; then
    L2TIDl1minoffset[$SHOTN]=${BASH_REMATCH[1]}
    L2TIDl1avgoffset[$SHOTN]=${BASH_REMATCH[2]}
    L2TIDl1maxoffset[$SHOTN]=${BASH_REMATCH[3]}
    L2TIDlift[$SHOTN]=${BASH_REMATCH[4]}
    L2TIDgain[$SHOTN]=${BASH_REMATCH[5]}
    L2TIDgamma[$SHOTN]=${BASH_REMATCH[6]}
    L2TIDsaturation[$SHOTN]=${BASH_REMATCH[7]}
    L2TIDchroma[$SHOTN]=${BASH_REMATCH[8]}
    L2TIDToneDetail[$SHOTN]=${BASH_REMATCH[9]}
  fi
populateDoVIMetaList $SHOTN "Shot"
# printf "Shot n:%d in:%d Lvl1-- min:%b avg:%b max:%b\n" "$SHOTN" "${FRAMEINS[$SHOTN]}" "${MINPQ[$SHOTN]}" "${AVGPQ[$SHOTN]}" "${MAXPQ[$SHOTN]}"
# printf "TID1 Trim shot n:%d in: %d %b(%b,%b,%b,%b,%b,%b,%b,%b,%b)\n" "$SHOTN" "${FRAMEINS[$SHOTN]}" "${LE2TID1Status[$SHOTN]}" "${L2TIDl1minoffset[$SHOTN]}" "${L2TIDl1avgoffset[$SHOTN]}" "${L2TIDl1maxoffset[$SHOTN]}" "${L2TIDlift[$SHOTN]}" "${L2TIDgain[$SHOTN]}" "${L2TIDgamma[$SHOTN]}" "${L2TIDsaturation[$SHOTN]}" "${L2TIDchroma[$SHOTN]}" "${L2TIDToneDetail[$SHOTN]}"
done

#------Xfade (<EditOffset>) parsing
# Shot count where edit offset nodes exist
XFADESHOTSCOUNT=$(parseXML "count(//Shot[Frame/EditOffset])")
editReport "There are $XFADESHOTSCOUNT shots where Dovi metadata per frame (of an existing fade editing) are applied"

#Edit Offset. Level 1 and potential Level 2 Parsing
IFS=$'\n'
XFADESHOTUUID=($(parseXML "//Shot[Frame/EditOffset[last()]]/UniqueID/text()"))
XFADEFRAMEENTRIES=($(parseXML "//Shot/Frame/EditOffset/text()"))
XFADEIMAGECHARACTERISTICS=($(parseXML "//Shot/Frame/PluginNode/DolbyEDR [@level="1"]/ImageCharacter/text()"))
XFADEL2TID1=($(parseXML "//Shot/Frame/PluginNode/DolbyEDR [@level="2"] [TID=1]/Trim/text()"))
# L2 param: L1minOffset,L1avgOffset,L&MaxOffset,Lift,Gain,Gamma,Saturation,Chroma,Tone Detail
XFADESHOTFRAMEINS=($(parseXML "//Shot[Frame/EditOffset]/Record/In/text()"))
XFADESHOTUUIDS=($(parseXML "//Shot[Frame/EditOffset]/UniqueID/text()"))
IFS="$OLDIFS"

#--------
#Determiner le numéro d'image en entrée pour chaque plan composé de frame offset

#pour chacun de ces plans determiner le nombre de frame offset
for XFADESHOTINDEX in ${!XFADESHOTFRAMEINS[@]}; do
    XFADEFRAMEOFFSETCOUNT[XFADESHOTINDEX]=$(parseXML "count(//Shot[Record/In="${XFADESHOTFRAMEINS[$XFADESHOTINDEX]}"]/Frame/EditOffset)")
# echo "$XFADESHOTINDEX -${XFADESHOTFRAMEINS[$XFADESHOTINDEX]} - ${XFADEFRAMEOFFSETCOUNT[$XFADESHOTINDEX]}"
done
#Pour chacun de ces plans sommer l'image d'entrée avec toutes les valeurs frame offsets correspondant
((XFADESHOTINDEX=0))
((XFADEFRAMEINDEX=0))
((LastXFADEFRAMETOTAL=0))

for XFADEFRAMECOUNT in ${XFADEFRAMEOFFSETCOUNT[@]}; do
# echo "loop 2 nombre d'image de Xfade de ce plan"
  ((XFADEFRAMETOTAL=$XFADEFRAMECOUNT+$LastXFADEFRAMETOTAL))
  while [ $XFADEFRAMEINDEX -lt $XFADEFRAMETOTAL ]; do
    # echo "Addition autant qu'il y a d'images xfade dans ce plan"
    ((XFADEFRAMEINS[XFADEFRAMEINDEX]=${XFADESHOTFRAMEINS[$XFADESHOTINDEX]}+${XFADEFRAMEENTRIES[$XFADEFRAMEINDEX]}))
    # echo "I:$XFADEFRAMEINDEX Shot:$XFADESHOTINDEX ShotFramein:${XFADESHOTFRAMEINS[$XFADESHOTINDEX]} Xfadeentry:${XFADEFRAMEENTRIES[$XFADEFRAMEINDEX]} XfadeFramein:${XFADEFRAMEINS[$XFADEFRAMEINDEX]}"
    ((XFADEFRAMEINDEX=$XFADEFRAMEINDEX+1))
  done
  ((LastXFADEFRAMETOTAL=$XFADEFRAMETOTAL))
  ((XFADESHOTINDEX=$XFADESHOTINDEX+1))
done

for XFADEFRAMEN in "${!XFADEFRAMEINS[@]}"; do
  if [[ -z ${XFADEIMAGECHARACTERISTICS[$XFADEFRAMEN]} ]]; then
    XL1Status[$XFADEFRAMEN]="Not Defined"
    XMINPQ[$XFADEFRAMEN]=""
    XAVGPQ[$XFADEFRAMEN]=""
    XMAXPQ[$XFADEFRAMEN]=""
  elif [[ ${XFADEIMAGECHARACTERISTICS[$XFADEFRAMEN]} =~ ([0-9.]*),([0-9.]*),([0-9.]*) ]]; then
      XMINPQ[$XFADEFRAMEN]=${BASH_REMATCH[1]}
      XAVGPQ[$XFADEFRAMEN]=${BASH_REMATCH[2]}
      XMAXPQ[$XFADEFRAMEN]=${BASH_REMATCH[3]}
  fi
  if [[ -z ${XFADEL2TID1[$XFADEFRAMEN]} ]]; then
    XLE2TID1Status[$XFADEFRAMEN]="Not Defined"
    XL2TIDl1minoffset[$XFADEFRAMEN]=""
    XL2TIDl1avgoffset[$XFADEFRAMEN]=""
    XL2TIDl1maxoffset[$XFADEFRAMEN]=""
    XL2TIDlift[$XFADEFRAMEN]=""
    XL2TIDgain[$XFADEFRAMEN]=""
    XL2TIDgamma[$XFADEFRAMEN]=""
    XL2TIDsaturation[$XFADEFRAMEN]=""
    XL2TIDchroma[$XFADEFRAMEN]=""
    XL2TIDToneDetail[$XFADEFRAMEN]=""
  elif [[ ${XFADEL2TID1[$XFADEFRAMEN]} =~ ([0-9.\-]*),([0-9.\-]*),([0-9.\-]*),([0-9.\-]*),([0-9.\-]*),([0-9.\-]*),([0-9.\-]*),([0-9.\-]*),([0-9.\-]*) ]]; then
      XL2TIDl1minoffset[$XFADEFRAMEN]=${BASH_REMATCH[1]}
      XL2TIDl1avgoffset[$XFADEFRAMEN]=${BASH_REMATCH[2]}
      XL2TIDl1maxoffset[$XFADEFRAMEN]=${BASH_REMATCH[3]}
      XL2TIDlift[$XFADEFRAMEN]=${BASH_REMATCH[4]}
      XL2TIDgain[$XFADEFRAMEN]=${BASH_REMATCH[5]}
      XL2TIDgamma[$XFADEFRAMEN]=${BASH_REMATCH[6]}
      XL2TIDsaturation[$XFADEFRAMEN]=${BASH_REMATCH[7]}
      XL2TIDchroma[$XFADEFRAMEN]=${BASH_REMATCH[8]}
      XL2TIDToneDetail[$XFADEFRAMEN]=${BASH_REMATCH[9]}
  fi
  populateDoVIMetaList $XFADEFRAMEN "FrameOffset"
done

# ------------------------- Liste des défauts potentiel detecté -----------------------------------------------------------#
#Pcture source 
#Source target display: RGB chromacity pas reconnu comme REC 709 P3 BT2020. "Source declared target display's colorspace is not identified. It is not compliant with Dolby Vision color grading best practice workflow (Source R source G source B)
[ "$SOURCECOLORSPACE" != "REC709" ] && [ "$SOURCECOLORSPACE" != "P3" ] && [ "$SOURCECOLORSPACE" != "REC2020" ] && editReport "Unknown color primaries declaration\n Based on Dolby Vision's best practices guide, color space should be clearly identified as P3 or REC.2020" && SOURCECOLORSPACE="NA"
# Source target display: point blanc pas reconnu comme D65. "Source declared target display's colorspace is not identified as D65. It is not compliant with Dolby Vision color grading best practice workflow (Source R source G source B)
[ "$SOURCEWHITEPOINT" != "D65" ] && editReport "Picture source white point declaration is not clearly identified."
# Source target display: EOTF doit être égal à PQ
[ "$SOURCEEOTF" != "ST.2084" ] && editReport "Source Picture's declared EOTF ($SOURCEEOTF) is not compliant with Dolby Vision color grading and mastering's workflow specifications\nit should be pq(ST.2084)"
# [ "$SOURCEMINBRT" -gt 1 ] && echo "Source declared minimum brightness ($SOURCEMINBRT) value should be inferior to 1nit"
# [ "$SOURCEMAXBRT" != 10000 ] && echo "Source declared maximum brightness ($SOURCEMAXBRT) value should be 10000 nits"
[[ $((SOURCEMINBRT*10)) -gt 1 ]] && editReport "Source declared minimum brightness ($SOURCEMINBRT) value should be inferior to 0.1nit"
[ "$SOURCEMAXBRT" != 10000 ] && editReport "Source declared maximum brightness ($SOURCEMAXBRT) value should be 10000 nits"
[ "$SOURCEMAXBRT" -le "$SOURCEMINBRT" ] && editReport "non coherent min max theoritical picture source brightness values declared"
# Source Color Comp = RGB ChromaFormat = 444
[ "$SOURCECOLORCOMP" != "rgb" ] && editReport "prior to mastering, declared picture source's color components should be RGB (4:4:4)" 
[ "$SOURCECHROMAFORMAT" != "444" ] && editReport "prior to mastering, declared picture source's color components should be RGB (4:4:4)" 
# Source Sig Range = Computer 
[ "$SOURCESIGRANGE" != "computer" ] && editReport "prior to mastering, declared picture source's dynamic range should be Full (0-1023 or 0-4095)"
# Source bithDepth -gt 10
[ "$SOURCEBITDEPTH" -le 10 ] && editReport "picture source's per pixel bit depth needs to be greater than 10 bits (at least 12bits to preserve future 12bits mastering)."
#Level 6 Declaration:
[ "$OPTMAXFALL" = 0 ] && [ "$OPTMAXCLL" = "$OPTMAXFALL" ] && editReport "Max FLL and Max CLL values haven't been injected into Dolby Vision CM metadata as per level 6" 
[ "$OPTMAXFALL" != 0 ] && [ "$OPTMAXFALL" -ge "$OPTMAXCLL" ] && editReport "non-coherent Max FALL and Max CLL value declaration. MaxFALL cannot bu greater or equal to MaxCLL"
[[ $OPTMAXCLL -gt $MDMAXBRT ]] && editReport "Measured max CLL (maximum peak brightness ever measured on whole program for a given pixel cannot be greater than the declared maximum peak brightness value of the mastering display"
#
# Déclaration de la cible verouillé dolby vision Mastering Display
# Match signature SourceMasterDisplay
#Comparer l'espace couleur avec celui déclarer à l'image source
[[ "$SOURCECOLORSPACE" != "$MDCOLORSPACE" ]] && editReport "Source picture's declared color space ($SOURCECOLORSPACE) & declared mastering display's color space ($MDCOLORSPACE) should be identical"
#Comparer le WP à celui déclarer à l'image à l'image source
[[ "$SOURCEWHITEPOINT" != "$MDWHITEPOINT" ]] && editReport "Source picture's declared white point ($SOURCEWHITEPOINT) & declared mastering display's white point ($MDWHITEPOINT) should be identical"
#comparer l'EOTF à celui déclarer à l'image à l'image source
[[ "$SOURCEEOTF" != "$MDEOTF" ]] && editReport "Source picture's declared EOTF ($SOURCEEOTF) & declared mastering display's EOTF ($MDEOTF) should be identical"
#
#Déclaration de la cible d'affichage SDR verouillé
#TID1 doit être déclaré
[[ -z $TID1 ]] && editReport "Dolby Vision metadata doesn't contain TID1 (SDR target) declaration. This is a big issue." 
#Match signature TargetDisplay (based on TID)
[ "$TID1" != "100-nit, BT.709, BT.1886, Full" ] && editReport "Dolby Vision TID1 locked target's signature is not correct."
#
#--------------Analyse des plans-------------------------#
#Defaut cohérence plans avec declaration générique#
#MaxPQ -le Mastering Display max brightness: Lister les plans et Xframe si ce n'est pas le cas: CSV commentaire ISSUE MAX PQ overeach MD cap 
#Lift positif: lister tous les plans, retourner les intervalles images pour une séquence entière.
#Défaut cohérence L1 
#min<avg<max problème de mesure
#min=avg=max problème de mesure
#Défaut cohérence L2 TID 1
#L1offset(min,avg,max) !=0: vérifier
[ "$MDMAXNIT" == "100" ] && CAPMAXPQ="5081"
[ "$MDMAXNIT" == "1000" ] && CAPMAXPQ="7518"
# [ $MDMAXNIT = 2000 ] && CAPMAXPQ=
[ "$MDMAXNIT" == "4000" ] && CAPMAXPQ="9026"
editReport "\nMAXPQ OVERREACH (PER SHOT)"
for I in ${!MAXPQ[@]}
do
  MINPQPERSHOT=$(echo "scale=5;${MINPQ[I]}*10000" | bc)
  MINPQPERSHOT=${MINPQPERSHOT%.*}
  AVGPQPERSHOT=$(echo "scale=5;${AVGPQ[I]}*10000" | bc)
  AVGPQPERSHOT=${AVGPQPERSHOT%.*}
  MAXPQPERSHOT=$(echo "scale=5;${MAXPQ[I]}*10000" | bc)
  MAXPQPERSHOT=${MAXPQPERSHOT%.*}
  L2LIFTPERSHOT=$(echo "scale=5;${L2TIDlift[I]}*10000" | bc)
  L2LIFTPERSHOT=${L2LIFTPERSHOT%.*}
  [[ $MAXPQPERSHOT -gt $CAPMAXPQ ]] && editReport "Maximum PQ ${MAXPQ[I]} for shot#$I FrameIn# ${FRAMEINS[I]} is above maximum brightness of the declared Master Display ($MDMAXNIT-nits)" && SHOTISSUES[$I]="MaxPQ above MasteringDisplay cap." && populateDoVIMetaList $I "Shot"
  [[ $MINPQPERSHOT != "0" ]] && [[ $MINPQPERSHOT -lt $AVGPQPERSHOT ]] && [[ $AVGPQPERSHOT -lt $MAXPQPERSHOT ]] || editReport "for shot#$I FrameIn#. Non-coherent L1 min ($MINPQPERSHOT) avg ($AVGPQPERSHOT) max PQ ($MAXPQPERSHOT) values are set"&& SHOTISSUES[$I]="L1 value issue." && populateDoVIMetaList $I "Shot"
  [[ $MINPQPERSHOT == "0" ]] && [[ $MINPQPERSHOT == $AVGPQPERSHOT ]] && [[ $AVGPQPERSHOT == $MAXPQPERSHOT ]] && editReport "for shot#$I FrameIn#. L1 min avg max PQ values are set at 0. Possible commercial black. It needs to be checked" && SHOTISSUES[$I]="L1 values=0." && populateDoVIMetaList $I "Shot"
  [ "${LE2TID1Status[I]}" != "Not Defined" ] && [ "${L2TIDl1minoffset[I]}" != "0" ] || [ "${L2TIDl1avgoffset[I]}" != "0" ] || [ "${L2TIDl1maxoffset[I]}" != "0" ] && editReport "for shot#$I FrameIn#. L2 Trim (TID1) min avg max PQ offset values aren't set at 0. It needs to be checked" && SHOTISSUES[$I]="L2 Offset!=0." && populateDoVIMetaList $I "Shot"
  [ "${LE2TID1Status[I]}" == "Not Defined" ] && [ "${L2LIFTPERSHOT[I]}" -gt "0" ] && editReport "for shot#$I FrameIn#. LE Trim (TID1) Lift value is set positive."  && SHOTISSUES[$I]="L2 TID Lift>0." && populateDoVIMetaList $I "Shot"
done
editReport "\nMAXPQ OVERREACH (PER FRAMEOFFSET)"
for J in ${!XMAXPQ[@]}
do
  MAXPQPERXF=$(echo "scale=5;${XMAXPQ[J]}*10000" | bc)
  MAXPQPERXF=${MAXPQPERXF%.*}
  [[ $MAXPQPERXF -gt $CAPMAXPQ ]] && editReport "Maximum PQ of ${XMAXPQ[J]} for XFrameIn# ${XFADEFRAMEINS[J]} is above maximum brightness of the declared Master Display ($MDMAXNIT-nits)" && FRAMEISSUES[$J]="MaxPQ above MasteringDisplay cap." && populateDoVIMetaList $J "FrameOffset"
done
#[Shot Shot n+1] min=min n+1 & avg=avg n+1 & max=max n+1 : verifier pourquoi deux plans successifs ont exactement la même mesure L1.
#FrameOut[Shotn] = (FrameIn(Shotn+1])-1
#Défaut cohérence frame:
editReport "\nFRAME OUT CROSSREACH"
((lastSHOT=$CMSHOTS-1))
for K in ${!SHOTUUID[@]}
do
  if [ ${FRAMEOUTS[K]} -lt $lastSHOT ]; then
    [[ ${FRAMEOUTS[K]} -gt ${FRAMEINS[((K+1))]} ]] && editReport "Shot#$K's frame out (${FRAMEOUT[K]}) is reaching over the next shot's (#$K) frame in ${FRAMEINS[((K+1))]}." && SHOTISSUES[$K]="FrameOut/FrameIn overreach." && populateDoVIMetaList $K "Shot"
    [ ${FRAMEDURATIONS[K]} = "1" ] && editReport "Shot#$K's duration is one frame. Shot needs to be checked"
    [ "${MINPQ[K]}" == "${MINPQ((K+1))}" ] && [ "${AVGPQ[K]}" == "${AVGPQ((K+1))}" ] && [ "${MAXPQ[K]}" == "${MAXPQ((K+1))}" ] && editReport "Shot#$K's and its following frame share the same L1 values. Check for extraneous metadata shot or possible issues." && SHOTISSUES[$K]="L1 consecutives shots." && populateDoVIMetaList $K "Shot"
  fi
done




#

#[Shot Shot n+1] tonedetail != tonedetail n+1: tone detail ne doit pas changer entre différent plans
#l2TID[*] ToneDetailTID[1] = ToneDetail[@]: Tone detail ne doit pas changer entre les différentes cible d'affichage
#pour chaque plan si trim TID[*] existe trim TID[1] doit aussi exister
#pour chaque plan si trim TID[1] existe trim TID[*] doit aussi exister
#(n-1)TID1 (n)X (n+1)TID1 checker pourquoi subitement TID1 disparait (potentiellement image noir)
#
#Analyse Fade Edit Offset
#[n n+1] L1 minPQ ou avgPQ ou maxPQ ne peuvent égaux entre chaque Frame offset
# L1MaxPQ < MaxBrightness MD
# XFRAMEn =(XFRAMEn=1)-1
#-n L2[Shotn]; -n L2[Shotn[Xframe=@]]  
#
#
#

#-------------------------------------------------------------------------- Generate CSV based on $CSVARRAY ----------------------------------------------#
doViMetaListToCSV
createReport
## Restoring IFS
IFS="$OLDIFS"
unset OLDIFS
exit