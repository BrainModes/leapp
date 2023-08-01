#!/bin/bash
#
# # DistortionCorrection_NEW.sh
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
# * last update: 2022.12.10
#



# ## Description
#
# This script performs an approximation of EPI susceptibility distortion correction of DWI images using 
# registration to T1w space. 
#
# * processing steps within this script:
# * 1. Extraction of first B0 image of denoised DWI volumes
# * 
# * 2. Registration of FLAIR space to DWI to create Lesion mask in DWI space
# * 3. Registration of T1w image to DWI space using cost function masking if lesion present
# * 4. Inversion of transformation matrix to: DWI to T1w space
# * 5. application of inverted transformation matrix on full DWI input data.
# REQUIREMENTS: 
# 1. LeAPP structural processing
# 2. Denoising.sh
# 3. BiasCorrection.sh
# 
#



#############################################
#                                           #
#            HELPER FUNCTIONS               #
#                                           #
#############################################

# parsing functions

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

# inverting mask image to use in cost function masking
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
    ${FSLDIR}/bin/flirt -dof 12 \
    -cost normmi \
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
        -out "${TempDir}/${4}_lesion_mask"
}

Resample() {
    # resampling input image to match reference dimensions
    # ${1} input image to resample
    # ${2} reference image for input dimensions
    # ${3} optional: output image
    if [ -z ${3} ]; then
        export _outimage="${1%.nii.gz}_resample.nii.gz"
    else
        _outimage=${3}
    fi
    ${FSLDIR}/bin/flirt \
        -in ${1} \
        -ref ${2} \
        -out ${_outimage} \
        -applyxfm \
        -usesqform

    ${FSLDIR}/bin/fslmaths \
    ${_outimage} \
    ${_outimage} \
    -odt int
}

#############################################
#                                           #
#            CHECK INPUT                    #
#                                           #
#############################################


Path=`getopt1 "--path" $@`  # "$1" directory path containing all subjects
Subject=`getopt1 "--sub" $@`  # "$2" subject ID (e.g. 0001)
Session=`getopt1 "--session" $@`  # "$3"

# set local variables
# WD="${Path}/${Subject}"
WD="${Path}/${Subject}/${Session}/dwi_preprocessed"

# check previous structural processing steps
if [[ ! -d "${Path}/${Subject}/${Session}/T1w" ]]; then
    log_Msg "ERROR:    No T1w folder of structural processing steps. Please run structural processing before using DWIpreproc"
    exit 1
fi

if [[ -d "${Path}/${Subject}/${Session}/lesion" ]]; then
    log_Msg "UPDATE:    Lesion folder found. Including lesion mask in distrotion correction."
    Lesion="True"
fi

# create temporary directory
randID=$RANDOM
TempDir="${WD}/temp-${randID}"
mkdir ${TempDir}


InputImage=${WD}/${Subject}"_DWI_preprocessed"


#############################################
#                                           #
#            DO COMPUTATIONS                #
#                                           #
#############################################


# extract B0 image
log_Msg "UPDATE:    preparing DWI image for registration."

${MRTRIXDIR}/bin/dwiextract -force \
    "${InputImage}.mif" - -bzero | mrmath - mean \
    "${TempDir}/B0Reference.mif" -axis 3 -force


# converting to FSL readable nifti format

${MRTRIXDIR}/bin/mrconvert -force \
    "${TempDir}/B0Reference.mif" \
    "${TempDir}/B0Reference.nii.gz"

# perform brain extraction

# DWI for time series masking
${MRTRIXDIR}/bin/dwi2mask -force \
    "${InputImage}.mif" \
    "${WD}/${Subject}_DWI_brainmask.nii.gz"

${FSLDIR}/bin/fslmaths "${TempDir}/B0Reference.nii.gz" \
    -mas "${WD}/${Subject}_DWI_brainmask.nii.gz" \
    "${TempDir}/DWIBrainMasked.nii.gz"

# check if lesion mask for patient population
if [[ ! -z ${Lesion} ]]; then

    log_Msg "UPDATE:    Running T1w to DWI registration with cost function masking."

    log_Msg "UPDATE:    Creating DWI space lesion mask following CreateCostMasks.sh approach."
    RegisterMask \
        "${Path}/${Subject}/${Session}/lesion/BaseImage" \
        "${TempDir}/DWIBrainMasked.nii.gz" \
        "${Path}/${Subject}/${Session}/lesion/BaseImageMask" \
        "DWI"
    
    # invert lesion mask and binarize
    InvertImage "${TempDir}/DWI_lesion_mask"

    cp "${TempDir}/DWI_lesion_mask.nii.gz" \
    "${Path}/${Subject}/${Session}/lesion/DWI_lesion_mask.nii.gz"
    
    cp "${TempDir}/DWI_lesion_mask_invert.nii.gz" \
    "${Path}/${Subject}/${Session}/lesion/DWI_lesion_mask_invert.nii.gz"

    # register T1w to DWI image with cost function masking
    ${FSLDIR}/bin/flirt -dof 12 \
        -cost normmi \
        -interp spline \
        -ref "${Path}/${Subject}/${Session}/T1w/T1w_acpc_dc_restore_brain.nii.gz" \
        -in  "${TempDir}/DWIBrainMasked.nii.gz" \
        -inweight "${Path}/${Subject}/${Session}/lesion/DWI_lesion_mask_invert.nii.gz" \
        -omat "${TempDir}/DWI2T1.mat" \
        -o "${TempDir}/DWI2T1.nii.gz"
    
    log_Msg "UPDATE:    Running T1w to DWI registration."
    # register T1w to DWI image with cost function masking
    ${FSLDIR}/bin/flirt -dof 6 \
        -cost normmi \
        -interp spline \
        -in "${TempDir}/DWIBrainMasked.nii.gz" \
        -ref "${Path}/${Subject}/${Session}/T1w/T1w_acpc_dc_restore_brain.nii.gz" \
        -omat "${TempDir}/DWI2T1.mat" \
        -o "${TempDir}/DWI2T1.nii.gz"
fi

# ${FSLDIR}/bin/convert_xfm \
#         "${TempDir}/DWI2T1.mat"\
#         -inverse \
#         -omat "${WD}/T1w2DWI.mat"


# log_Msg "UPDATE:    Applying T1w to DWI transformation to parcellation and T1w image for 5 tissue typ separation."
# # # apply registration to DWI image
# ${FSLDIR}/bin/flirt -applyxfm -usesqform \
#     -init "${WD}/T1w2DWI.mat" \
#     -in "${Path}/${Subject}/T1w/T1w_acpc_dc_restore_brain.nii.gz" \
#     -ref "${TempDir}/DWIBrainMasked.nii.gz" \
#     -out "${Path}/${Subject}/T1w/T1w_acpc_dc_restore_brain_DWI.nii.gz"

# ${FSLDIR}/bin/flirt -applyxfm -usesqform \
#     -init "${WD}/T1w2DWI.mat" \
#     -interp "nearestneighbour" \
#     -in "${Path}/${Subject}/parcellation/${Subject}_HCPMMP1_resample.nii.gz" \
#     -ref "${TempDir}/DWIBrainMasked.nii.gz" \
#     -out "${Path}/${Subject}/parcellation/${Subject}_HCPMMP1_DWI.nii.gz" 



log_Msg "UPDATE:    Masking DWI image volumes."

${MRTRIXDIR}/bin/mrconvert -force -quiet \
    "${InputImage}.mif" \
    "${TempDir}/DWI_orig.nii.gz"  \
    -export_grad_fsl ${TempDir}"/bvec.bvec" ${TempDir}"/bval.bval"

${FSLDIR}/bin/flirt -applyxfm -usesqform \
    -init "${TempDir}/DWI2T1.mat" \
    -ref "${Path}/${Subject}/${Session}/T1w/T1w_acpc_dc_restore_brain.nii.gz" \
    -in "${TempDir}/DWI_orig.nii.gz" \
    -out "${TempDir}/DWI_T1w.nii.gz"


${FSLDIR}/bin/fslmaths "${TempDir}/DWI_T1w.nii.gz" \
    -mas "${Path}/${Subject}/${Session}/T1w/brainmask_fs.nii.gz" \
    "${TempDir}/DWI_T1w_masked.nii.gz"

${MRTRIXDIR}/bin/mrconvert -force -quiet -fslgrad \
    "${TempDir}/bvec.bvec" "${TempDir}/bval.bval" \
    "${TempDir}/DWI_T1w_masked.nii.gz" \
    "${InputImage}_brain.mif" 


# DWI for time series masking

if [ -z ${NOCLEANUP} ]; then
    log_Msg "removing temporary directory."
    rm -r ${TempDir}
    rm ${InputImage}".mif"
fi     
