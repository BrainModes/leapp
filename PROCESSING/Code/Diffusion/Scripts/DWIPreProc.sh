#!/bin/bash
#
#
# DWIPreProc.sh
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
# This script performs diffusion processing steps to enable connectome creation in
# following scripts.
#
# * processing steps within this script:
# * 0. corresponsing file selection in case of multiple starts of DWI
# * 1. denoising
# * 2. EPI distortion correction (simple approach via registration to T1w space)
# * 3. bias correction

# This script assumes the lesion2tvb structural processing pipeline has been performed.
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

CheckExit() {
    if [[ $( echo $? ) -eq 1 ]]; then
        log_Msg "ERROR:    previous processing step $( basename ${1}) did not complete."
        exit 1
    fi
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
ParcName=`getopt1 "--parcname" $@`  # "$4" Atlas to be used for parcellation for structural connectome creation in later step.

# check previous structural processing steps
if [[ ! -d "${Path}/${Subject}/${Session}/T1w" ]]; then
    log_Msg "ERROR:   No T1w folder of strucutral processing steps found. Please run structural processing before diffusion pipeline"
    exit 1
fi


#set current directory to working directory to enable creation of temporary folders by mrtrix
cd "${Path}/${Subject}/${Session}"

#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################

log_Msg "START:    Diffusion preprocessing for ${Subject}"

# identifying diffusion file with corresponding bvec, bval and json
${LEAPP_DWIDIR}/Scripts/GetFiles.sh \
    --path=${Path} \
    --sub=${Subject} \
    --session=${Session}

CheckExit ${LEAPP_DWIDIR}/Scripts/GetFiles.sh


# perform denoising, degibbsing and dwifslpreproc from mrtrix3
${LEAPP_DWIDIR}/Scripts/PreProcessing.sh \
    --path=${Path} \
    --sub=${Subject} \
    --session=${Session}

CheckExit ${LEAPP_DWIDIR}/Scripts/PreProcessing.sh

# registration to T1w final processed space
${LEAPP_DWIDIR}/Scripts/T1wRegistration.sh \
    --path=${Path} \
    --sub=${Subject} \
    --session=${Session}

CheckExit ${LEAPP_DWIDIR}/Scripts/T1wRegistration.sh

# perform bias correction
${LEAPP_DWIDIR}/Scripts/BiasCorrection.sh \
    --path=${Path} \
    --sub=${Subject} \
    --session=${Session}

CheckExit ${LEAPP_DWIDIR}/Scripts/BiasCorrection.sh


log_Msg "COMPLETED: diffusion preprocessing for ${Subject}"

