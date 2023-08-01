#!/bin/bash
#
#
# # DWIProcessing.sh
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
# This script performs diffusion processing steps to enable connectome creation in following scripts.
#
# * processing steps within this script:
# * 1. Five type tissue segmentation
# * 2. Response function computation
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

# parsing functions

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
Subject=`getopt1 "--subject" $@`  # "$2" subject ID (e.g. 0001)
Session=`getopt1 "--session" $@`  # "$3" session ID (e.g. 01)
lesion=`getopt1 "--lesion" $@`  # "$4" Boolean if lesioned patient data

#######################
# perform computations
#######################


#############################################
#                                           #
#            DO COMPUTATIONS                #
#                                           #
#############################################

log_Msg "START: performing tissue type segmentation and response estimation for ${Subject}"


# perform standard 5tt segmentation and include lesion mask as pathological tissue
${LEAPP_DWIDIR}/Scripts/TissueSegmentation.sh \
    --path=${Path} \
    --sub=${Subject} \
    --session=${Session} \
    --lesionembed=${lesion}

# compute response function
${LEAPP_DWIDIR}/Scripts/ResponseFunction.sh \
    --path=${Path} \
    --sub=${Subject} \
    --session=${Session}



log_Msg "COMPLETED: performing tissue type segmentation and response estimation for ${Subject}"
