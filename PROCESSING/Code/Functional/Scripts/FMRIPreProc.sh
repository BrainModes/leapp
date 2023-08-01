#!/bin/bash
#
#
# # FMRIPreProc.sh
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
# This script perform functional MRI preprocessing and assumes the LeAPP structural processing 
# pipeline has been performed. It performs the the adjusted HCP minimal processing functional volume pipeline.
#
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

GetScanParameter() {
    # extract meta parameter of functional data acquisition to use in processing
    export PEdir=$(cat ${1} | grep '"PhaseEncodingDirection":' | cut -b29-30)
    export DwellTime=$(cat ${1} | grep '"DwellTime":'| cut -d: -f2| cut -d, -f1)
    export Resolution=$(cat ${1} | grep '"SliceThickness":'| cut -d: -f2| cut -d, -f1)
}

show_fmaps() {
	cat <<EOF


***     LESION AWARE PROCESSING PIPELINE (LeAPP)     ***

Assumed Fieldmaps based on Siemens scanners in BIDS standard:

./fmap/sub-01_task-{taskname}_part-1-mag_bold.nii.gz
./fmap/sub-01_task-{taskname}_part-2-mag_bold.nii.gz
./fmap/sub-01_task-{taskname}_part-phase_bold.nii.gz

EOF
	exit 1
}

# GetFieldMaps() {
#     # create filenames for time series corresponding fieldmap acquisitions to use in processing
#     FMapPhaseDiff=( ${Path}/${Subject}/${Session}/fmap/*_phasediff.nii.gz )
#     if [[ ${#FMapPhaseDiff[@]} -gt 1 ]]; then
#         FMapPhaseDiff=${FMapPhaseDiff[0]}
#     fi
#     if [[ ! -f ${FMapPhaseDiff} ]]; then
#         log_Msg "ERROR:    no corresponding <<phase difference>> image found."
#         show_fmaps
#         exit 1
#     fi
#     MagnitudeFiles=( ${Path}/${Subject}/${Session}/fmap/*_magnitude*.nii* )
#     if [[ ${#MagnitudeFiles[@]} -gt 1 ]]; then
#         ${FSLDIR}/bin/fslmerge -t \
#         "${Path}/${Subject}/${Session}/fmap/Concat_Magnitude_Image.nii.gz" \
#         ${MagnitudeFiles[0]} ${MagnitudeFiles[1]} 
#         FMapMagnitude="${Path}/${Subject}/${Session}/fmap/Concat_Magnitude_Image.nii.gz"
#     elif [[ ! -f ${MagnitudeFiles} ]]; then
#         log_Msg "ERROR:    no corresponding <<magnitude>> image(s) found."
#         show_fmaps
#         exit 1
#     else
#         FMapMagnitude="${Path}/${Subject}/${Session}/fmap/*_magnitude.nii.gz"
#     fi

# }
GetFieldMaps() {
    # create filenames for time series corresponding fieldmap acquisitions to use in processing
    # $1 fmri time series filename
    GetFMapTask() {
        # $1 phase difference filename
        tmp=$( basename ${1%.nii.gz})
        tmp=$( echo ${tmp%_part-phase_bold})
        tmpsplit=(${tmp//-/ })
        fmaptask=$( echo ${tmpsplit[2]})
    }
    _task=$( basename ${1%.nii.gz})
    PhaseFiles=( ${Path}/${Subject}/${Session}/fmap/*-phase_bold.nii*)
    if [[ ! -f ${PhaseFiles} ]]; then
    log_Msg "ERROR:    No phase difference image found in ${Path}/${Subject}/${Session}/fmap/."
        show_fmaps
    elif [[ ${#PhaseFiles[@]} -gt 1 ]]; then
        for pf in ${PhaseFiles[@]}; do
            GetFMapTask ${pf}
            if [[ "${_task}" == *"${fmaptask}"* ]]; then
                FMapPhaseDiff=${pf}
                FMapMagnitude="${Path}/${Subject}/${Session}/fmap/${Subject}_task-${fmaptask}_part-mag_concat_bold.nii.gz"
                ${FSLDIR}/bin/fslmerge -t \
                    ${FMapMagnitude} \
                    "${Path}/${Subject}/${Session}/fmap/${Subject}_task-${fmaptask}_part-1-mag_bold.nii.gz" \
                    "${Path}/${Subject}/${Session}/fmap/${Subject}_task-${fmaptask}_part-2-mag_bold.nii.gz"
            fi
        done
    else
        FMapPhaseDiff=${PhaseFiles}
        MagnitudeFiles=( ${Path}/${Subject}/${Session}/fmap/*-mag_bold.nii* )
        GetFMapTask $MagnitudeFiles
        FMapMagnitude="${Path}/${Subject}/${Session}/fmap/${Subject}_task-${fmaptask}-mag_concat_bold.nii.gz"
        ${FSLDIR}/bin/fslmerge -t \
            ${FMapMagnitude} \
            "${Path}/${Subject}/${Session}/fmap/${Subject}_task-${fmaptask}-part-1-mag_bold.nii.gz" \
            "${Path}/${Subject}/${Session}/fmap/${Subject}_task-${fmaptask}-part-2-mag_bold.nii.gz"
    fi
}

GetTimeSeriesName() {
    # extract time series base name
    tmp=$( basename ${1%.nii.gz})
    tmp=$( echo ${tmp%_bold} | rev)
    tmp=$( echo ${tmp%-ksat*} | rev)
    fmriname=$( echo ${tmp})
}

#############################################
#                                           #
#            CHECK ENVIRONMENT              #
#                                           #
#############################################

# parsing arguments
Path=`getopt1 "--path" $@`  # "$1" directory path containing all subjects
Subject=`getopt1 "--subject" $@`  # "$2" subject ID (e.g. 0001)
Session=`getopt1 "--session" $@`  # "$3" session ID (e.g. 01)
FMRITimeSeries=`getopt1 "--timeseries" $@`  # "$4" fmri time series to process


# check previous structural processing steps
if [[ ! -d "${Path}/${Subject}/${Session}/T1w" ]]; then
    log_Msg "ERROR:    T1w folder of previous processing steps. Please run structural processing before using FMRIPreProc.sh"
    exit 1
fi

if [[ -d "${Path}/${Subject}/${Session}/lesion" ]]; then
    log_Msg "UPDATE:    Lesion directory found. Running fMRI preprocessing using cost function masking."
fi

if [[ -z ${FMRITimeSeries} ]]; then
    log_Msg "ERROR:    No FMRI time series to process specified. Please check naming within ../func/ directory."
    exit 1
fi
#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################


GetTimeSeriesName ${FMRITimeSeries}

# get corresponding json file for parameter extraction
jsonfile=${FMRITimeSeries%.nii*}".json"
GetScanParameter ${jsonfile}
GetFieldMaps ${FMRITimeSeries}

log_Msg "START:    processing of time series: ${fmriname} volume"

${LEAPP_FUNCTDIR}/Scripts/GenericfMRIVolumeProcessingPipeline.sh \
    --path=${Path} \
    --subject=${Subject} \
    --session=${Session} \
    --fmriname=${fmriname} \
    --fmritcs=${FMRITimeSeries} \
    --fmriscout="NONE" \
    --SEPhaseNeg="NONE" \
    --SEPhasePos="NONE" \
    --fmapmag=${FMapMagnitude} \
    --fmapphase=${FMapPhaseDiff} \
    --fmapgeneralelectric="NONE" \
    --echospacing=$(echo ${DwellTime}) \
    --echodiff=2.46 \
    --unwarpdir=${PEdir} \
    --fmrires=$(echo ${Resolution}) \
    --dcmethod='SiemensFieldMap' \
    --gdcoeffs="NONE" \
    --topupconfig=${HCPPIPEDIR_Config}"/b02b0.cnf" \
    --printcom="" \
    --biascorrection="Legacy" \
    --mctype="MCFLIRT"

log_Msg "FINISHED:    processing of time series: ${fmriname} volume"

# log_Msg "FINISHED:   functional MRI preprocessing for ${Subject}"

