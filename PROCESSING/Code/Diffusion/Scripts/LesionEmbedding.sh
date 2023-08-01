#!/bin/bash
#
# # LesionEmbedding.sh
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
# Subscript called during TissueSegmentation.sh as optional step for lesion handling during anatomically constrained tractography (ACT).
# The default type of embedding is using 5ttedit MRtrix functionality. The additional experimentatl type only 
# adds the given lesion mask as the pathological tissue type in the 4D five tissue type image volume.
#
# REQUIREMENTS: 
# 1. DWIPreProc.sh
# 2. five tissue type segmentation
#
#
#   Lesion embedding option
#
# option 1: classical MRTrix3 lesion embedding
#     updating all tisue types to contain lesion information (i.e. adding lesion mask
#     as pathological tissue and removing lesion signal from Gm, WM etc.
# option 2: experimentatl embedding
#     only including lesion mask as pathological tissue, not altering other tissue types.




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

source ${HCPPIPEDIR}/global/scripts/log.shlib  # Logging related functions
source ${HCPPIPEDIR}/global/scripts/opts.shlib # Command line option functions


#############################################
#                                           #
#            CHECK INPUT                    #
#                                           #
#############################################

Path=`getopt1 "--path" $@`
subj=`getopt1 "--subj" $@`
Session=`getopt1 "--session" $@`  # "$3" session ID (e.g. 01)
embedding=`getopt1 "--type" $@` # "$3" describing the type of lesion embedding: DEFAULT= use 5tt to upgrade ALL tissue types to exclude pathological tissue / MINIMAL = only include lesion mask as type 5 tissue
log_Msg "START:    performing lesion embedding in 5TT volume for ${subj}"


WD="${Path}/${subj}/${Session}/dwi_preprocessed"
InputImage="${WD}/5tt"
GetTempDir ${WD}


#############################################
#                                           #
#            DO COMPUTATIONS                #
#                                           #
#############################################

log_Msg "UPDATE:    running default MRtrix3 based lesion embedding <5ttedit>."

${MRTRIXDIR}/bin/5ttedit -force \
    ${InputImage}".mif" \
    ${InputImage}"_lesion.mif" \
    -path "${Path}/${subj}/${Session}/lesion/T1w_acpc_dc_restore_mask.nii.gz"

log_Msg "FINISHED:    performing lesion embedding in 5TT volume for ${subj}"
