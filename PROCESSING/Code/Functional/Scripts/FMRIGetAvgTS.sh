#!/bin/bash
#
#
# # FMRIGetAvgTS.sh
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
# * last update: 2022.11.01
#
#
#
# ## Description
#
# This scripts extracts the average time series for provided brain parcellation
# to use in further analysis. This script also assumes the provided parcellation 
# image (default= HCP-MMP1) is in the same space as the EPI image (here: MNI152)
#
# The follwoing steps are performed:
#
# * 1. create temp directory
# * 2. use parcellation image to extract average timesries (fslmeants)






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

GetTempDir(){
# create temporary directory
    randID=$RANDOM
    export TempDir="${1}/temp-${randID}"
    mkdir ${TempDir}
}

GetDimInfo () {
# get image dimension from input header
# and return as $ImgDim
    _dim1="$( fslval ${1} dim1)"
    len1="$((${#_dim1}-1))"
    _dim2="$( fslval ${1} dim2)"
    len2="$((${#_dim2}-1))"
    _dim3="$( fslval ${1} dim3)"
    len3="$((${#_dim3}-1))"
    export ImgDim=${_dim1:0:${len1}}"x"${_dim2:0:${len2}}"x"${_dim3:0:${len3}}
}

GetAvgTs() {
    # wrapper function to extract average time series from input image for given ROI
    #
    # input: ${1} input 4D EPI time series
    #        ${2} ROI ID
    # output: txt file containing average time series
    # temp="$( fslmeants -i ${1} -m ${TempDir}/ROI_${2}_Mask.nii.gz )"
    fslmeants -i ${1} --label=${2} -o "${TempDir}/AvgTS.txt"
    # echo ${temp} >> "${TempDir}/AvgTS.txt"
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
TaskName=`getopt1 "--fmriname" $@`  # "$4" fmri task name used in FMRIPreProc.sh
ParcName=`getopt1 "--parcname" $@`  # "$5" parcellation name to use for connectome creation (if present in TVBTEMPLATES directory)
ParcImage=`getopt1 "--parcimage" $@`  # "$6" parcellation image to use for connectome creation (if non default HCP-MMP1 parcellation)

WD="${Path}/${Subject}/${Session}/${TaskName}"

if [[ ! -d "${Path}/${Subject}/${Session}/MNINonLinear/Results/${TaskName}" ]]; then
    log_Msg "ERROR:    Corresponding results folder ${WD} missing. Did you run FMRIPreProc.sh before?"
    exit 1
fi

if [[ -z ${TaskName} ]]; then
    log_Msg "ERROR:    No fMRI task specified. Please define >>fmriname<< variable."
    exit 1
fi

if [[ -z ${ParcName} ]] && [[ -z ${ParcImage} ]]; then
    # check if parcellation name defined, else use default HCP-MMP1 (Glasser et al. 2016)
    log_Msg "UPDATE:    Using default >>HCP-MMP1<< adjusted brain parcellation to create connectomes."
    ParcName="HCPMMP1"
    ParcImage="${Path}/${Subject}/${Session}/parcellation/${Subject}_${ParcName}_resample.nii.gz"
fi


# create temporary directory
GetTempDir ${WD}

# Get WPI input image
EPIImage="${WD}/${Subject}_task-${TaskName}_T1w.nii.gz"

#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################
log_Msg "START:    Creating average time series per ROI for ${Subject} for ${TaskName}."

GetAvgTs ${EPIImage} ${ParcImage}


# save average time series file
cp "${TempDir}/AvgTS.txt" \
    "${WD}/${Subject}_task-${TaskName}_avg_ts.txt"

log_Msg "UPDATE:    remomving tmp directory ${TempDir}"
rm -r ${TempDir}


log_Msg "FINISHED:    Creating average time series per ROI for ${Subject} for ${TaskName}."

