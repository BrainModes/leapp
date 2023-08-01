#!/bin/bash
#

# # FunctionalPipeline.sh
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
# * last update: 2023.05.19
#
#
#
# ## Description
#
# This script is performing functional processing of neuroimaging data within lesion2TVB pipeline.
#
# The following steps are performed:
#
# * 1. Volume based processing (adjusted HCP minimal processing pipeline)
# * 2. Extraction of average time series
# * 3. Connectome creation via correlation coefficient
#
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

GetTimeSeriesName() {
    # extract time series base name
    tmp=$( basename ${1%.nii.gz})
    tmp=$( echo ${tmp%_bold} | rev)
    tmp=$( echo ${tmp%-ksat*} | rev)
    FMRIName=$( echo ${tmp})
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
ParcName=`getopt1 "--atlas" $@`  # "$4" Atlas to use as parcellation for FC computation
AllSteps=`getopt1 "--allsteps" $@` # $55 boolean if all processing steps should be performed
PreProcStep=`getopt1 "--preproc" $@` # $6 boolean if preprocessing is performed
FCStep=`getopt1 "--connectome" $@` # $7 boolean if functional connectome creation is performed
FMRIFiles=`getopt1 "--fmrifiles" $@` # $8 fmri file names (including path) to process. [optional; default: use all volumes found in <<$Path/$Subject/func/>>]
TaskOnsets=`getopt1 "--onsets" $@` # $9 boolean if experimental design task onsets are used


if [[ ! -z ${AllSteps} ]]; then
    PreProcStep="True"
    FCStep="True"
fi

if [[ -z ${FMRIFiles} ]]; then
    log_Msg "UPDATE:    performing processing for all fmri volumes in <<${Path}/${Subject}/func/>>."
    FMRIFiles=$( find ${Path}/${Subject}/${Session}/func/*_bold.nii* -type f )
fi

# if [[ ! -z ${TaskOnsets} ]]; then
#     TaskOnsetDir="${Path}/${Subject}/func/onsets"
#     if [[ ! -d ${TaskOnsetDir} ]]; then
#         log_Msg "ERROR:    <<${TaskOnsetDir}>> directory not found. Please check documentation for naming conventions."
#         exit 1
#     fi
#     log_Msg "UPDATE:    using experimental design task onsets in <<${TaskOnsetDir}>>."
# fi

#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################




log_Msg "START:    functional processing for ${Subject}"


#-------------------PREPROCESSING-------------------#
if [[ ! -z ${PreProcStep} ]]; then
    log_Msg "START:    Volume based preprocessing for ${Subject}"
    for fmritaskfile in ${FMRIFiles[@]}; do
        ${LEAPP_FUNCTDIR}/Scripts/FMRIPreProc.sh \
            --path=${Path} \
            --subject=${Subject} \
            --session=${Session} \
            --timeseries=${fmritaskfile}
    done
    log_Msg "FINISHED:    Volume based preprocessing for ${Subject}"
fi





if [[ ! -z ${FCStep} ]]; then
    for fmritaskfile in ${FMRIFiles[@]}; do
        # FMRIName=$(echo $( basename ${fmritaskfile} )| cut -d- -f2 | cut -d. -f1)
        GetTimeSeriesName ${fmritaskfile}
        # FMRIName=$(echo $( basename ${fmritaskfile%.nii.gz} )| cut -d- -f2 | rev | cut -d_ -f2- | rev )
        log_Msg "START:    Extracting average time series for ${Subject} for ${FMRIName}."
#--------REGISTRATION PARCELLATION TO EPI-----------#
        ${LEAPP_FUNCTDIR}/Scripts/FMRIRegStructT1w.sh \
            --path=${Path} \
            --subject=${Subject} \
            --session=${Session} \
            --fmriname=${FMRIName} \
            --parcname=${ParcName} \

#----------------AVERAGE TIME SERIES----------------#
        ${LEAPP_FUNCTDIR}/Scripts/FMRIGetAvgTS.sh \
            --path=${Path} \
            --subject=${Subject} \
            --session=${Session} \
            --fmriname=${FMRIName} \
            --parcname=${ParcName} \
            --parcimage=${Path}/${Subject}/${Session}/parcellation/${Subject}_${ParcName}_resample.nii.gz

        log_Msg "FINISHED:    Extracting average time series for ${Subject} for ${FMRIName}."

#----------------CREATE CONNECTOME-----------------#
        log_Msg "START:    Creating functional connectome for ${Subject}"

        python3 ${LEAPP_FUNCTDIR}/Scripts/GetFunctConnectome.py \
            --path=${Path} \
            --subject=${Subject} \
            --session=${Session} \
            --taskname=${FMRIName}

        log_Msg "FINISHED:    Creating functional connectome for ${Subject}"

    done
fi
