#!/bin/bash
#
# # DWIAverageResponse.sh
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
# This script performs response function averaging across full population
#
#
#


#############################################
#                                           #
#            HELPER FUNCTIONS               #
#                                           #
#############################################

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

# parsing arguments
Path=`getopt1 "--path" $@`  # "$1" directory path containing all subjects
Session=`getopt1 "--session" $@`  # "$2" session ID (e.g. 01)

#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################


log_Msg "START:    computing population average resonse function"

if [[ ! -d "${Path}/GroupLevel/${Session}" ]]; then
    mkdir -p "${Path}/GroupLevel/${Session}"
fi

#----------------Get Relevant Files------------------#
# Inputs="$( find ${Path} -samefile *"${Session}/dwi_preprocessed/RF_WM_tournier.txt")"
Inputs="$( find ${Path}/*/"${Session}/dwi_preprocessed" -name *"RF_WM_tournier.txt")"
# save included filenames for QC purposes
echo ${Inputs} > "${Path}/GroupLevel/${Session}/AverageResponseFiles.txt"

#-----------------Average Response-------------------#
${MRTRIXDIR}/bin/responsemean -force \
    ${Inputs} \
    "${Path}/GroupLevel/${Session}/average_response.txt" 


log_Msg "FINISHED:    computing population average resonse function"


