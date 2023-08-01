#!/bin/bash
#
#
#
# # FMRIRegStructT1w.sh
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
# This scripts performs registartion of one step resampled fMRI 
# volume in MNI space to T1w_acpc_dc_restore space 
# for connectome creation.
#
# The follwoing steps are performed:
#
# * 1..Register original T1w space to corrseponding downsampled T1w output from FMRIPreProc.sh
# * 2. invert transformation
# * 3. apply inverste transformation to full fMRI image




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


WD="${Path}/${Subject}/${Session}/${TaskName}"
GetTempDir ${WD}


if [[ ! -d "${Path}/${Subject}/${Session}/MNINonLinear/Results/${TaskName}" ]]; then
    log_Msg "ERROR:    Corresponding results folder ${WD} missing. Did you run FMRIPreProc.sh before?"
    exit 1
fi

if [[ -z ${TaskName} ]]; then
    log_Msg "ERROR:    No fMRI task specified. Please define >>fmriname<< variable."
    exit 1
fi




# Get WPI input image
TargetImage="${Path}/${Subject}/${Session}/T1w/T1w_acpc_dc_restore_brain.nii.gz"
TargetMask="${Path}/${Subject}/${Session}/lesion/T1w_acpc_dc_restore_mask_invert.nii.gz"
RefImage="${WD}/OneStepResampling/T1w_restore.3.nii.gz"
RefBrainMask="${WD}/OneStepResampling/brainmask_fs.3.nii.gz"
EPIImage="${Path}/${Subject}/${Session}/MNINonLinear/Results/${TaskName}/${TaskName}"

#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################

log_Msg "START:    Registering EPI image to T1w subject space for ${Subject} for ${TaskName}."



#---brain extraction using brainmask
${FSLDIR}/bin/fslmaths \
    ${RefImage} \
    -mas ${RefBrainMask} \
    "${WD}/OneStepResampling/T1w_restore.3_brain.nii.gz"

RefImage="${WD}/OneStepResampling/T1w_restore.3_brain.nii.gz"

#---Registering TargetImage to EPI space

if [[ -f ${TargetMask} ]]; then
    log_Msg "UPDATE:    Registration using cost function masking."
    ${FSLDIR}/bin/flirt -dof 12 -interp spline \
        -in ${TargetImage} \
        -inweight ${TargetMask} \
        -ref ${RefImage} \
        -omat "${TempDir}/T1w2EPI.mat" \
        -out "${TempDir}/T1w2EPI.nii.gz"
else
    log_Msg "UPDATE:    Registration without cost function masking."
    ${FSLDIR}/bin/flirt -dof 12 -interp spline \
        -in ${TargetImage} \
        -ref ${RefImage} \
        -omat "${TempDir}/T1w2EPI.mat" \
        -out "${TempDir}/T1w2EPI.nii.gz"
fi


#---Inverting transformation matrix

${FSLDIR}/bin/convert_xfm \
    "${TempDir}/T1w2EPI.mat" \
    -inverse \
    -omat "${TempDir}/EPI2T1w.mat"


#---Applying transformation to EPI time series volume
log_Msg "UPDATE:    Applying registration to EPI volume."
${FSLDIR}/bin/flirt -applyxfm -usesqform \
    -interp nearestneighbour \
    -init "${TempDir}/EPI2T1w.mat" \
    -in ${EPIImage} \
    -ref ${TargetImage} \
    -out "${WD}/${Subject}_task-${TaskName}_T1w.nii.gz"


# Clean up of temporary directories
if [[ -z ${NOCLEANUP} ]]; then
    log_Msg "UPDATE:    Removing temporary directory ${TempDir}"
    rm -r ${TempDir}
fi


log_Msg "FINISHED:    Registering EPI image to T1w subject space for ${Subject} for ${TaskName}."
