#!/bin/bash
#
# # DWIIntensityNormaization.sh
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
# * last update: 2022.12.10
#
#
#
# ## Description
#
# This script  performs population based intensity normalization
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



#############################################
#                                           #
#            CHECK INPUT                    #
#                                           #
#############################################

# save current working directory for later before temporarily switching 
# to $Path to handle automatic temp directories
InitCD=${PWD}

# parse arguments
Path=`getopt1 "--path" $@`  # "$1"
Session=`getopt1 "--session" $@`  # "$2"

# define input files
SubjectBiasFiles="$( find ${Path}/*/"${Session}/dwi_preprocessed" -name *"_DWI_biascorrected.mif")"
SubjectMaskFiles="$( find ${Path}/*/"${Session}/dwi_preprocessed" -name *"_DWI_brainmask.nii.gz")"

# if [[ ! -d ${Path}/"dwiintensitynorm_input" ]]; then
#     mkdir ${Path}/'dwiintensitynorm_input'
# fi

# if [[ ! -d ${Path}/"dwiintensitynorm_mask" ]]; then
#     mkdir ${Path}/'dwiintensitynorm_mask'
# fi

# if [[ ! -d ${Path}/"dwiintensitynorm_output" ]]; then
#     mkdir ${Path}/'dwiintensitynorm_output'
# fi

if [[ ! -d ${Path}/"DWIIntNorm/${Session}" ]]; then
    mkdir -p "${Path}/DWIIntNorm/${Session}"
    mkdir -p "${Path}/DWIIntNorm/${Session}/input"
    mkdir -p "${Path}/DWIIntNorm/${Session}/mask"
    mkdir -p "${Path}/DWIIntNorm/${Session}/output"
fi


#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################


cp ${SubjectBiasFiles} "${Path}/DWIIntNorm/${Session}/input"

cp ${SubjectMaskFiles} "${Path}/DWIIntNorm/${Session}/mask"


log_Msg "START:    performing population based intensity normalization for ${Session}"

# save included filenames for QC purposes
echo ${SubjectBiasFiles} > "${Path}/DWIIntNorm/${Session}/FileList.txt"

FileCount="$( echo $( ls "${Path}/DWIIntNorm/${Session}/input" | wc -l ))"

if [ ! $FileCount -gt 1 ]; then
    log_Msg "WARNING:    Only single input image found. Not performing population based normalization."
    cp ${SubjectBiasFiles} \
    "${Path}/DWIIntNorm/${Session}/output"
    exit 0
fi

${MRTRIXDIR}/bin/dwinormalise group -force -quiet \
    "${Path}/DWIIntNorm/${Session}/input" \
    "${Path}/DWIIntNorm/${Session}/mask" \
    "${Path}/DWIIntNorm/${Session}/output" \
    "${Path}/DWIIntNorm/${Session}/output/fa_template.mif" \
    "${Path}/DWIIntNorm/${Session}/output/wm_mask.mif"


log_Msg "FINISHED:    performing population based intensity normalization for ${Session}"

# change back to initial working directory
cd ${InitCD}