#!/bin/bash
#

# # DiffusionPipeline.sh
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
# * last update: 2022.11.02
#
#
#
# ## Description
#
# This script is performing diffusion processing of neuroimaging data within lesion2TVB pipeline.
#
# The following steps are performed:
#
# * 1. Preprocessing
# * 2. Intensity Normalization [population wide]
# * 3. Tissue Segmentation
# * 4. Response Function Averaging [population wide]
# * 5. Tractography
# * 6. Connectome creation
#




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


# parse arguments
Path=`getopt1 "--path" $@`  # "$1" directory path containing all subjects
Subject=`getopt1 "--subject" $@`  # "$2" subject ID (e.g. 0001)
Session=`getopt1 "--session" $@`  # "$3" session ID (e.g. 01)
Atlas=`getopt1 "--atlas" $@`  # "$4" Atlas to use as parcellation for FC computation
PreProcStep=`getopt1 "--preproc" $@` # $5 boolean if preprocessing is performed
INStep=`getopt1 "--normal" $@` # $6 boolean if functional connectome creation is performed
SegmStep=`getopt1 "--segment" $@` # $7 fmri file names (including path) to process. [optional; default: use all volumes found in <<$Path/$Subject/func/>>]
RespStep=`getopt1 "--response" $@` # $8 boolean if experimental design task onsets are used
SCStep=`getopt1 "--connectome" $@` # $9 boolean if structural connectomes are created
LesionInclude=`getopt1 "--lesion" $@` # $10 boolean if to include lesion in processing
NrStreams=`getopt1 "--streams" $@` # $11 number of streams to compute in tractography [default 100Mio]
ROIMask=`getopt1 "--roimask" $@` # $12 mask image to use for ROI based connectome creation




#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################




log_Msg "START:    diffusion processing for ${Subject} : ${Session}."


#-------------------PREPROCESSING-------------------#
if [[ ! -z ${PreProcStep} ]]; then
    ${LEAPP_DWIDIR}/Scripts/DWIPreProc.sh \
        --path=${Path} \
        --subject=${Subject} \
        --session=${Session} \
        --parcname=${Atlas}
    
    CheckExit ${LEAPP_DWIDIR}/Scripts/DWIPreProc.sh
fi



#---------------INTENSITY NORMALIZATION--------------#
if [[ ! -z ${INStep} ]]; then
    ${LEAPP_DWIDIR}/Scripts/DWIIntensityNormalization.sh \
        --path=${Path} \
        --session=${Session}
    
    CheckExit ${LEAPP_DWIDIR}/Scripts/DWIIntensityNormalization.sh
fi



## adjusting
#--------5 TISSUE TYPE & RESPONSE FUNCTION----------#
if [[ ! -z ${SegmStep} ]]; then
    ${LEAPP_DWIDIR}/Scripts/DWIProcessing.sh \
        --path=${Path} \
        --subject=${Subject} \
        --session=${Session} \
        --lesion=${LesionInclude}
    
    CheckExit ${LEAPP_DWIDIR}/Scripts/DWIProcessing.sh
fi



#------------AVERAGING RESPONSE FUNCTION------------#
if [[ ! -z ${RespStep} ]]; then
    ${LEAPP_DWIDIR}/Scripts/DWIAvgResponse.sh \
		--path=${Path} \
        --session=${Session}
    
    CheckExit ${LEAPP_DWIDIR}/Scripts/DWIAvgResponse.sh
fi


#------------TRACTOGRAPHY & CONNECTOMES------------#
if [[ ! -z ${SCStep} ]]; then
    ${LEAPP_DWIDIR}/Scripts/DWITractography.sh \
        --path=${Path} \
        --subject=${SubID} \
        --session=${Session} \
        --parcname=${Atlas} \
        --lesion=${LesionInclude} \
        --streams=${NrStreams}
    
    CheckExit ${LEAPP_DWIDIR}/Scripts/DWITractography.sh
fi

if [[ ! -z ${ROIMask} ]]; then
    ${LEAPP_DWIDIR}/Scripts/DWIROIConnectome.sh \
        --path=${Path} \
        --subject=${SubID} \
        --session=${Session} \
        --parcname=${Atlas} \
        --rois=${ROIMask} \
        --streams=${NrStreams}

    CheckExit ${LEAPP_DWIDIR}/Scripts/DWIROIConnectome.sh
fi

log_Msg "FINISHED:    diffusion processing for ${Subject} : ${Session}."
