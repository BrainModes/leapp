#!/bin/bash
#

# # StructuralPipeline.sh
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
# * last update: 2023.01.31
#
#
#
# ## Description
#
# This script is performing structural processing of neuroimaging data.
# The pipeline is consisting of the three main components of the 
# Humman Connectome Project (HCP) pipeline (Glasser et al. 2013) as well as 
# lesion2tvb specific approaches.
#
# * 0. Cost mask creation
# * 1. Virtual Brain Transplant (VBT)
# * 2. PreFreeSurfer
# * 3. FreeSurfer 
# * 4. PostFreeSurfer 
# * 5. Parcellation mapping 
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
ParcName=`getopt1 "--atlas" $@`  # "$4" Atlas to use as parcellation for SC/FC computation
AllSteps=`getopt1 "--allsteps" $@` # $5 boolean if all processing steps should be performed
PreFSStep=`getopt1 "--prefs" $@` # $6 boolean if prefreesurfer is performed
FSStep=`getopt1 "--fs" $@` # $7 boolean if freesurfer is performed
PostFSStep=`getopt1 "--postfs" $@` # $8 boolean if postfreesurfer is performed
ParcMapping=`getopt1 "--parcmap" $@` # $9 boolean if atlas mapping is performed
MaskSpace=`getopt1 "--maskspace" $@` # $10 mask base space to use in creation of cost function masks
Lesion=`getopt1 "--lesion" $@` # $11 boolean whether to include lesion mask in processing

# Global
WD=${Path}/${Subject}/${Session}

# PostFreeSurfer
regname='MSMSulc'
grayordinatesres=2
lowresmesh=32


# define steps top be performed
if [[ ! -z ${AllSteps} ]]; then
    PreFSStep="True"
    FSStep="True"
    PostFSStep="True"
    ParcMapping="True"
fi

if [ ! -z ${Lesion} ]; then
    if [[ -z ${MaskSpace} ]]; then
        MaskSpace="T1w"
        log_Msg "IMPORTANT:    no mask space provided. Assuming default T1w space as basis for lesion mask."
    fi
fi
#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################


log_Msg "START:    structural processing for ${Subject} : ${Session}"
# setting pipeline parameters


#-------------------VBT & PREFREESRUFER-------------------#

# running PreFreeSurfer with default steps and templates

if [[ ! -z ${PreFSStep} ]]; then
    log_Msg "START:    PreFreeSurfer for ${Subject}"

    if [[ -d ${WD}"/T1w" ]]; then
        ResultDir="Structural_$( date +'%m_%d_%Y' )"
        log_Msg "WARNING:    Structural pipeline results found. Moving previous results into >>${ResultDir}<< folder."
        ResultDir="${Path}/${Subject}/${Session}/${ResultDir}"
        mkdir -p ${ResultDir}
        for source in "transplant" "T1w" "T2w" "MNINonLinear" "lesion" "parcellation"; do
            if [[ -d ${WD}/${source} ]]; then
                mv ${WD}/${source} \
                    ${ResultDir}/${source}
            fi
        done
    fi

    if [[ ! -f $( echo ${WD}/anat/${Subject}*T2*.ni* ) ]]; then
        if [[ ! -f $( echo ${WD}/anat/${Subject}*FLAIR.ni* ) ]]; then
            log_Msg "ERROR:    no T2 image or FLAIR image found. Please provide at least one. Recommended is a high resolution T2w."
            exit 1
        else
            log_Msg "UPDATE:    no T2 image found. Using provided FLAIR image as approximate to high resolution T2w image."
            cp ${WD}/anat/${Subject}_*FLAIR.nii* "${WD}/anat/${Subject}_flairproxy_T2.nii.gz"
            cp ${WD}/anat/${Subject}_*FLAIR.json "${WD}/anat/${Subject}_flairproxy_T2.json"
        fi
    fi

    ${LEAPP_STRUCTDIR}/Scripts/PreFreeSurferPipeline.sh \
        --path=${Path} \
        --subject=${Subject} \
		--session=${Session} \
        --t1=$( echo ${WD}/anat/${Subject}_*T1w.nii* ) \
        --t2=$( echo ${WD}/anat/${Subject}_*T2*.ni* ) \
        --flair=$( echo ${WD}/anat/${Subject}_*FLAIR.nii* ) \
        --t1template="${HCPPIPEDIR_Templates}/MNI152_T1_1mm.nii.gz" \
        --t1templatebrain="${HCPPIPEDIR_Templates}/MNI152_T1_1mm_brain.nii.gz" \
        --t1template2mm="${HCPPIPEDIR_Templates}/MNI152_T1_2mm.nii.gz" \
        --t2template="${HCPPIPEDIR_Templates}/MNI152_T2_1mm.nii.gz" \
        --t2templatebrain="${HCPPIPEDIR_Templates}/MNI152_T2_1mm_brain.nii.gz" \
        --t2template2mm="${HCPPIPEDIR_Templates}/MNI152_T2_2mm.nii.gz" \
        --templatemask="${HCPPIPEDIR_Templates}/MNI152_T1_1mm_brain_mask.nii.gz" \
        --template2mmmask="${HCPPIPEDIR_Templates}/MNI152_T1_2mm_brain_mask_dil.nii.gz" \
        --maskspace=${MaskSpace} \
        --lesioncorrect=${Lesion}
    
    log_Msg "FINISHED:    PreFreeSurfer for ${Subject} completed"
fi

#------------------------FREESRUFER-----------------------#

if [[ ! -z ${FSStep} ]]; then
    # running FreeSurfer using PreFreeSurfer results
    log_Msg "START:    FreeSurfer for ${Subject}"
    ${HCPPIPEDIR}/FreeSurfer/FreeSurferPipeline.sh \
        --subject=${Subject} \
        --subjectDIR=${WD}/T1w \
        --t1=${WD}/T1w/T1w_acpc_dc_restore.nii.gz \
        --t1brain=${WD}/T1w/T1w_acpc_dc_restore_brain.nii.gz \
        --t2=${WD}/T1w/T2w_acpc_dc_restore.nii.gz
        # ${HCPPIPEDIR}/FreeSurfer/FreeSurferPipeline.sh \
        # --subject=${Subject} \
        # --subjectDIR=${WD}/T1w \
        # --t1=${WD}/T1w/T1w_acpc_dc_restore.nii.gz \
        # --t1brain=${WD}/T1w/T1w_acpc_dc_restore_brain.nii.gz \
        # --t2=${WD}/T1w/T2w_acpc_dc_restore.nii.gz \
        # --flair
    log_Msg "FINISHED:    FreeSurfer for ${Subject} completed"
fi

#----------------------POSTFREESRUFER---------------------#

if [[ ! -z ${PostFSStep} ]]; then
    log_Msg "START:    PostFreeSurfer for ${Subject}"
    # running PostFreeSrufer
    ${LEAPP_STRUCTDIR}/Scripts/PostFreeSurferPipeline.sh  \
        --path=${Path} \
        --subject=${Subject} \
        --session=${Session} \
        --surfatlasdir=${HCPPIPEDIR_Templates}/standard_mesh_atlases  \
        --grayordinatesdir=${HCPPIPEDIR_Templates}/91282_Greyordinates \
        --grayordinatesres=${grayordinatesres:s} \
        --hiresmesh=164  \
        --lowresmesh=${lowresmesh:d} \
        --subcortgraylabels=${HCPPIPEDIR_Config}/FreeSurferSubcorticalLabelTableLut.txt \
        --freesurferlabels=${HCPPIPEDIR_Config}/FreeSurferAllLut.txt \
        --refmyelinmaps=${HCPPIPEDIR_Templates}/standard_mesh_atlases/Conte69.MyelinMap_BC.164k_fs_LR.dscalar.nii \
        --regname=${regname}  \
        --printcom=""
    
    if [[ -f "${Path}/${Subject}/${Session}/lesion/BaseImage.nii.gz" ]]; then
        ${LEAPP_STRUCTDIR}/Scripts/GetFinalT1wLesionMasks.sh \
            --path=${Path} \
            --subject=${Subject} \
            --session=${Session}
    fi
    log_Msg "END:    PostFreeSurfer for ${Subject} completed"
fi


#------------------PARCELLATION MAPPING-------------------#

if [[ ! -z ${ParcMapping} ]]; then
    log_Msg "START:    Mapping ${ParcName} to T1w for ${Subject}."
    # map HCP-MMP1 (default) parcellation to extracted structural subject T1w ribbon.
    ${LEAPP_STRUCTDIR}/Scripts/MapParcellation.sh \
        --path=${Path} \
        --sub=${Subject} \
        --session=${Session} \
        --parcellation=${ParcName}
    log_Msg "FINISHED:    Mapping ${ParcName} to T1w for ${Subject}."
fi




log_Msg "FINISHED:    structural processing for ${Subject} : ${Session}"
