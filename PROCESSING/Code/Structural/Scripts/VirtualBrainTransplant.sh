#!/bin/bash
#
# # VirtualBrainTransplant.sh
#
#
# * Brain Simulation Section
# * Charité Berlin Universitätsmedizin
# * Berlin Institute of Health
#
# ## Author(s)
#
# * Bey, Patrik, Charité Universitätsmedizin Berlin, Berlin Institute of Health
# 
#
# * last update: 2022.11.01
#
#
#
# ## Description
#
# This script creates a virtual brain transplant (VBT) of lesioned brains 
# following (Solodkin et al. 2010). 
# 
# * The following steps are performed:
# * 
# * 1. Mirroring of lesioned input image
# * 2. Mirroring of lesion mask
# * 3. Registration to mirror image using cost function masking
# * 5. Midline alignment (images & mask) via half transform to mirror image
# * 6. smoothing of lesion mask 
# * 7. multiplication of mirror image with smoothed lesion mask
# * 8. mutliplication of input image with inverse smoothed lesion mask
# * 9. Concatenation of both results
#
#
#
# References:
#
# * 1. Solodkin et al. 2010 | DOI:10.4449/aib.v148i3.1221
# * 2. Nachev et al. 2008 | DOI:10.1016/j.neuroimage.2007.10.002


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

GetTempDir(){
# create temporary directory
    randID=$RANDOM
    export TempDir="${1}/temp-${randID}"
    mkdir ${TempDir}
}

InvertImage() {
	fslmaths ${1} -bin ${1}
	fslmaths ${1} -mul -1 -add 1 -thr 0.5 -bin ${1}"_invert"
	fslmaths ${1}"_invert" -bin ${1}"_invert"
}



source ${HCPPIPEDIR}/global/scripts/log.shlib  # Logging related functions
source ${HCPPIPEDIR}/global/scripts/opts.shlib # Command line option functions




#############################################
#                                           #
#            CHECK INPUT                    #
#                                           #
#############################################


# parse arguments
Path=`getopt1 "--workingdir" $@`  # "$1" working directory 
Input=`getopt1 "--in" $@`  # "$2"   input images to perform VBT on
Subject=`getopt1 "--subject" $@`  # "$3"   Subject ID
Session=`getopt1 "--session" $@`  # "$4"   Session ID
Output=`getopt1 "--out" $@`  # "$5" output directory
CostMask=`getopt1 "--costmask" $@` #"$6" provided lesion mask
# SmoothingFactor=`getopt1 "--smoothing" $@` #"$7" smoothing value for lesion border kernel

if [[ -z ${SmoothingFactor} ]]; then
    export SmoothingFactor="2"
    log_Msg "UPDATE:    Using default smoothing parameter sigma=${SmoothingFactor} during virtual brain transplant."
fi


#############################################s
#                                           #
#            DO COMPUTATIONS                #
#                                           #
#############################################

log_Msg "START:    performing virtual brain transplant for ${Subject}"

# create temporary directory for computations
GetTempDir "${Path}/${Subject}/${Session}"

cp ${Input} "${TempDir}/Orig.nii.gz"
cp ${CostMask} "${TempDir}/Mask.nii.gz"

InvertImage "${TempDir}/Mask"

#------------1 mirror input image-----------#
${FSLDIR}/bin/fslswapdim \
    "${TempDir}/Orig.nii.gz" \
    -x y z \
    "${TempDir}/Mirror.nii.gz"

#------------2 mirror input mask------------#
${FSLDIR}/bin/fslswapdim \
    "${TempDir}/Mask.nii.gz" \
    -x y z \
    "${TempDir}/MaskMirror.nii.gz"

InvertImage "${TempDir}/MaskMirror"

#------------3 register to mirror-----------#
log_Msg "UPDATE:    Registering to mirror image for midline alignment."
${FSLDIR}/bin/flirt -dof 6 -interp 'nearestneighbour' \
    -in "${TempDir}/Orig.nii.gz" \
    -inweight "${TempDir}/Mask_invert.nii.gz" \
    -ref "${TempDir}/Mirror.nii.gz" \
    -omat "${TempDir}/orig2mirror.mat" \
    -out "${TempDir}/orig2mirror.nii.gz"

# -refweight "${TempDir}/MaskMirror_invert.nii.gz" \

#------------4 get half transform-----------#
log_Msg "UPDATE:    creating half transformation to midline"
${FSLDIR}/bin/midtrans \
    --template="${TempDir}/Orig.nii.gz" \
    --separate="${TempDir}/MidtransO2H" \
    --out="${TempDir}/mir2half.txt" \
    "${TempDir}/orig2mirror.mat" \
    $FSLDIR/etc/flirtsch/ident.mat

#------------5 midline alignment-----------#
log_Msg "UPDATE:    Applying half transform to midline to input image / mirror image / input mask"
${FSLDIR}/bin/flirt -applyxfm \
    -init "${TempDir}/MidtransO2H0001.mat" \
    -in "${TempDir}/Orig.nii.gz" \
    -ref "${TempDir}/Orig.nii.gz" \
    -out "${TempDir}/OrigMidline.nii.gz"

${FSLDIR}/bin/flirt -applyxfm \
    -init "${TempDir}/MidtransO2H0002.mat" \
    -in "${TempDir}/Mirror.nii.gz" \
    -ref "${TempDir}/Mirror.nii.gz" \
    -out "${TempDir}/MirrorMidline.nii.gz"

${FSLDIR}/bin/flirt -applyxfm \
    -init "${TempDir}/MidtransO2H0001.mat" \
    -in "${TempDir}/Mask.nii.gz" \
    -ref "${TempDir}/Mask.nii.gz" \
    -out "${TempDir}/MaskMidline.nii.gz"


###########
#
#
# check path from here on out ($Session)
#
#
############


#------------6 create transplant-----------#
# providing input to python script

python3 ${LEAPP_STRUCTDIR}/Scripts/CreateTransplant.py \
    --wd=${TempDir} \
    --smoothing=${SmoothingFactor}


# if [[ -z ${SmoothingFactor} ]]; then
#     SmoothingFactor="2"
# fi
# export Smoothing=${SmoothingFactor}
# export tempdir=${TempDir}
# export DATE=$(date)

# python3 ${LEAPP_STRUCTDIR}/Scripts/CreateTransplant.py

# rewarping transplanted image back to original space
log_Msg "UPDATE:    Applying half transform from midline to input space."


${FSLDIR}/bin/convert_xfm \
    "${TempDir}/MidtransO2H0001.mat" \
    -inverse \
    -omat "${TempDir}/Mid2Orig.mat"

${FSLDIR}/bin/flirt -applyxfm \
    -init "${TempDir}/Mid2Orig.mat" \
    -in "${TempDir}/Transplant.nii.gz" \
    -ref "${TempDir}/Orig.nii.gz" \
    -out "${TempDir}/TransplantOrig.nii.gz"

${FSLDIR}/bin/flirt -applyxfm \
    -init "${TempDir}/Mid2Orig.mat" \
    -in "${TempDir}/VBTMaskInverse.nii.gz" \
    -ref "${TempDir}/Orig.nii.gz" \
    -out "${TempDir}/VBTMaskInverseOrig.nii.gz"

${FSLDIR}/bin/fslmaths \
    "${TempDir}/Orig.nii.gz" \
    -mul \
    "${TempDir}/VBTMaskInverseOrig.nii.gz" \
    "${TempDir}/HealthySignal.nii.gz"

${FSLDIR}/bin/fslmaths \
    "${TempDir}/HealthySignal.nii.gz" \
    -add \
    "${TempDir}/TransplantOrig.nii.gz" \
    "${TempDir}/VBT.nii.gz" \
    -odt 'int'

cp "${TempDir}/VBT.nii.gz" \
    "${Output}.nii.gz"

if [[ -z ${NOCLEANUP} ]]; then
    rm -r ${TempDir}
fi


log_Msg "FINISHED:    performing virtual brain transplant for ${Subject}"
