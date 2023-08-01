#!/bin/bash
#
#
# # GetConnectome.sh
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
# This script computes connectomes for the tractography files created during PerformTractography.sh.
#
# * steps within this script:
# * 1. Create Connectome weights and tract lengths files






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
streams=`opts_GetOpt1 "--streams" $@` # "$4"
n_cores=`opts_GetOpt1 "--cores" $@` # "$5" number of cores to use 
parc=`opts_GetOpt1 "--parc" $@` # "$6" parcellation image for connectome computation
lesion=`opts_GetOpt1 "--lesion" $@` # "$7" boolean if to use lesion based files



if [ -z ${n_cores} ]; then
    n_cores=10
fi

# creating output directory
OutDir="${Path}/${subj}/${Session}/connectome"
if [[ ! -d ${OutDir} ]]; then
    mkdir ${OutDir}
fi

if [[ -z ${parc} ]]; then
    # check if parcellation name defined, else use default HCP-MMP1 (Glasser et al. 2016)
    log_Msg "UPDATE:    Using >>HCP-MMP1<< brain parcellation as default to create connectomes."
    ParcName="HCPMMP1"
else
    ParcName=${parc}
fi

ParcImage="${Path}/${subj}/${Session}/parcellation/${subj}_${ParcName}.mif"

if [ ! -z ${lesion} ]; then
    # define input variables
    tck_file="${Path}/${subj}/${Session}/dwi_preprocessed/${subj}_${streams}_lesion.tck"
    sift_weights="${Path}/${subj}/${Session}/dwi_preprocessed/sift2_weights_lesion.txt"
    # define output variables
    weights="${OutDir}/StructuralConnectome_weights_lesion.csv"
    lengths="${OutDir}/StructuralConnectome_lengths_lesion.csv"
    assignfile="${Path}/${subj}/${Session}/dwi_preprocessed/assignments_${ParcName}_lesion.csv"
else
    # define input variables
    tck_file="${Path}/${subj}/${Session}/dwi_preprocessed/${subj}_${streams}.tck"
    sift_weights="${Path}/${subj}/${Session}/dwi_preprocessed/sift2_weights.txt"
    # define output variables
    weights="${OutDir}/StructuralConnectome_weights.csv"
    lengths="${OutDir}/StructuralConnectome_lengths.csv"
    assignfile="${Path}/${subj}/${Session}/dwi_preprocessed/assignments_${ParcName}.csv"
fi


#############################################s
#                                           #
#            DO COMPUTATIONS                #
#                                           #
#############################################


log_Msg "START:    Computing connectome for ${subj}"


# create connectome
# tck2connectome -tck_weights_in ${sift_weights} ${tck_file} ${diffusion_mask_2dwi} ${weights} -nthreads ${n_cores} -force -symmetric -zero_diagonal
tck2connectome -force -symmetric -zero_diagonal \
    -tck_weights_in ${sift_weights} \
    ${tck_file} \
    ${ParcImage} \
    ${weights} \
    -out_assignment ${assignfile} \
    -nthreads ${n_cores}  

tck2connectome -scale_length -force -symmetric -zero_diagonal -stat_edge mean \
    -tck_weights_in ${sift_weights} \
    ${tck_file} \
    ${ParcImage} \
    ${lengths} \
    -nthreads ${n_cores} 

log_Msg "FINISHED:    Computing connectome for ${subj}"

