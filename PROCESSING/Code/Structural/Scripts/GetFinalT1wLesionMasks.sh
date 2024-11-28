#!/bin/bash
#

# # GetFinalT1wLesionMasks.sh
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
#
#
# ## Description
#
# This script creates lesion masks for images after performing VBT and structural processing. 
# The resulting lesion masks can be used during registration to the preprocessed T1w_acpc_dc_restore brain image
# as performed in e.g. functional processing and is the basis for extracting 'lesion load' measures.
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

GetTempDir(){
# create temporary directory
    randID=$RANDOM
    export TempDir="${1}/temp-${randID}"
    mkdir ${TempDir}
}

InvertImage() {
    # invert binary lesion mask to use in cost function masking
	fslmaths ${1} -binv ${1%.nii.gz}_invert.nii.gz
}

source ${HCPPIPEDIR}/global/scripts/log.shlib  # Logging related functions
source ${HCPPIPEDIR}/global/scripts/opts.shlib # Command line option functions


#############################################
#                                           #
#            CHECK INPUT                    #
#                                           #
#############################################


# parse arguments
Path=`getopt1 "--path" $@`  # "$1" directory path containing all subjects
Subject=`getopt1 "--subject" $@`  # "$2" subject ID (e.g. sub-0001)
Session=`getopt1 "--session" $@`  # "$3" session ID (e.g. ses-01)

WD="${Path}/${Subject}/${Session}"

InputImage="${WD}/T1w/T1w_acpc_dc_restore.nii.gz"
RefImage="${WD}/anat/${Subject}*T1w.nii.gz"
RefMask="${WD}/lesion/T1w_lesion_mask_invert.nii.gz"

if [[ ! -f ${RefMask} ]]; then
    log_Msg "ERROR:    No >>/lesion/T1w_lesion_mask.nii.gz<< found. Did you run CreateCostMasks.sh?"
    exit 1
fi
#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################


log_Msg "START:   Creating lesion mask in final T1w space for ${Subject}."


GetTempDir "${WD}/lesion"

# register raw base image image to fully processed T1w_restore image using cost function masking

${FSLDIR}/bin/flirt -dof 6 \
    -interp spline \
    -in ${InputImage} \
    -ref ${RefImage} \
    -refweight ${RefMask} \
    -omat "${TempDir}/T1w2Raw.mat"

# inverse transformation
${FSLDIR}/bin/convert_xfm \
    "${TempDir}/T1w2Raw.mat" \
    -inverse \
    -omat "${TempDir}/Raw2Taw.mat"

# apply inverse transformation to T1w lesion mask
${FSLDIR}/bin/flirt -applyxfm -usesqform \
    -init "${TempDir}/Raw2Taw.mat" \
    -in "${WD}/lesion/T1w_lesion_mask.nii.gz" \
    -ref ${InputImage} \
    -out "${WD}/lesion/T1w_acpc_dc_restore_mask.nii.gz"

${FSLDIR}/bin/fslmaths \
    "${WD}/lesion/T1w_acpc_dc_restore_mask.nii.gz" \
    -bin \
    "${WD}/lesion/T1w_acpc_dc_restore_mask.nii.gz"

# invert created lesion mask
InvertImage "${WD}/lesion/T1w_acpc_dc_restore_mask"


# clean up of temporary files
if [[ -z ${NOCLEANUP} ]]; then
    log_Msg "UPDATE:    Removing temp directory."
    rm -r ${TempDir}
fi

log_Msg "FINISHED:    Creating lesion mask in final T1w space for ${Subject}."

