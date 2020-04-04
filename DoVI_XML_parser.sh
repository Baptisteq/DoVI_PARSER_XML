#!/bin/bash

# DoVI XML parser retourne dans un fichier texte des atoms predictifs d'un XML géneré par DaVinci 
# contenant toutes les informations metadatas Dolby Vision d'une timeline
# DoVI XML parser permet aussi de réaliser des test logiques sur le contenu de l'XML

INPUTXML=$1

XML=$(cat $INPUTXML)
# Revision history#
parseXML()
{
  local XPATH=$1
  
  echo "$XML" | xmllint --xpath "$XPATH" -
}

REVISIONCOUNT=$(parseXML "count(/DolbyLabsMDF/RevisionHistory/Revision)")
echo "$REVISIONCOUNT"
exit 0

#---- is this a revised version ? (number of <revision> node. if 1 it is the fisrt version ever generated
REVISIONCOUNT=$(echo "$XML" | xmllint --xpath "count(/DolbyLabsMDF/RevisionHistory/Revision)" $INPUTXML)
#---- if not, display last history by DATE/AUTHOR/SOFTWARE/SOFTWAREVERSION
MODIFIEDDATE=$(xmllint --xpath "/DolbyLabsMDF/RevisionHistory/Revision[last()]/DateTime" $INPUTXML | sed 's/<.*>\(.*\)<\/.*>/\1/')
AUTHOR=$(xmllint --xpath "/DolbyLabsMDF/RevisionHistory/Revision[last()]/Author" $INPUTXML | sed 's/<.*>\(.*\)<\/.*>/\1/')
SOFTWARE=$(xmllint --xpath "/DolbyLabsMDF/RevisionHistory/Revision[last()]/Software" $INPUTXML | sed 's/<.*>\(.*\)<\/.*>/\1/')
SOFTWAREV=$(xmllint --xpath "/DolbyLabsMDF/RevisionHistory/Revision[last()]/SoftwareVersion" $INPUTXML | sed 's/<.*>\(.*\)<\/.*>/\1/')
[ $REVISIONCOUNT = 1 ] && echo "This is the first version ever generated by this software: $AUTHOR -- $SOFTWARE -- $SOFTWAREV on $MODIFIEDDATE" 
#---- if it is, display all history by HISTORYNUMBER/DATE/AUTHOR/SOFTWARE/SOFTWAREVERSION
let I=1

if [ $REVISIONCOUNT > 1 ]; then
  echo "There are $REVISIONCOUNT version:"
  while [ $I -le $REVISIONCOUNT ]
    do
    MODIFIEDDATEnV=$(xmllint --xpath "/DolbyLabsMDF/RevisionHistory/Revision[$I]/DateTime" $INPUTXML | sed 's/<.*>\(.*\)<\/.*>/\1/')
    AUTHORnV=$(xmllint --xpath "/DolbyLabsMDF/RevisionHistory/Revision[$I]/Author" $INPUTXML | sed 's/<.*>\(.*\)<\/.*>/\1/')
    SOFTWAREnV=$(xmllint --xpath "/DolbyLabsMDF/RevisionHistory/Revision[$I]/Software" $INPUTXML | sed 's/<.*>\(.*\)<\/.*>/\1/')
    SOFTWAREVnV=$(xmllint --xpath "/DolbyLabsMDF/RevisionHistory/Revision[$I]/SoftwareVersion" $INPUTXML | sed 's/<.*>\(.*\)<\/.*>/\1/')
    echo "DoVI color mapping saved version $I generated on $MODIFIEDDATEnV by: $AUTHORnV -- $SOFTWAREnV -- $SOFTWAREVnV" 
    let I=I+1
  done
fi


#---- Outputs

# nom de la metadata Outputs/Output[name=.*]
METADATANAME=$(xmllint -xpath "/DolbyLabsMDF/Outputs/Output/@name" $INPUTXML | sed 's/"\(.*\)"$/\1/')
echo "DoVi CM metadata filename is: $METADATANAME"
# version de la metadata (2.0.5, 4.0.2 ...)
CMV=$(xmllint -xpath "/DolbyLabsMDF/@version" $INPUTXML | sed 's/.*="\([0-9.]*\)".*/\1/')
echo "Metadata version is CMv=$CMV"
# param cadre diffuser (à afficher et convertir en ligne*pix) Outputs/output/CanvasAspectRatio
CANVASASPECTRATIO=$(xmllint -xpath "/DolbyLabsMDF/Outputs/Output/CanvasAspectRatio" $INPUTXML | sed 's/.*>\(.*\)<.*/\1/')
echo "Canvas aspect ratio is: $CANVASASPECTRATIO"  
# param cadre util (à afficher et convertir en ligne*pix) Outputs/output/ImageAspectRatio
IMAGEASPECTRATIO=$(xmllint -xpath "/DolbyLabsMDF/Outputs/Output/ImageAspectRatio" $INPUTXML | sed 's/.*>\(.*\)<.*/\1/')
echo "Image aspect ratio is: $IMAGEASPECTRATIO" 
# Outputs/Output/video/rate   cadence image de la metadata(<n>f</n>p<d>s</d>)
METAFRAMERATEN=$(xmllint -xpath "/DolbyLabsMDF/Outputs/Output/Video/Track/Rate/n" $INPUTXML | sed 's/.*>\(.*\)<.*/\1/')
METAFRAMERATED=$(xmllint -xpath "/DolbyLabsMDF/Outputs/Output/Video/Track/Rate/d" $INPUTXML | sed 's/.*>\(.*\)<.*/\1/')
let METAFRAMERATE="METAFRAMERATEN / METAFRAMERATED"
echo "DoVi metadatas are set at $METAFRAMERATE fps"
#Outputs/Output/video/ColorEncoding/Primaries/Red /Green /Blue (arg: x,y) déclaration des extremes colorimétriques du VDM
SOURCECOLORSPACER=$(xmllint -xpath "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/Primaries/Red" $INPUTXML | sed 's/.*>\(.*\)<.*/\1/')
SOURCECOLORSPACEG=$(xmllint -xpath "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/Primaries/Green" $INPUTXML | sed 's/.*>\(.*\)<.*/\1/')
SOURCECOLORSPACEB=$(xmllint -xpath "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/Primaries/Blue" $INPUTXML | sed 's/.*>\(.*\)<.*/\1/')
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
echo "Picture source declared primaries chromaticities coordinates are:"
echo "R(x,y) $SOURCECOLORSPACER"
echo "G(x,y) $SOURCECOLORSPACEG"
echo "B(x,y) $SOURCECOLORSPACEB"
[ "$SOURCECOLORSPACER" == "0.64,0.33" ] && [ "$SOURCECOLORSPACEG" == "0.3,0.6" ] && [ "$SOURCECOLORSPACEB" == "0.15,0.06" ] && SOURCECOLORSPACE="REC709" && echo "Picture source is declared for a REC.709 master target display." 
[ "$SOURCECOLORSPACER" == "0.68,0.32" ] && [ "$SOURCECOLORSPACEG" == "0.265,0.69" ] && [ "$SOURCECOLORSPACEB" == "0.15,0.06" ] && SOURCECOLORSPACE="P3" && echo "Picture source is declared for a P3 master target display." 
[ "$SOURCECOLORSPACER" == "0.708,0.292" ] && [ "$SOURCECOLORSPACEG" == "0.17,0.797" ] && [ "$SOURCECOLORSPACEB" == "0.131,0.046" ] && SOURCECOLORSPACE="REC2020" && echo "Picture source is declared for a REC.2020 master target display."
[ "$SOURCECOLORSPACE" != "REC709" ] && [ "$SOURCECOLORSPACE" != "P3" ] && [ "$SOURCECOLORSPACE" != "REC2020" ] && echo "Unknown color primaries declaration" && SOURCECOLORSPACE="NA"

# à determiner par rapport au diagramme de chromaticité 1331 (P3 BT.2020 REC.709, Unknown)
#Outputs/Output/video/ColorEncoding/WhitePoint coordonée point blanc (arg:x,y) à pointer et determiner selon Chrom 1331 (D65,D60, DCI, unknown)
SOURCEWHITEPOINT=$(xmllint -xpath "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/WhitePoint" $INPUTXML | sed 's/.*>\(.*\)<.*/\1/')
SOURCEWHITEPOINTx=$(echo $SOURCEWHITEPOINT | sed 's/\([0-9\.]\),.*/\1/' | sed 's/^\(0,[0-9]*[1-9]\)0*$/\1/')
SOURCEWHITEPOINTy=$(echo $SOURCEWHITEPOINT | sed 's/.*,\([0-9\.]\)/\1/' | sed 's/^\(0,[0-9]*[1-9]\)0*$/\1/')
SOURCEWHITEPOINT="$SOURCEWHITEPOINTx"",""$SOURCEWHITEPOINTy"
echo "Picture source declared white point chromaticities coordinates are: $SOURCEWHITEPOINT"
[ "$SOURCEWHITEPOINT" == "0.3127,0.329" ] && echo "Picture source is declared for a D65 white point master target display."	
[ "$SOURCEWHITEPOINT" != "0.3127,0.329" ] && echo "Picture source white point declaration is not clearly identified."
#Outputs/Output/video/ColorEncoding/Encoding doit être identifié en "PQ" (Perceptual Quantizer)
SOURCEEOTF=$(xmllint -xpath "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/Encoding" $INPUTXML | sed 's/.*>\(.*\)<.*/\1/')
echo "Picture source declared EOTF is: $SOURCEEOTF"
[ "$SOURCEEOTF" != "pq" ] && echo "Picture source declared EOTF ($SOURCEEOTF) is not compliant with Dolby Vision CM workflow."
#Outputs/Output/video/ColorEncoding/<MinimumBrightness>0 (echelle absolue de la dynamique du luminance idéale dit être inférieur à 1nits)
#Outputs/Output/video/ColorEncoding/<PeakBrightness>10000 (echelle absolue de la dynamique du luminance idéale doit être égale à 10000nits)
SOURCEMINBRT=$(xmllint -xpath "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/MinimumBrightness" $INPUTXML | sed 's/.*>\(.*\)<.*/\1/')
SOURCEMAXBRT=$(xmllint -xpath "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/PeakBrightness" $INPUTXML | sed 's/.*>\(.*\)<.*/\1/')
echo "Picture source theoritical min,max brightness: $SOURCEMINBRT,$SOURCEMAXBRT nits"
[ "$SOURCEMINBRT" -gt 1 ] && echo "Source declared minimum brightness ($SOURCEMINBRT) value should be inferior to 1nit"
[ "$SOURCEMAXBRT" != 10000 ] && echo "Source declared maximum brightness ($SOURCEMAXBRT) value should be 10000 nits"
[ "$SOURCEMAXBRT" -le "$SOURCEMINBRT" ] && echo "non coherent min max theoritical picture source brightness values declared"

#Outputs/Output/video/ColorEncoding/<BitDepth>16 résolution de la dynamique du signal, doit coresspondre au fichier source
SOURCEBITDEPTH=$(xmllint -xpath "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/BitDepth" $INPUTXML | sed 's/.*>\(.*\)<.*/\1/')
echo "Source declared bit depth: $SOURCEBITDEPTH"
#Outputs/Output/video/ColorEncoding/<ColorSpace>rgb interpretation chromatique des composantes colorimétriques de la source image (doit correspondre au fichier source)
SOURCECOLORCOMP=$(xmllint -xpath "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/ColorSpace" $INPUTXML | sed 's/.*>\(.*\)<.*/\1/')
echo "Source declared color components: $SOURCECOLORCOMP"
#Outputs/Output/video/ColorEncoding/<ChromaFormat>444 quantification (si RGB doit être 444 & doit correspondre au fichier source dans tous les cas doit être 444)
SOURCECHROMAFORMAT=$(xmllint -xpath "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/ChromaFormat" $INPUTXML | sed 's/.*>\(.*\)<.*/\1/')
echo "Source declared chromat quantification is: $(echo "$SOURCECHROMAFORMAT" | sed 's/\([0-9]\)\([0-9]\)\([0-9]\)/\1:\2:\3/g')"
#Outputs/Output/video/ColorEncoding/<SignalRange>computer (paramètre indéfinit, doit correspondre au fichier source et dans l'idéal doit toujours être en full (0N à 1024B)
SOURCESIGRANGE=$(xmllint -xpath "/DolbyLabsMDF/Outputs/Output/Video/Track/ColorEncoding/SignalRange" $INPUTXML | sed 's/.*>\(.*\)<.*/\1/')
echo "Source declared signal range is: $SOURCESIGRANGE"
# level 6 optionnel, valeur MaxFALL (Frame Average Light Level) MaxCLL (Max Constant Light Level), simplement afficher, si 0 0  MaxFALL > MaxCLL & Max FALL MaxCLL < Mastering display PK brt
OPTMAXFALL=$(xmllint --xpath "/DolbyLabsMDF/Outputs/Output/Video/Track[@name]/Level6/MaxFALL" $INPUTXML | sed 's/.*>\(.*\)<.*/\1/')
OPTMAXCLL=$(xmllint --xpath "/DolbyLabsMDF/Outputs/Output/Video/Track[@name]/Level6/MaxCLL" $INPUTXML | sed 's/.*>\(.*\)<.*/\1/')
echo -e "Level6 = Optionnal Max FALL & Max CLL measurement for the whole program duration:\nMaxFall = $OPTMAXFALL\nMaxCLL = $OPTMAXCLL"
[ "$OPTMAXFALL" = 0 ] && [ "$OPTMAXCLL" = "$OPTMAXFALL" ] && echo "Max FLL and Max CLL values haven't been injected into Dolby Vision CM metadata as per level 6" 
[ "$OPTMAXFALL" != 0 ] && [ "$OPTMAXFALL" -ge "$OPTMAXCLL" ] && echo "non-coherent Max FALL and Max CLL value declaration. MaxFALL cannot bu greater or equal to MaxCLL"
# [ "$OPTMAXCLL" -gt "$MDMAXBRT" ] && echo "Measured max CLL (maximum peak brightness ever measured on whole program for a given pixel cannot be greater than the declared maximum peak brightness value of the mastering display"

#Declaration Mastering Display


#/DolbyLabsMDF/Outputs/Output/Video/Track[@name]/PluginNode/DolbyEDR/Characteristics level="0"/<MasteringDisplay level="0">/<Name>
# afficher et garder en mémoire les caracteristiques du mastering display: 
MD=$(xmllint -xpath "/DolbyLabsMDF/Outputs/Output/Video/Track[@name]/PluginNode/DolbyEDR/Characteristics [@level ='0']/MasteringDisplay [@level = '0']/Name" $INPUTXML | sed 's/.*>\(.*\)<.*/\1/')
echo "Mastering display signature: $MD"
MDMAXNIT=$(echo "$MD" | sed 's/\([0-9]*\)-nit.*$/\1/')
echo "Mastering display maximum brightness is: $MDMAXNIT nits."
MDCOLORSPACE=$(echo "$MD" | sed 's/.*-nit,\s\([^,]*\),.*$/\1/ ')
echo "Mastering display color space is: $MDCOLORSPACE."
MDWHITEPOINT=$(echo "$MD" | sed 's/.*-nit,\s[^,]*,\s\([^,]*\),.*$/\1/ ')
echo "Mastering display white point is: $MDWHITEPOINT."
MDEOTF=$(echo "$MD" | sed 's/.*-nit,\s[^,]*,\s[^,]*,\s\([^,]*\),.*$/\1/ ')
echo "Mastering display EOTF is: $MDEOTF."
MDSIGRANGE=$(echo "$MD" | sed 's/.*-nit,\s[^,]*,\s[^,]*,\s[^,]*,\s\([^,]*\)$/\1/')
echo "Mastering display signal range is: $MDSIGRANGE."
#Comparer l'espace couleur avec celui déclarer à l'image
#Comparer le WP à celui déclarer à l'image
#comparer l'EOTF à celui déclarer à l'image

#Déclaration Target Display

#Compter le nombre de target display. Si il y en a qu'un vérifier qu'il s'agit bien du TID=1 (100-nit, BT.709, BT.1886, Full) Metafier fait le reste.
#count(/DolbyLabsMDF/Outputs/Output/Video/Track[@name]/PluginNode/DolbyEDR/Characteristics level="0"/TargetDisplay level="0")



# afficher pour le fun les infos du target display 1
TID1=$(xmllint -xpath "/DolbyLabsMDF/Outputs/Output/Video/Track[@name]/PluginNode/DolbyEDR/Characteristics [@level ='0']/TargetDisplay [@level = '0']/Name" $INPUTXML | sed 's/.*>\(.*\)<.*/\1/')
echo "Target display number 1 (SDR target) signature: $TID1"
TID1MAXNIT=$(echo "$TID1" | sed 's/\([0-9]*\)-nit.*$/\1/')
echo "Target display number 1 (SDR target) maximum brightness is: $TID1MAXNIT nits."
TID1COLORSPACE=$(echo "$TID1" | sed 's/.*-nit,\s\([^,]*\),.*$/\1/ ')
echo "Target display number 1 (SDR target) color space is: $TID1COLORSPACE."
TID1EOTF=$(echo "$TID1" | sed 's/.*-nit,\s[^,]*,\s\([^,]*\),.*$/\1/ ')
echo "Target display number 1 (SDR target) EOTF is: $TID1EOTF."
TID1SIGRANGE=$(echo "$TID1" | sed 's/.*-nit,\s[^,]*,\s[^,]*,\s\([^,]*\)$/\1/')
echo "Target display number 1 (SDR target) signal range is: $TID1SIGRANGE."

TID1WHITEPOINT=$(xmllint -xpath "/DolbyLabsMDF/Outputs/Output/Video/Track[@name]/PluginNode/DolbyEDR/Characteristics [@level ='0']/TargetDisplay [@level = '0']/WhitePoint" $INPUTXML | sed 's/.*>\(.*\)<.*/\1/' )
TID1WHITEPOINTx=$(echo $TID1WHITEPOINT | sed 's/\([0-9\.]\),.*/\1/' | sed 's/^\(0,[0-9]*[1-9]\)0*$/\1/')
TID1WHITEPOINTy=$(echo $TID1WHITEPOINT | sed 's/.*,\([0-9\.]\)/\1/' | sed 's/^\(0,[0-9]*[1-9]\)0*$/\1/')
TID1WHITEPOINT="$TID1WHITEPOINTx"",""$TID1WHITEPOINTy"
echo "Target display number 1 (SDR target) declared white point chromaticities coordinates are: $TID1WHITEPOINT"
[ "$TID1WHITEPOINT" == "0.3127,0.329" ] && echo "Target display number 1 (SDR target) is declared for a D65 white point master target display."	
[ "$TID1WHITEPOINT" != "0.3127,0.329" ] && echo "Target display number 1 (SDR target) white point declaration is not clearly identified."


#----- SHOTS METADATA DOLBY VISION CMv2.0.5 METADATA
# METADATA SHOT COUNTS
CMSHOTN=$(xmllint --xpath "count(//Shot)" $INPUTXML)
echo "Number of metadatashot: $CMSHOTN".
# CSV print of all shots (FRAMESTART;FRAME DURATION;FRAMEEND;TCIN;TCOUT;MinPQ;AvgPQ;MaxPQ;TID;...WIP
FRAMEINS=($(xmllint -xpath "//Shot/Record/In/text()" $INPUTXML))
FRAMEDURATIONS=($(xmllint -xpath "//Shot/Record/Duration/text()" $INPUTXML))

for INDEX in "${!FRAMEINS[@]}"; do
  ((FRAMEOUTS[$INDEX]=${FRAMEINS[$INDEX]}+${FRAMEDURATIONS[$INDEX]}-1))
#  echo "in:${FRAMEINS[$INDEX]} out:${FRAMEOUTS[$INDEX]} duration:${FRAMEDURATIONS[$INDEX]}"
  
  printf "in: %d\tout: %d\tduration: %d\n" "${FRAMEINS[$INDEX]}" "${FRAMEOUTS[$INDEX]}" "${FRAMEDURATIONS[$INDEX]}"
done



# IMAGECHARACTERISTICS=$(xmllint -xpath "//Shot/PluginNode/DolbyEDR [@level="1"]/ImageCharacter/text()" $INPUTXML)

  # PQCHARACTERISTICS=$(xmllint --xpath "//Shot[$J]/PluginNode/DolbyEDR [@level="1"]/ImageCharacter" $INPUTXML | sed 's/<.*>\(.*\)<\/.*>/\1/')
# MINPQ=$(echo $PQCHARACTERISTICS | sed 's/^\([0-9.]*\),[0-9.]*,[0-9.]*$/\1/')
# AVGPQ=$(echo $PQCHARACTERISTICS | sed 's/^[0-9.]*,\([0-9.]*\),[0-9.]*$/\1/')
# MAXPQ=$(echo $PQCHARACTERISTICS | sed 's/^[0-9.]*,[0-9.]*,\([0-9.]*\)$/\1/')



# METADATA SHOT COUNTS FOR minPQ=0




 






