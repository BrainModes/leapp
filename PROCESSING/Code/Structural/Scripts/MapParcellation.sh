#!/bin/bash
#

# # MapParcellation.sh
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
# * last update: 2022.10.25
#
#
# script for the mapping of the HCP-MM1 (Glasser et al. 2016) brain parcellation to the 
# freesurfer created subject surface.
# This script is following a script by Hugo Cesar Baggio & Alexandra Abos at CJNeuroLab (https://cjneurolab.org/2016/11/22/hcp-mmp1-0-volumetric-nifti-masks-in-native-structural-space/) using the previously published 
# HCP-MMP1 based annotation labels (Mills (2016),https://figshare.com/articles/dataset/HCP-MMP1_0_projected_on_fsaverage/3498446)
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

source ${HCPPIPEDIR}/global/scripts/log.shlib  # Logging related functions
source ${HCPPIPEDIR}/global/scripts/opts.shlib # Command line option functions


GetTempDir(){
# create temporary directory
    randID=$RANDOM
    export TempDir="${1}/temp-${randID}"
    mkdir ${TempDir}
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
        -usesqform \
        -interp nearestneighbour

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



Path=`getopt1 "--path" $@`  # "$1"
Subject=`opts_GetOpt1 "--sub" $@` # "$2"
Session=`getopt1 "--session" $@`  # "$3" session ID (e.g. ses-01)
annotation=`getopt1 "--parcellation" $@` # "$4" name of parcellation used (here: HCPMMP1)
NOCLEANUP=`getopt1 "--nocleanup" $@` # "$5" boolean whether to perform cleanup of temporary directories. default = False > removing temp dir

WD="${Path}/${Subject}/${Session}"

if [[ -z ${annotation} ]]; then
    log_Msg "WARNING:    No <<parcellation>> specified. Using HCP-MMP1 (Glasser et al. 2016) default parcellation."
    annotation="HCPMMP1"
fi

log_Msg "START:   Mapping of ${annotation} atlas to subject surface"

# set hemisphere variable
hemispheres="lh rh"
old_subjectdir=${SUBJECTS_DIR}

# create output variables
OutputDir="${WD}/parcellation"

# create parcellation directory
if [ ! -d ${OutputDir} ]; then 
    log_Msg "UPDATE:    creating parcellation results folder and temporary directory."
    mkdir ${OutputDir} && \
    mkdir "${OutputDir}/label" && \
    mkdir "${OutputDir}/fslabel" 
    GetTempDir ${OutputDir}
else 
    log_Msg "UPDATE:    previous parcellation results found. Moving to /parcellation-old-${Date} and creating new result folder."
    mv ${OutputDir} "${OutputDir}-old-${Date}"
    mkdir ${OutputDir} && \
    mkdir "${OutputDir}/label" && \
    mkdir "${OutputDir}/fslabel" 
    GetTempDir ${OutputDir}
fi


# check if HCPMMP1 annotation files in fsaverage directory
if [ ! -e "${WD}/T1w/fsaverage/label/lh.${annotation}.annot" ]; then
    log_Msg "UPDATE:    including annotation files in ./T1w/fsaverage/label/"
    # copy fsaverage from templates to ensure ownership
    rm -r "${WD}/T1w/fsaverage"
    cp -r "${FREESURFER_HOME}/subjects/fsaverage" "${WD}/T1w/fsaverage"
    # copy annotation files
    cp "${LEAPP_TEMPLATES}/lh.${annotation}.annot" "${WD}/T1w/fsaverage/label/lh.${annotation}.annot"
    cp "${LEAPP_TEMPLATES}/rh.${annotation}.annot" "${WD}/T1w/fsaverage/label/rh.${annotation}.annot"
fi


#############################################
#                                           #
#          PREPARE LABEL LISTS              #
#                                           #
#############################################

# setting subjectsdir variable to use local subject folder
SUBJECTS_DIR="${WD}/T1w"

for hemi in ${hemispheres}; do
    log_Msg "UPDATE:    Creating annotation labels for: " ${hemi}
    mri_annotation2label --subject fsaverage \
        --hemi ${hemi} --outdir "${OutputDir}/fslabel" \
        --annotation ${annotation} >> "${TempDir}/log_annotation2label"
    mri_annotation2label --subject fsaverage \
        --hemi ${hemi} --outdir "${OutputDir}/fslabel" \
        --annotation ${annotation} \
        --ctab "${TempDir}/colortab_${annotation}_${hemi}1" >> "${TempDir}/log_annotation2label"
done

# clean color table
for hemi in ${hemispheres}; do
    awk '!($1="")' "${TempDir}/colortab_${annotation}_${hemi}1" >> "${TempDir}/colortab_${annotation}_${hemi}2"
done

# create region list
for hemi in ${hemispheres}; do
    awk '{print $2}' "${TempDir}/colortab_${annotation}_${hemi}1" > "${TempDir}/list_labels_${hemi}1"
    # sed '/???/d' "${TempDir}/list_labels_${hemi}1" > "${TempDir}/list_labels_${hemi}1clean"
done

    

# check for existing labels
for hemi in ${hemispheres}; do
    for label in `cat ${TempDir}/list_labels_${hemi}1`; do
        if [[ -e ${OutputDir}/fslabel/${hemi}.${label}.label ]]; then
            echo ${hemi}.${label}.label >> ${TempDir}/list_labels_${annotation}${hemi}
            grep " ${label} " "${TempDir}/colortab_${annotation}_${hemi}2" >> "${TempDir}/colortab_${annotation}_${hemi}3"
        fi
    done
    # insert HCP-MMP1 numbers
    number_labels=`wc -l < ${TempDir}/list_labels_${annotation}${hemi}`
    if [ ${hemi} = 'lh' ]; then
        step=1000
        else
        step=2000
    fi
    for ((i=1;i<=${number_labels};i+=1)); do
        num=`echo "${i}+${step}" | bc`
        printf "$num\n" >> ${TempDir}/LUT_number_table_${annotation}${hemi}
        printf "$i\n" >> ${TempDir}/${annotation}_number_table_${hemi}
    done
done
# # check for existing labels
# for hemi in ${hemispheres}; do
#     for label in `cat ${TempDir}/list_labels_${hemi}1clean`; do
#         if [[ -e ${OutputDir}/fslabel/${hemi}.${label}.label ]]; then
#             echo ${hemi}.${label}.label >> ${TempDir}/list_labels_${annotation}${hemi}
#             grep " ${label} " "${TempDir}/colortab_${annotation}_${hemi}2" >> "${TempDir}/colortab_${annotation}_${hemi}3"
#         fi
#     done
#     # insert HCP-MMP1 numbers
#     number_labels=`wc -l < ${TempDir}/list_labels_${annotation}${hemi}`
#     if [ ${hemi} = 'lh' ]; then
#         step=1000
#         else
#         step=2000
#     fi
#     for ((i=1;i<=${number_labels};i+=1)); do
#         num=`echo "${i}+${step}" | bc`
#         printf "$num\n" >> ${TempDir}/LUT_number_table_${annotation}${hemi}
#         printf "$i\n" >> ${TempDir}/${annotation}_number_table_${hemi}
#     done
# done

# check LUT for actual regions
for hemi in ${hemispheres}; do
    paste ${TempDir}/${annotation}_number_table_${hemi} \
        ${TempDir}/colortab_${annotation}_${hemi}3 > ${TempDir}/colortab_${annotation}_${hemi}
    paste ${TempDir}/LUT_number_table_${annotation}${hemi} \
        "${TempDir}/list_labels_${annotation}${hemi}" > "${TempDir}/LUT_${hemi}_${annotation}"
done
# combine LUTs
cat ${TempDir}/LUT_lh_${annotation} ${TempDir}/LUT_rh_${annotation} > "${TempDir}/LUT_${annotation}.txt"
# adjust naming convention
sed '/_H_ROI/d' "${TempDir}/LUT_${annotation}.txt" > "${OutputDir}/LUT_${annotation}.txt"  
# transform labels from fsaverage to subject space

#############################################
#                                           #
#  TRANSFORMING LABEL FILES TO PARCELLATION #
#                                           #
#############################################

for hemi in ${hemispheres}; do
    for label in `cat ${TempDir}/list_labels_${annotation}${hemi}`; do
        log_Msg "transforming ${label}"
        mri_label2label --srcsubject fsaverage \
        --srclabel ${OutputDir}/fslabel/${label} \
        --trgsubject ${Subject} --trglabel "${OutputDir}/label/${label}.label" \
        --regmethod surface --hemi ${hemi} >> "${OutputDir}/log_label2label"
    done
done

# convert labels back to annot file in subject space
# and create parcellation annotation in subject surface
for hemi in ${hemispheres}; do
    for label in `cat ${TempDir}/list_labels_${annotation}${hemi}`; do
        printf " --l ${OutputDir}/label/${label}" >> "${TempDir}/temp_cat_${annotation}_${hemi}"
    done

    mris_label2annot --s ${Subject} --h ${hemi} \
        `cat ${TempDir}/temp_cat_${annotation}_${hemi}` \
        --a ${Subject}_${annotation} \
        --ctab "${TempDir}/colortab_${annotation}_${hemi}" >> ${OutputDir}/label2annot_${annotation}${hemi}.log
done

# convert label file to volume
mri_aparc2aseg --s ${Subject} \
    --o "${TempDir}/${annotation}.nii.gz" \
    --annot ${Subject}_${annotation} >> "${OutputDir}/log_aparc2aseg"



# adjusting of incremented HCP-MMP1 ROI IDs

ROIMax=$( echo $( mrstats -ignorezero "${TempDir}/${annotation}.nii.gz" ) | cut -d" " -f 15 )
TheoreticalMax=$( echo $( tail -n 1 "${OutputDir}/LUT_${annotation}.txt" ) | cut -d' ' -f1)
CorticalMin=$( echo $( head -n 1 "${OutputDir}/LUT_${annotation}.txt" ) | cut -d' ' -f1)

if [[ "${ROIMax}" -gt "${TheoreticalMax}" ]]; then
    log_Msg "UPDATE:    adjusting threshold values for cortical ROIs."

    # split cortical and subcortical volumes.
    ${FSLDIR}/bin/fslmaths "${TempDir}/${annotation}.nii.gz" \
        -thr ${CorticalMin} "${TempDir}/${annotation}_ctx.nii.gz"

    ${FSLDIR}/bin/fslmaths "${TempDir}/${annotation}.nii.gz" \
        -uthr "$(( ${CorticalMin} - 1 ))" "${TempDir}/${annotation}_subctx.nii.gz"
    
    for hemi in ${hemispheres}; do
        log_Msg "UPDATE:    removing unknown voxels in ${hemi}."
        HemiMin=$( echo $( head -n 1 "${TempDir}/LUT_${hemi}_${annotation}" ) | cut -d' ' -f1)
        ${FSLDIR}/bin/fslmaths "${TempDir}/${annotation}_ctx.nii.gz" \
            -thr ${HemiMin} -uthr ${HemiMin} "${TempDir}/Unknown_${hemi}.nii.gz"

        ${FSLDIR}/bin/fslmaths "${TempDir}/${annotation}_ctx.nii.gz" \
            -sub "${TempDir}/Unknown_${hemi}.nii.gz" \
            "${TempDir}/${annotation}_ctx.nii.gz"
    done

    ${MRTRIXDIR}/bin/mrcalc -force -quiet \
    "${TempDir}/${annotation}_ctx.nii.gz" \
    1 -subtract \
    "${TempDir}/${annotation}_ctx_clean.nii.gz"

    ${FSLDIR}/bin/fslmaths "${TempDir}/${annotation}_ctx_clean.nii.gz" \
        -thr 1 "${TempDir}/${annotation}_ctx_clean.nii.gz"

    ${FSLDIR}/bin/fslmaths "${TempDir}/${annotation}_ctx_clean.nii.gz" \
        -add "${TempDir}/${annotation}_subctx.nii.gz" \
        "${TempDir}/${annotation}_clean.nii.gz"

else
    cp "${TempDir}/${annotation}.nii.gz" "${TempDir}/${annotation}_clean.nii.gz" 
fi


# cleaning of hippocampal residue from few surrounding voxels in HCP-MMP1 to FS based hippcampus
for hemi in ${hemispheres}; do
    log_Msg "UPDATE:    cleaning ${hemi} hippocampus representation in HCP-MMP1 to complete FS mapping of HPC."
    if [ ${hemi} = 'lh' ]; then
        _id='L'
        _nr=17
        else
        _id='R'
        _nr=53
    fi
    hpc_idx=`grep $( echo ${_id}_H_ROI.label) ${TempDir}/LUT_${annotation}.txt | cut -c-4`

    ${FSLDIR}/bin/fslmaths "${TempDir}/${annotation}_clean.nii.gz" \
        -thr ${hpc_idx} -uthr ${hpc_idx} "${TempDir}/${_id}_hipp_HCP"

    ${FSLDIR}/bin/fslmaths "${TempDir}/${_id}_hipp_HCP" \
        -bin -mul ${_nr} "${TempDir}/${_id}_hipp_FS"

    ${FSLDIR}/bin/fslmaths "${TempDir}/${annotation}_clean.nii.gz" \
        -sub "${TempDir}/${_id}_hipp_HCP" \
        -add "${TempDir}/${_id}_hipp_FS" \
        "${TempDir}/${annotation}_clean.nii.gz"

done

# prepare lookup table to include subcortical areas from FreeSurferColor_LUT.txt extracted

log_Msg "UPDATE:    include subcortial areas in ${annotation} lookup table."
cat ${LEAPP_TEMPLATES}/FreeSurfer_Subcortex_LUT.txt >> "${OutputDir}/LUT_${annotation}.txt" 


log_Msg "UPDATE:    reordering ROI labeling to use in MRtrix3."
# converting resulting nifti to integer type for MRTix3
${MRTRIXDIR}/bin/mrconvert -datatype uint32 -force -quiet \
    "${TempDir}/${annotation}_clean.nii.gz" \
    "${TempDir}/${annotation}_parcels.mif"

# adjusting labels to use ordered HCP-MMP1 ROI labels for use in MRTrix3
${MRTRIXDIR}/bin/labelconvert -force -quiet \
    "${TempDir}/${annotation}_parcels.mif" \
    "${OutputDir}/LUT_${annotation}.txt"  \
    "${LEAPP_TEMPLATES}/${annotation}_LUT_mrtrix.txt" \
    "${TempDir}/${annotation}_parcels_ordered.mif"

cp "${TempDir}/${annotation}_parcels_ordered.mif" \
    "${OutputDir}/${Subject}_${annotation}.mif"

# updating parcellation nifti image in parcellation directory
${MRTRIXDIR}/bin/mrconvert -datatype uint32 -force -quiet\
    "${OutputDir}/${Subject}_${annotation}.mif" \
    "${OutputDir}/${Subject}_${annotation}.nii.gz"

#############

# resampling parcellation volume to fit final T1w processed volume
Resample \
    "${OutputDir}/${Subject}_${annotation}.nii.gz" \
    "${WD}/T1w/T1w_acpc_dc_restore_brain.nii.gz"

# computing lesion load using final T1w lesion mask and parcellation volume
if [[ -f "${WD}/lesion/T1w_acpc_dc_restore_mask.nii.gz" ]]; then

    python3 ${LEAPP_STRUCTDIR}/Scripts/GetLesionLoads.py \
        --subject=${Subject} \
        --parcimage="${OutputDir}/${Subject}_${annotation}_resample.nii.gz" \
        --maskimage="${WD}/lesion/T1w_acpc_dc_restore_mask.nii.gz" \
        --lut="${LEAPP_TEMPLATES}/${annotation}_LUT_mrtrix.txt"
fi

# reset to default subjects_dir
export SUBJECTS_DIR=${old_subjectdir}


# Clean up of temporary directories
if [[ -z ${NOCLEANUP} ]]; then
    rm -r ${TempDir}
fi

log_Msg "FINISHED:   Mapping of ${annotation} atlas to subject surface"
