#!/bin/bash
#

# # RunVBT.sh
#
#
# * Brain Simulation Section
# * Charité Berlin Universitätsmedizin
# * Berlin Institute of Health
#
# ## Author(s)
# * Bey, Patrik, Charité Universitätsmedizin Berlin, Berlin Institute of Health
# 
#
# * last update: 2022.10.28
#
#
#
# ## Description
#
# This script performs  virtual brain transplant (VBT) as
# described in "Lesion Aware automated processing pipeline", Bey et al. (in prep.)
# for a given input image and corresponding lesion mask.
# 
#



#############################################
#                                           #
#            HELPER FUNCTIONS               #
#                                           #
#############################################


# function for parsing options
getopt1() {
    sopt="$1"
    shift 1
    for fn in $@ ; do
	if [ `echo $fn | grep -- "^${sopt}=" | wc -w` -gt 0 ] ; then
	    echo $fn | sed "s/^${sopt}=//"
	    return 0
	fi
    done
}

GetDimInfo () {
# get image dimension from input header
# and return as $ImgDim
    _dim1="$( fslval ${1} dim1)"
    len1="$((${#_dim1}-1))"
    _dim2="$( fslval ${1} dim2)"
    len2="$((${#_dim2}-1))"
    _dim3="$( fslval ${1} dim3)"
    len3="$((${#_dim3}-1))"
    export ImgDim=${_dim1:0:${len1}}"x"${_dim2:0:${len2}}"x"${_dim3:0:${len3}}
}

source ${HCPPIPEDIR}/global/scripts/log.shlib  # Logging related functions
source ${HCPPIPEDIR}/global/scripts/opts.shlib # Command line option functions



#############################################
#                                           #
#            CHECK INPUT                    #
#                                           #
#############################################

# parse arguments
Path=`getopt1 "--path" $@`  # "$1" working directory 
Subject=`getopt1 "--subject" $@`  # "$2"   Subject ID
Session=`getopt1 "--session" $@`  # "$3"   Session ID
Image=`getopt1 "--image" $@`  # "$4" image to perform VBT on
CostMask=`getopt1 "--mask" $@` #"$5" lesion mask of input image
NOCLEANUP=`getopt1 "--nocleanup" $@` #"$5" boolean to remove temp files


if [[ -z ${Image} ]]; then
    log_Msg "ERROR:   no input >>Image<< variable defined."
    exit 1
fi

if [[ -z ${CostMask} ]]; then
    log_Msg "ERROR:    no input >>mask<< variable defined."
    exit 1
fi

CostMask=${Path}/${Subject}/${Session}/${CostMask}
Image=${Path}/${Subject}/${Session}/${Image}

# Define variables
OutDir="$( dirname ${Image})"
MaskNameResample="${CostMask%.nii.gz}_resample.nii.gz"


#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################

# get dimension of Mask image
GetDimInfo ${CostMask}
MaskDim=${ImgDim}

# get dimension of input image to transplant
GetDimInfo ${Image}


# resample mask image to fit input image
if [[ ${MaskDim} != ${ImgDim} ]]; then
    log_Msg "UPDATE:    resampling lesion mask to fit ${Image}."
    ${MRTRIXDIR}/bin/mrtransform -force -quiet \
                -template ${Image} \
                -interp 'nearest' \
                ${CostMask} \
                ${MaskNameResample}
    CostMaskVBT=${MaskNameResample}
else
    CostMaskVBT=${CostMask}
fi


# run vbt
${RUN} ${LEAPP_STRUCTDIR}/Scripts/VirtualBrainTransplant.sh \
    --workingdir=${Path} \
    --subject=${Subject} \
    --session=${Session} \
    --in=${Image} \
    --costmask=${CostMaskVBT} \
    --out="${OutDir}/TransplantedImage" \
    --nocleanup=${NOCLEANUP}
