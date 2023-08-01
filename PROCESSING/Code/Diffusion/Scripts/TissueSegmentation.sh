#!/bin/bash
#
# # TissueSegmentation.sh
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
# This script performs processing of preprocessed DWI data to enable ACT based tractography.
#
# * processing steps within this script:
# * 1. five tissue seperation using FSL algorithm as 
# recommended from Robert E. Smith (MRTrix3 Forum)
# * 2. Registration of 5TT image to DWI space
# * 3. Registration of parcellation image to DWI space
# * 4. Embedding of lesion mask as pathological tissue in 5TT image (optional)
#
# REQUIREMENTS: 
# 1. LeAPP structural processing
# 2. DWIPreProc.sh performed
# 3. DWIIntNormalize.sh performed
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
Path=`getopt1 "--path" $@`
subj=`getopt1 "--sub" $@`
Session=`getopt1 "--session" $@`  # "$3" session ID (e.g. 01)
lesion=`getopt1 "--lesionembed" $@` # $4 logical if lesion mask should be added as pathological tissue in 5TT image
parc=`getopt1 "--parc" $@` # "$5" parcellation in T1w space to use as basis for tractography
n_cores=`getopt1 "--cores" $@` # "$6" number of cores to use 


# define numbers of cores used (default to 10)
# n_cores="$(grep -c ^processor /proc/cpuinfo)"
# n_cores="$((${n_cores}-1))"
if [[ -z ${n_cores} ]]; then
    n_cores=10
fi

if [[ -d "${Path}/${Subject}/${Session}/T1w" ]]; then
    log_Msg "ERROR:    No >>T1w<< results folder found. Please run structural processing first."
    exit 1
fi

if [[ -z ${LesionEmbed} ]]; then
    log_Msg "UPDATE:    performg standard MRTrix3 lesion embedding across all tissue types."
    LesionEmbed='classic'
fi


log_Msg "START:    performing five tissue type seperation for ${subj}"



#############################################
#                                           #
#            DO COMPUTATIONS                #
#                                           #
#############################################

############################################################
#
# generate 5 tissue typpe image from T1w image
#
############################################################


SGE_ROOT=""  5ttgen fsl -force -premasked -quiet -nocrop \
    -nthreads ${n_cores} \
    "${Path}/${subj}/${Session}/T1w/T1w_acpc_dc_restore_brain.nii.gz" \
    "${Path}/${subj}/${Session}/dwi_preprocessed/5tt.mif"

${MRTRIXDIR}/bin/mrconvert -force -quiet \
    "${Path}/${subj}/${Session}/dwi_preprocessed/5tt.mif" \
    "${Path}/${subj}/${Session}/dwi_preprocessed/5tt.nii.gz"





############################################################
#
# Embedding of lesion as pathological tissue type in 5tt image
#
############################################################


if [ ! -z ${lesion} ]; then
    # running default MRtrix based lesion embedding (5ttedit function)
    ${LEAPP_DWIDIR}/Scripts/LesionEmbedding.sh \
        --path=${Path} \
        --subj=${subj} \
        --session=${Session} \
        --type=${LesionEmbed}
fi

log_Msg "FINISHED:    performing five tissue type seperation for ${subj}"



