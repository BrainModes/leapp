#!/bin/bash
#
#
# # DWITractography.sh
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
# This script performs tractography and connectome creation.
#
# * steps within this script:
# * 1. perform tractography 
# * 1.1 Constrained Spherical Deconvolution
# * 1.2.SIFT based
# * 2. Create Connectome
#
# REQUIREMENTS: 
# 1. LeAPP structural processing
# 2. DWIPreProc.sh performed
# 3. DWIIntNormalize.sh performed
# 4. DWITissueSeperation.sh performed
# 5. DWIAvgResponse.sh performed
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
ParcName=`getopt1 "--parcname" $@`  # "$4" name of parcellation to be used in tractography default is HCP DK atlas
Streams=`getopt1 "--streams" $@` # "$5" number of streams to create during tractography
lesioninclude=`getopt1 "--lesion" $@` # "$6" lesion mask to add as pathological tissue in 5TT image

#######################
# perform computations
#######################

log_Msg "START: Performing tractoraphy for ${Subject}"

# check if streams provided else use default 100Mio streams
if [[ -z ${Streams} ]]; then
    log_Msg "UPDATE:   No number of streams defined. Creating default 10Mio streamlines."
    Streams=10000000
else
    log_Msg "UPDATE:    Creating ${Streams} streamlines."
fi


# change to $Path working directory to ensure enough storage for writing files
cd ${Path}


#############################################s
#                                           #
#            DO COMPUTATIONS                #
#                                           #
#############################################


if [[ ! -z ${lesioninclude} ]]; then
    # create tractography including lesion pathology
    ${LEAPP_DWIDIR}/Scripts/PerformTractography.sh \
        --path=${Path} \
        --sub=${Subject} \
        --session=${Session} \
        --streams=${Streams} \
        --cores=${cores} \
        --lesion="${Path}/${Subject}/${Session}/dwi_preprocessed/5tt_lesion.mif"

    ${LEAPP_DWIDIR}/Scripts/GetConnectome.sh \
        --path=${Path} \
        --sub=${Subject} \
        --session=${Session} \
        --parc=${ParcName} \
        --streams=${Streams} \
        --cores=${cores} \
        --lesion=${lesioninclude}
    log_Msg "UPDATE:   connectome with lesion 5TT created for ${Subject}"
    # also create tractography without lesion pathology for comparison
    # ${LEAPP_DWIDIR}/Scripts/PerformTractography.sh \
    #     --path=${Path} \
    #     --sub=${Subject} \
    #     --streams=${Streams} \
    #     --cores=${cores}
    # ${LEAPP_DWIDIR}/Scripts/GetConnectome.sh \
    #     --path=${Path} \
    #     --sub=${Subject} \
    #     --parc=${ParcName} \
    #     --streams=${Streams} \
    #     --cores=${cores}
    # log_Msg "UPDATE:   connectome without lesion 5TT created for ${Subject}"
else
    # create tractography without lesion pathology
    ${LEAPP_DWIDIR}/Scripts/PerformTractography.sh \
        --path=${Path} \
        --sub=${Subject} \
        --session=${Session} \
        --streams=${Streams} \
        --cores=${cores}

    ${LEAPP_DWIDIR}/Scripts/GetConnectome.sh \
        --path=${Path} \
        --sub=${Subject} \
        --session=${Session} \
        --parc=${ParcName} \
        --streams=${Streams} \
        --cores=${cores}

fi


# plotting created structural connectomes

python3 ${LEAPP_DWIDIR}/Scripts/PlotStructuralConnectomes.py \
    --path=${Path} \
    --subject=${Subject} \
    --session=${Session}

log_Msg "FINISHED:   Performing tractoraphy for ${Subject}"


