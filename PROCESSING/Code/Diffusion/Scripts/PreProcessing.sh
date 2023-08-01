#!/bin/bash
#
#
# PreProcessing.sh
#
# * Brain Simulation Section
# * Charité Berlin Universitätsmedizin
# * Berlin Institute of Health
#
# ## Author(s)
# * Bey, Patrik, Charité Universitätsmedizin Berlin, Berlin Institute of Health
# 
#
# * last update: 2022.12.11
#
#
#
# ## Description
#
# This script performs the following DWI preprocessing steps:
#
# * 1. PCA based denoising (dwidenoise)
# * 2. Gibbs ring artefact removal
# * 3. Eddy current and motion correction
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

GetPEDirection() {
    # $1 input metadata json file
    # output phase encoding direction without quotation marks for use with dwifslpreproc
    PE_dir=$(cat ${1} | grep '"PhaseEncodingDirection":' )
    IFS=':' read -a words <<<${PE_dir%,}
    PE_dir=$( echo ${words[1]} ) 
    export PE_dir=$( echo $PE_dir | tr -d '"' )
} 

source ${HCPPIPEDIR}/global/scripts/log.shlib  # Logging related functions
source ${HCPPIPEDIR}/global/scripts/opts.shlib # Command line option functions


#############################################
#                                           # 
#            CHECK INPUT                    #
#                                           #
#############################################

# parse arguments
Path=`getopt1 "--path" $@`  # "$1"
Subject=`opts_GetOpt1 "--sub" $@` # "$2"
Session=`getopt1 "--session" $@`  # "$3"

WD="${Path}/${Subject}/${Session}/dwi_preprocessed"
#define input volumes / parameter
dwi_raw_mif="${WD}/${Subject}_DWI_raw.mif"


# define output volumnes
dwi_denoised="${WD}/${Subject}_DWI_denoised.mif"
dwi_unringed="${WD}/${Subject}_DWI_unringed.mif"
dwi_preprocessed="${WD}/${Subject}_DWI_preprocessed.mif"

# add dynamic core usage for multithreading

#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################


log_Msg "START:    DWI denoising, unringing and preprocessing for ${Subject}"

# # get phase encoding direction for preprocessing
# PE_dir=$(cat "${WD}/${Subject}_meta.json" | \
#     grep '"PhaseEncodingDirection":' | cut -b29-30)
# adjust PE directory extraction for single digit letters
# PE_dir=$(cat "${WD}/${Subject}_meta.json" | grep '"PhaseEncodingDirection":' )
# IFS=':' read -a words <<<${PE_dir%,}
# PE_dir="${words[1]}"

GetPEDirection "${WD}/${Subject}_meta.json"

# run denoising
${MRTRIXDIR}/bin/dwidenoise -force -quiet \
    ${dwi_raw_mif} \
    ${dwi_denoised} \
    -noise "${WD}/noise_map.nii.gz"


# ensure access rights to files
chmod 755 ${dwi_denoised}
# include lesion mask in denoising?
# dwidenoise ${dwi_raw_mif} ${dwi_denoised} -mask ${Path}${Subject}/lesion/CostFunctionMaskFlair2T2_invert.nii.gz -noise ${Path}${Subject}/dwi_preprocessed/noise_map.nii.gz -force


# run gibbs ring removal
${MRTRIXDIR}/bin/mrdegibbs -force -quiet \
    ${dwi_denoised} \
    ${dwi_unringed} 

# ensure access rights to files
chmod 755 ${dwi_unringed}

#perform eddy current and motion correction using dwipreproc
${MRTRIXDIR}/bin/dwifslpreproc -force -quiet \
    -rpe_none \
    -pe_dir ${PE_dir} \
    -eddy_options ' --slm=linear' \
    ${dwi_unringed} \
    ${dwi_preprocessed}

# ensure access rights to files
chmod 755 ${dwi_preprocessed}
if [ -z ${NOCLEANUP} ]; then
    rm ${dwi_unringed}
    rm ${dwi_raw_mif}
    rm ${dwi_denoised}
fi

log_Msg "END:    DWI denoising, unringing and preprocessing  for ${Subject}"

