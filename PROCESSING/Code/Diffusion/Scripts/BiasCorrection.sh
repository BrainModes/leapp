#!/bin/bash
#
#
# BiasCorrection.sh
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
# This script performs biascorrection of the T1w registered DWI image volumes before running tractography.


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
Path=`getopt1 "--path" $@`  # "$1" directory path containing all subjects
Subject=`getopt1 "--sub" $@`  # "$2" subject ID 
Session=`getopt1 "--session" $@`  # "$3"

#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################
log_Msg "START:    bias correction ${Subject}"


dwibiascorrect ants -force -quiet \
    "${Path}/${Subject}/${Session}/dwi_preprocessed/${Subject}_DWI_preprocessed_brain.mif" \
    "${Path}/${Subject}/${Session}/dwi_preprocessed/${Subject}_DWI_biascorrected.mif"

chmod 755 "${Path}/${Subject}/${Session}/dwi_preprocessed/${Subject}_DWI_biascorrected.mif"


if [[ -z ${NOCLEANUP} ]]; then
    rm "${Path}/${Subject}/${Session}/dwi_preprocessed/${Subject}_DWI_preprocessed_brain.mif"
fi

log_Msg "FINISHED:    bias correction ${Subject}"
