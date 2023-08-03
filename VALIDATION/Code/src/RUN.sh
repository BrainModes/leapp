#!/bin/bash
#
# # RUN.sh    [  DOCKER CONTAINER VERSION  ]
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
#
# ## Description
#
# This script is a wrapper for the full functionality of the LeAPP validation
# pipeline as described in Bey et al. (in prep.)
#
#
#
#
#
# * This functionality of this script is described in the corresponding documentation
# * github.com/brainmodes/leapp
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




show_usage() {
	cat <<EOF

***************************************************************
***                    LeAPP VALIDATION                     ***

*** ------------ USAGE ------------ ***

docker run \
    -e Path=<string>       [optional] Path to input files.
                            default: /data bound volume to container

    -e Mode=<string>        [optional] Mode of input image to validate 
                           Possible options values:
                            <ribbon>:     Cortical ribbon validation
                            <WM>:         White matter mask validation
                            <string_WM>:  using "string_WM" volumes. (e.g. "FSL_WM")
                            <atlas>:      Atlas ROI based validation
                                required parameters:
                                <<Atlas>>
                            <connectome>:  Connectome network validation
                                required parameters:
                                <<Level>>
                                <<Connectome>>

    -e Atlas=<string>       [optional] Parcellation used for ROI based validation. Required for atlas
                                       volume validation mode
    
    -e Level=<string>       [optional] Level of connectome based network metrics. Required for 
                                       connectome validation.
                                       Possible options values:
                                       <global>:   global network metrics
                                       <local>:    local network metrics

    -e Labels=<string>      [required] Comma delimited list of group labels to perform comparison for

    -e Step=<string>        [required] Validation step to perform.
                            Possible options values:
                            <agreement>:  Running computation of agreement measures
                                required parameters:
                                    <<Mode>> 
                                    <<Labels>>

                            <metrics>:  Running metric computations
                                required parameters:
                                    Input image to segment.
                                optional parameter:
                                    OutDir output directory for segmentation results.

                            <stats>: Running statistical testing for groups
                                required parameters:
                                    Input matrices
                                optional parameters:
                                    
                            <learning>:   Running machine learning based classification
                                required parameters:
                                    <<Files>> [ list of group features]
                                optional parameters:
                                    <<cvsplit>> [Cross Validation split

    -e Files=<string>      [optional] list of comma/semicolo/space seperated input files
                            a single file for each group [subject x features]
    
    -e Connectome=<string>  [optional] Connectome name to use for validation
    
    -e CVSplit=<float>      [optional] value between 0 and 1 defining training / test split
                            If not provided default used is 0.1
    
    -e PrefixOut=<string>   [optional] Prefix used for classification output files
                            If not provided default used is "OutPut_"

    -e OutDir=<string>      [optional] Path to output directory.

*** ------------ INPUT ------------ ***


The expected file directory structure:
<<Path>>
    |___GroupLabel[1]
        |___sub-0001_filename.nii.gz
        ...
    |___GroupLabel[2]
        |___sub-0001_filename.nii.gz


EOF
	exit 1
}


if [[ -z ${Path} ]]; then
    log_msg "UPDATE:    no <<Path>> variable defined. Using default mounted directory <</data>>."
    Path="/data"
    if [ ! -d ${Path} ]; then
        log_msg "ERROR:    no mounted volume <</data>> found."
        show_usage
        exit 1
    fi
fi

if [[ -z ${Step} ]]; then
    log_msg "ERROR:    no <<Step>> variable defined."
    show_usage
    exit 1
fi

case "${Step}" in
    learning)
        if [ -z ${Files} ]; then
            log_msg "ERROR:    no <<Files>> variable defined"
            show_usage
            exit 1
        fi
    ;;
    agreement)
        if [ -z ${Mode} ]; then
            log_msg "ERROR:    no <<Mode>> variable defined."
            show_usage
            exit 1
        fi
    ;;
esac

if [[ -z ${OutDir} ]]; then
    log_msg "UPDATE:    no <<OutDir>> variable defined. using default <<Path>> "
    OutDir=${Path}
fi

if [[ ! -d ${OutDir} ]]; then
    log_msg "UPDATE:    creating output directory ${OutDir}"
    mkdir -p ${OutDir}
fi

case "${Mode}" in
    atlas)
        if [[ -z ${Atlas} ]]; then
            log_msg "ERROR:    no <<Atlas>> variable defined"
            show_usage
        fi
        export Connectome="None"
    ;;
    connectome)
        if [[ -z ${Level} ]]; then
            log_msg "ERROR:    no <<Level>> variable defined"
            show_usage
        fi
        if [[ -z ${Connectome} ]]; then
            log_msg "ERROR:    no <<Connectome>> variable defined"
            show_usage
        fi
    ;;
    learning)
        if [[ -z ${Files} ]]; then
            log_msg "ERROR:    no <<Files>> variable defined"
            show_usage
            exit 1
        fi
        if [[ -z ${CVsplit} ]]; then
            log_msg "UPDATE:    no <<CVSplit>> variable defined. using defaul 10%"
            CVSplit=0.1
        fi
esac




#############################################
#                                           #
#           DO COMPUTATIONS                 #
#                                           #
#############################################

log_msg "START:    running ${Step}."

case "${Step}" in
    agreement)
        ${SRCDIR}/scripts/GetAgreementMetrics.sh \
            -p ${Path} \
            -m ${Mode} \
            -l ${Labels} \
            -o ${OutDir} \
            -a ${Atlas} \
            -c ${Connectome}

    ;;
    metrics)
        python3 ${SRCDIR}/scripts/GetNetworkMetrics.py \
            --path ${Path} \
            --labels ${Labels} \
            --level ${Level} \
            --connectome ${Connectome} \
            --outdir ${OutDir}

    ;;
    stats)

    ;;
    learning)
        python3 ${SRCDIR}/scripts/GetClassification.py \
            --path ${Path} \
            --labels ${Labels} \
            --files ${Files} \
            --cvsplit "${CVSplit}" \
            --outfile ${PrefixOut}
    ;;
esac


log_msg "FINISHED:    running ${Step}."