#!/bin/bash
#
#
# ResponseFunction.sh
#
# * Brain Simulation Section
# * Charité Berlin Universitätsmedizin
# * Berlin Institute of Health
#
# ## Author(s)
# * Bey, Patrik, Charité Universitätsmedizin Berlin, Berlin Institute of Health
# 
#
# * last update: 2022.11.02
#
#
#
# ## Description
#
# This script performs response function estimation for use with tractography.
#
# *



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

Path=`getopt1 "--path" $@`  # "$1" directory path containing all subjects
Subject=`getopt1 "--sub" $@`  # "$2" subject ID 
Session=`getopt1 "--session" $@`  # "$3" session ID (e.g. 01)

log_Msg "START:    computing response function for ${Subject}"

#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################
# estimate response function
${MRTRIXDIR}/bin/dwi2response tournier -force \
    "${Path}/DWIIntNorm/${Session}/output/${Subject}_DWI_biascorrected.mif" \
    "${Path}/${Subject}/${Session}/dwi_preprocessed/RF_WM_tournier.txt" \
    -voxels "${Path}/${Subject}/${Session}/dwi_preprocessed/RF_voxels_tournier.mif"

log_Msg "FINISHED:    computing response function for ${Subject}"
