#!/bin/bash
#

# # CreateCostMasks.sh
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
# * last update: 2022.11.01
#
# Script for creation of binary lesion masks to use in cost function masking 
# and virtual brain transplantation (VBT) in the LeAPP framework.



#############################################
#                                           #
#            HELPER FUNCITONS               #
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

source ${HCPPIPEDIR}/global/scripts/log.shlib  # Logging related functions
source ${HCPPIPEDIR}/global/scripts/opts.shlib # Command line option functions


# function to invert mask image to use in cost function masking
InvertImage() {
	fslmaths ${1} -bin ${1}
	fslmaths ${1} -mul -1 -add 1 -thr 0.5 -bin ${1}_invert
	fslmaths ${1}_invert -bin ${1}_invert
}



# function to register mask using base images
RegisterMask() {
# ${1} = Reference image
# ${2} = image in target space
# ${3} = provided lesion mask in reference space
# ${4} = Name of target space
# register reference image to target image to obtain transformation matrix
# using cost function masking in reference space
    ${FSLDIR}/bin/flirt \
    -in ${2} \
    -refweight ${3}"_invert.nii.gz" \
    -ref ${1} \
    -omat "${TempDir}/${4}2ref.mat"
# invert transformation matrix
    ${FSLDIR}/bin/convert_xfm \
        "${TempDir}/${4}2ref.mat"  \
        -inverse \
        -omat "${TempDir}/ref2${4}.mat" 
# apply transformation matrix to lesion mask to create lesion mask in target space
    ${FSLDIR}/bin/flirt -applyxfm -usesqform \
        -init "${TempDir}/ref2${4}.mat"  \
        -in ${3} \
        -ref ${2} \
        -out "${WD}/lesion/${4}_lesion_mask"
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

GetTempDir(){
# create temporary directory
    randID=$RANDOM
    export TempDir="${1}/temp-${randID}"
    mkdir ${TempDir}
}

#############################################
#                                           #
#            CHECK INPUT                    #
#                                           #
#############################################


Path=`getopt1 "--studyfolder" $@`  # "$1" directory containing all subjects
Subject=`getopt1 "--subject" $@`  # "$2" Subject ID
Session=`getopt1 "--session" $@`  # "$2" Subject ID
T1wInput=`getopt1 "--t1winput" $@`  # "$3" T1w input image to use
T2wInput=`getopt1 "--t2winput" $@` # "$4" T2w input image to use
MNIInput=`getopt1 "--templateinput" $@` # "$5" MNI template to use
MNI2mmInput=`getopt1 "--templateinput2mm" $@` # "$6" MNI 2mm template to use
FLAIRInput=`getopt1 "--flairinput" $@` # "$7" FLAIR input image to use
MaskSpace=`getopt1 "--maskspace" $@` # "$8" Space of Cost mask base (T1w,T2w,MNI,FLAIR)

# define local variables
WD=${Path}/${Subject}/${Session}
CostMask="${WD}/anat/${Subject}_${MaskSpace}_lesion_mask.nii.gz"
if [[ ! -f ${CostMask} ]]; then
    log_Msg "ERROR:    No lesion mask >>${CostMask}<< found. "
    exit 1
fi

Spaces="T1w T2w MNI MNI2mm FLAIR"

# creating relevant folder structure
if [[ ! -d ${WD}"/lesion" ]]; then
    log_Msg "UPDATE:    Creating lesion directory ${WD}/lesion."
    mkdir ${WD}"/lesion"
fi

# create basis space cost mask
cp ${CostMask} ${WD}"/lesion/BaseImageMask.nii.gz"

# create temporary directory
GetTempDir "${WD}/lesion"


#############################################
#                                           #
#            DO COMPUTATIONS                #
#                                           #
#############################################

log_Msg "START:    Creating lesion masks for ${Subject}."

#-------------get hdr info------------------#
GetDimInfo ${CostMask}
MaskDim=${ImgDim}

#-----------resample base image-------------#

for s in ${Spaces}; do
    if [[ ${MaskSpace} = ${s} ]]; then
        input="${s}Input"
        GetDimInfo ${!input}
        if [[ ${MaskDim} != ${ImgDim} ]]; then
            log_Msg "UPDATE:    resampling base lesion mask to fit anatomical ${s} image."
            cp ${WD}"/lesion/BaseImageMask.nii.gz" \
                ${WD}"/lesion/BaseImageMaskInitial.nii.gz"
            ${MRTRIXDIR}/bin/mrtransform -force -quiet \
                -template ${!input} \
                -interp 'nearest' \
                ${WD}"/lesion/BaseImageMaskInitial.nii.gz" \
                ${WD}"/lesion/BaseImageMask.nii.gz"
            # ${ANTSDIR}/ResampleImage 3 \
            #     ${WD}"/lesion/BaseImageMask.nii.gz"  \
            #     "${TempDir}/BaseImageMaskResample.nii.gz" \
            #     ${ImgDim} 1 1
            
        fi
        cp ${!input} \
            "${WD}/lesion/BaseImage.nii.gz"
    fi
done

#------------create inverse masks------------#

InvertImage ${WD}"/lesion/BaseImageMask"

#------------create lesion masks------------#

for s in ${Spaces}; do 
    idx="${s}Input"
    input=$( echo ${!idx} | cut -d' ' -f1 )
    if [[ -f ${input} ]]; then
        log_Msg "UPDATE:    Creating lesion mask in ${s} space."
        RegisterMask \
            "${WD}/lesion/BaseImage" \
            ${input} \
            ${WD}"/lesion/BaseImageMask" \
            ${s}
        InvertImage "${WD}/lesion/${s}_lesion_mask"
    else
    log_Msg "WARNING:    no ${s} input image found."
    fi 
done


# clean up of temporary files
if [[ -z ${NOCLEANUP} ]]; then
    log_Msg "UPDATE:    Removing temp directory."
    rm -r ${TempDir}
fi

log_Msg "FINISHED:    Creating lesion masks for ${Subject}."