#!/bin/bash
#
# # GetAgreementMetrics.sh
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
# * last update: 2023.08.01
#
#
# This script is a wrapper for computing agreement metrics for given processing results as 
# described in Bey et al. (in prep.) 
#
#


#############################################
#                                           #
#            CHECK ENVIRONMENT              #
#                                           #
#############################################


if [ -z "${SRCDIR}" ]; then
	echo "ERROR: SRCDIR environment variable must be set"
	exit 1
fi

#############################################
#                                           #
#         PREPARE WORKSPACE                 #
#                                           #
#############################################


source "${SRCDIR}/scripts/utils/utils.sh" # load utiuility functyions (logging, Temporary directory,...)



#############################################
#                                           #
#            CHECK INPUT                    #
#                                           #
#############################################

#-------------parse input-------------------#


while getopts p:m:l:o:a:c: flag; do
    case "${flag}" in
        p) Path=${OPTARG} # Path to group level directories
        ;;
        m) Mode=${OPTARG} # mode of input volume to perform comparison for
        ;; 
        l) Labels=${OPTARG} # group labels for diadic comparison
        ;; 
        o) OutDir=${OPTARG} # output directory
        ;;
        a) Atlas=${OPTARG} # Atlas used for parcellation
        ;;
        c) Connectome=${OPTARG} # Define connectome name to use

    esac
done

if [[ "${Mode}" = "atlas" ]]; then
    python3 ${SRCDIR}/scripts/GetMetrics_parcellation.py \
        --path ${Path} \
        --labels ${Labels} \
        --atlas ${Atlas} \
        --outdir ${OutDir}

elif [[ "${Mode}" = "connectome" ]]; then
    python3 ${SRCDIR}/scripts/GetMetrics_connectome.py \
        --path ${Path} \
        --labels ${Labels} \
        --connectome ${Connectome} \
        --outdir ${OutDir}

else
    python3 ${SRCDIR}/scripts/GetMetrics_brainmask.py \
        --path ${Path} \
        --labels ${Labels} \
        --mode ${Mode} \
        --outdir ${OutDir}

fi
