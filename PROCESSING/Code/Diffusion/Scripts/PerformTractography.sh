#!/bin/bash
#
#
# # PerformTractography.sh
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
#
#
# ## Description
#
# This script performs anatomically constrained tractography as part of the DWITractography.sh script.
#
# * steps within this script:
# * 1. perform tractography 
# * 1.1 Constrained Spherical Deconvolution
# * 1.2.SIFT based streamline weights




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

# parse arguments
Path=`getopt1 "--path" $@`  # "$1"
subj=`opts_GetOpt1 "--sub" $@` # "$2"
Session=`getopt1 "--session" $@`  # "$3" session ID (e.g. 01)
streams=`opts_GetOpt1 "--streams" $@` # "$4" default:100000000
n_cores=`opts_GetOpt1 "--cores" $@` # "$5" number of cores to use 
lesionimg=`opts_GetOpt1 "--lesion" $@` # "$6" lesion embedded 5tt image to use for anatomical constrained tractography


#define input volumes / parameter
avg_response="${Path}/GroupLevel/${Session}/average_response.txt"

if [ -z ${n_cores} ]; then
    n_cores=10
fi

#----------------check 5tt image-------------------#
# check if lesion present to use as 5tt image with 
# embedded lesion else use non-embedded 5tt image.
if [[ ! -z ${lesionimg} ]]; then
    log_Msg "UPDATE:    using 5tt image with lesion embedding as anatomical constraint."
    fivettimage=${lesionimg}
    tck_file="${Path}/${subj}/${Session}/dwi_preprocessed/${subj}_${streams}_lesion.tck"
    sift_file="${Path}/${subj}/${Session}/dwi_preprocessed/sift2_weights_lesion.txt"
else
    log_Msg "UPDATE:    using 5tt image without lesion as anatomical constraint."
    fivettimage="${Path}/${subj}/${Session}/dwi_preprocessed/5tt.mif"
    tck_file="${Path}/${subj}/${Session}/dwi_preprocessed/${subj}_${streams}.tck"
    sift_file="${Path}/${subj}/${Session}/dwi_preprocessed/sift2_weights.txt"
fi



#############################################s
#                                           #
#            DO COMPUTATIONS                #
#                                           #
#############################################


log_Msg "START:    performing tractography for ${subj}"



#----------get fiber orientation distributions-----------#
${MRTRIXDIR}/bin/dwi2fod csd -force -quiet -nthreads ${n_cores} \
    "${Path}/DWIIntNorm/${Session}/output/${subj}_DWI_biascorrected.mif" \
    ${avg_response} "${Path}/${subj}/${Session}/dwi_preprocessed/WM_FOD_tournier.mif" 

#---------------------get GMWMi seed---------------------#
${MRTRIXDIR}/bin/5tt2gmwmi -force \
    ${fivettimage} "${Path}/${subj}/${Session}/dwi_preprocessed/GMWMSeed.mif"

#------------------Generate ACT tracks--------------------#
log_Msg "UPDATE:    selecting ${streams} anatomically constrained tracts."
${MRTRIXDIR}/bin/tckgen -force \
    "${Path}/${subj}/${Session}/dwi_preprocessed/WM_FOD_tournier.mif" \
    ${tck_file} \
    -algorithm iFOD2 \
    -cutoff 0.06 -nthreads ${n_cores} \
    -act ${fivettimage} \
    -backtrack -seed_gmwmi "${Path}/${subj}/${Session}/dwi_preprocessed/GMWMSeed.mif" \
    -maxlength 250 -select ${streams}

#------------use sift2 for streamline weights-------------#
tcksift2 -force \
    -act ${fivettimage} \
    ${tck_file} \
    "${Path}/${subj}/${Session}/dwi_preprocessed/WM_FOD_tournier.mif" \
    ${sift_file} \
    -nthreads ${n_cores}


log_Msg "FINISHED:    performing tractography for ${subj}"





