#!/bin/bash
#
# # TVBReadyFileSelection.sh
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
# * last update: 2023.05.20
#
#
#
# ## Description
#
# This script creates TVB ready input files based on the created results from the lLeAPP pipeline.
#
# 
# The created file directory contains:
#     TVBReady
#         sub-{ID}
#             ses-{01}
#                 coords
#                     sub-{ID}_centers.txt
#                 lesion
#                     sub-{ID}_ROI_lesionload.txt
#                 net
#                     sub-{ID}_lengths.txt
#                     sub-{ID}_weights.txt
#                     sub-{ID}_{fmriname}_FC.tsv
#                 T1w
#                     sub-{ID}_T1w_final_brain.nii.gz
#                     sub-{ID}_T1w_final_lesion_mask.nii.gz
#                     sub-{ID}_LeAPP_parcellation.nii.gz
#                 ts
#                     sub-{ID}_{fmriname}_avg_ts.txt
#
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

# GetTempDir(){
# # create temporary directory
#     randID=$RANDOM
#     export TempDir="${1}/temp-${randID}"
#     mkdir ${TempDir}
# }

# GetTimeSeriesName() {
#     # extract time series base name
#     tmp=$( basename ${file%.txt})
#     tmp=$( echo ${tmp%_full} | rev)
#     taskname=$( echo ${tmp%_emotcennoClanoitcnuF} | rev)
# }

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
ParcName=`getopt1 "--atlas" $@`  # "$2"   Subject ID

if [[ ! -d "${Path}/${Subject}/${Session}/T1w" ]]; then
    log_Msg "ERROR:   no T1w folder found. Did you run structural processing?"
    exit 1
fi

if [[ ! -d "${Path}/${Subject}/${Session}/parcellation" ]]; then
    log_Msg "ERROR:   no parcellation folder found. Did you run parcellation mapping?"
    exit 1
fi

if [[ ! -d "${Path}/${Subject}/${Session}/connectome" ]]; then
    log_Msg "ERROR:   no connectome folder found. Did you run diffusion or functional pipeline?"
    exit 1
fi

if [[ -z "${ParcName}" ]]; then
    log_Msg "UPDATE:   no parcellation name provided. Using LeAPP adjusted HCPMMP1"
    ParcName="HCPMMP1"
fi

#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################

log_Msg "START:    creating TVB-Ready files and directory for ${Subject}."

TVBDir="${Path}/TVBReady/${Subject}/${Session}"

if [[ ! -d ${TVBDir} ]]; then
    mkdir -p "${TVBDir}"
    log_Msg "UPDATE:    Creating TVB file directory: ${TVBDir}."
fi



log_Msg "UPDATE:    getting network data"
mkdir -p "${TVBDir}/net"
cp "${Path}/${Subject}/${Session}/connectome/StructuralConnectome_lengths_lesion.csv" "${TVBDir}/net/${Subject}_lengths.tsv"
cp "${Path}/${Subject}/${Session}/connectome/StructuralConnectome_weights_lesion.csv" "${TVBDir}/net/${Subject}_weights.tsv"

FuncConFiles="${Path}/${Subject}/${Session}/connectome/*_FC.txt"
for fcf in ${FuncConFiles}; do
    cp ${fcf} "${TVBDir}/net/$( basename ${fcf%.txt}).tsv"
done

log_Msg "UPDATE:    getting functional timeseries"
mkdir -p "${TVBDir}/ts"

TimeSeriesFiles=$( find "${Path}/${Subject}/${Session}" -type f -name "*_avg_ts.txt" )

for tsf in ${TimeSeriesFiles}; do
    cp ${tsf} "${TVBDir}/ts/$( basename ${tsf} )"
done

TimeSeriesEventFiles=$( find "${Path}/${Subject}/${Session}/func" -type f -name "*_event.*" )
for tse in ${TimeSeriesEventFiles}; do
    cp ${tse} "${TVBDir}/ts/$( basename ${tse} )"
done

log_Msg "UPDATE:    getting processed T1w image and parcellation"
mkdir -p "${TVBDir}/T1w"

cp "${Path}/${Subject}/${Session}/T1w/T1w_acpc_dc_restore_brain.nii.gz" ${TVBDir}/T1w/${Subject}_T1w_final.nii.gz

cp "${Path}/${Subject}/${Session}/parcellation/${Subject}_${ParcName}_resample.nii.gz" "${TVBDir}/T1w/${Subject}_LeAPP_parcellation.nii.gz"

mkdir -p "${TVBDir}/coords"

python3 "${LEAPP_MISCDIR}/Scripts/GetParcellationCenters.py" \
    --path=${TVBDir} \
    --subject=${Subject} \
    --parcellation=${ParcName}



if [[ -d "${Path}/${Subject}/${Session}/lesion/" ]]; then
    log_Msg "UPDATE:    add pathology specific files"
    cp -r "${Path}/${Subject}/${Session}/phenotype" "${TVBDir}/phenotype"
    cp "${Path}/${Subject}/${Session}/lesion/T1w_acpc_dc_restore_mask.nii.gz" ${TVBDir}/T1w/${Subject}_T1w_final_lesion_mask.nii.gz
    cp "${Path}/${Subject}/${Session}/lesion/LesionAffectedROIs.txt" "${TVBDir}/phenotype/${Subject}_ROI_lesionload.txt"
fi




log_Msg "FINISHED:    creating TVB-Ready files and directory for ${Subject}."
