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
# * last update: 2023.07.26
#
#
#
# ## Description
#
# This script is a wrapper for the full functionality of the LeAPP processing
# pipeline as described in Bey et al. (2024)
#
# * The steps that can be performed are split in four main categories:
# *
# * 1. Structural processing
# * 2. Diffusion Weighted processing
# * 2.1. single subject computation
# * 2.2. population based computations
# * 3. Functional MRI processing
# * 4. TVB ready output curation
# *
#
# * 1. Structural processing
#
# The structural processing pipeline is the human connectome project (HCP) 
# minimal processing pipelie (Glasser et al.2013) 
# adjusted for use with lesioned brain data (Bey et al. (2024)).
# These adjustments include three major updates.
#
# 1.1 The automated creation of lesion mask in required reference spaces to use for 
# continued cost function masking when registering lesion affected volumes.
#
# 1.2 Virtual brain transplant (VBT) to create enantiomorphically corrected brain 
# images (following Solodkin et al. 2010).
#
# 1.3 Parcellation mapping is performed by transforming the extracted surface annotations 
# using provided brain atlas annotation files.
#
# * 2. Diffusion Weighted Imaging processing
#
# The provided pipeline for processing of Diffusion weighted imaging data to create structural connectomes.
# The semi automated pipeline performs mutliple steps switching from single subject to population based computations and needs to be initiated multiple times to run the full pipeline with different initial conditions. For a full description see documentation.
# 
# * 3. Functional MRI processing
#
# The functional MRI processing consists the fmri volume based processing pipeline 
# from the HCP processing pipeline (Glasser ar al. 2013)
# and the creation of Functional Connectomes using ROI based average time series and the created 
# surface bsed volume parcellation from structural processing.
# *
# *
# *
# *




#############################################
#                                           #
#            CHECK ENVIRONMENT              #
#                                           #
#############################################


if [ -z "${HCPPIPEDIR}" ]; then
	echo "ERROR: HCPPIPEDIR environment variable must be set"
	exit 1
fi

if [ -z "${FSLDIR}" ]; then
	echo "ERROR: FSLDIR environment variable must be set"
	exit 1
fi

if [ -z "${HCPPIPEDIR_Global}" ]; then
	echo "ERROR: HCPPIPEDIR_Global environment variable must be set"
	exit 1
fi

if [ -z "${HCPPIPEDIR_PreFS}" ]; then
	echo "ERROR: HCPPIPEDIR_PreFS environment variable must be set"
	exit 1
fi

if [ -z "${FREESURFER_HOME}" ]; then
	echo "ERROR: FREESURFER_HOME environment variable must be set"
	exit 1
fi

if [ -z "${LEAPP_TEMPLATES}" ]; then
	echo "ERROR: LEAPP_TEMPLATES environment variable must be set"
	exit 1
fi

if [ -z "${LEAPP_STRUCTDIR}" ]; then
	echo "ERROR: LEAPP_STRUCTDIR environment variable must be set"
	exit 1
fi

if [ -z "${LEAPP_FUNCTDIR}" ]; then
	echo "ERROR: LEAPP_FUNCTDIR environment variable must be set"
	exit 1
fi

if [ -z "${LEAPP_DWIDIR}" ]; then
	echo "ERROR: LEAPP_DWIDIR environment variable must be set"
	exit 1
fi

if [ -z "${LEAPP_MISCDIR}" ]; then
	echo "ERROR: LEAPP_MISCDIR environment variable must be set"
	exit 1
fi

if [ -z "${MRTRIXDIR}" ]; then
	echo "ERROR: MRTRIXDIR environment variable must be set"
	exit 1
fi

# if [ -z "${ANTSDIR}" ]; then
# 	echo "ERROR: ANTSDIR environment variable must be set"
# 	exit 1
# fi




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

#-------loading I/O & logging functionality-------#
source ${HCPPIPEDIR}/global/scripts/log.shlib  # Logging related functions
source ${HCPPIPEDIR}/global/scripts/opts.shlib # Command line option functions



contains() {
	[[ ${Steps} =~ (^|[[:space:]])${1}($|[[:space:]]) ]] && echo 'True' || echo ''
}

CheckExit() {
    if [[ $( echo $? ) -eq 1 ]]; then
        log_Msg "ERROR:    previous processing step $( basename ${1}) did not complete."
        exit 1
    fi
}

show_usage() {
	cat <<EOF

***     LESION AWARE PROCESSING PIPELINE (LeAPP)     ***

Usage: docker run -e <OPTION>=<VALUE> -v </PATH/TO/STUDYFOLDER>:/data 

-e SubID=<string>		Subject ID to use in pipeline 
							[required - integer]
-e Path=<path>			Path variable to study folder 
								[optional ; default : "/data" mounted volume to container via << -v >> option.]
-e SesID=-<string>		Session ID to use in pipeline
								[optional ; defaul : 01 ]
-e Steps=<string>		Processing steps to perform in run call.  [required]
							Space delimited list of steps and options. 
							Possible options: 
							<full>: Running all processing steps up to preprocessed DWI images.

							<vbt>: Only perform Virtual Brain Transplant

							<lesion>: boolean parameter whether to include lesion processing. 
										[not needed e.g. for processing of healthy controls]

							<nocleanup>: boolean whether to clean up temporary files

							<structural>: Perform structural processing steps [T1w & T2w image required]
								-possible substeps:
								<all>          : running all structural processing steps.
								<prefs>        : running only adjusted PreFreeSurfer steps.
								<fs>           : running only FreeSurfer steps. Requires
												"prefs" to be run before.
								<postfs>       : running only PostFreeSurfer steps. Requires 
													"prefs" and "fs" to be run before.
								<parcmap> : mapping of brain parcellation template to T1w extracted ribbon.
							
							<functional>: Perform fMRI processing [requires structural processing results]
								-possible substeps:
								<all>			: running all functional processing steps.
								<preproc>		: running HCP based volume processing
								<connectome>	: running connectome creation using average time series.
								<fmrifiles>     : file names for fmri time series to process [optional; default: all volumes found in <<./func>> directory.]
								<onsets>		: boolean if experimental design task onsets file to be used vs full time series [e.g. for the case of resting-state fMRI].

							<dwi>: Perform diffusion weighted imaging processing
								-possible substeps:
								<preproc>		: running all subject specific preprocessing steps.
								<normal>		: running population based intensity normalization.
								<segment>		: running 5 tissue type segmentation based on processed T1w image. Optional parameter:
								<response>		: running population based response function normalization.
								<connectome>	: running connectome creation with optional lesion embedding.
							
							<tvb>: Get minimally required TVB files for simulation and reformat. [currently not supported]

-e Atlas=<string>		Parcellation to use in SC creation [optional]
								[default : HCP-MMP1]

-e Streams=<integer>		Number of streamlines to compute in tractography [optional; default: 100Mio traces]								
							
-e MaskSpace=<string>	Basis space of provided lesion mask volume. [default: T1w]
							Possible <parameter>:
							<T1w>				: created lesion mask is based on T1w image
							<T2w>				: created lesion mask is based on T2w image
							<MNI>				: created lesion mask is based on MNI image
							<FLAIR>				: created lesion mask is based on FLAIR image

-e Image=<filepath>		VBT Input image filename relative to '${Path}'

-e Mask=<filepath>			VBT Input mask filename relative to '${Path}'

-e SmoothingFactor=<int>	Smoothing factor for use in Gaussian Kernel during virtual brain transplant

-e LesionEmbed=<string>   : type of lesion embedding in 5tt segmentation; possible versions <<mrtrix, experimental>> (see documentation for details).

-e VariableName=<Parameter>  If additional global parameter are added they can be 
							 called this way. (currently not supported)

EOF
	exit 1
}



#############################################
#                                           #
#            CHECK INPUT                    #
#                                           #
#############################################
#
# Check for provided input variables and exit for required 
# parameters or set default for optional parameter.
#
log_Msg "START:    performing following steps: ${Steps} for subject: sub-${SubID} for ${Session}"


#-----------------general input-------------------#
if [[ -z ${Steps} ]]; then
	log_Msg "ERROR:    No <<Steps>> variable defined. Please specify processing steps to perform."
	show_usage
	exit 1
fi

if [[ -z ${Path} ]]; then
	if [[ -d "/data" ]]; then
		Path="/data"
		log_Msg "UPDATE:    using '/data' directory as input directory."
	else
		log_Msg "ERROR:    No <<Path>> variable defined and no '/data' volume mounted with docker image. Please specify a study directory."
		show_usage
		exit 1
	fi
fi

if [[ -z ${SubID} ]]; then
	log_Msg "ERROR:    No  <<SubID>>. variable defined. Please specify a subject ID"
	show_usage
	exit 1
else
	SubID="sub-${SubID}"
fi

if [[ -z ${SesID} ]]; then
 	log_Msg "UPDATE:    no session <<SesID>> provided, using default 'ses-01' for processing"
	export SesID="ses-01"
 else
 	export SesID="ses-${SesID}"
 	log_Msg "UPDATE:    processing session <<${SesID}>>"
fi

if [[ -z ${Atlas} ]]; then
	Atlas="HCPMMP1"
	log_Msg "INFO:    Using HCP-MMP1 as default brain parcellation to map to subject space for cortical ROIs in connectome creation."
fi

if [[ ! -z "$( contains "nocleanup")" ]]; then
	export NOCLEANUP="True"
	log_Msg "IMPORTANT:     Not performing clean up to temporary directories."
fi

# LogDir="${Path}/log"
# [[ ! -d ${LogDir} ]] && mkdir -p ${LogDir}

#-----------------processing steps-------------------#

if [[ ! -z "$( contains "lesion")" ]]; then
	LESION="True"
	log_Msg "IMPORTANT:    Running lesion based processing. Pipeline expects '${SubID}_*_lesion_mask.nii.gz' file in anat subject folder."
	if [[ -z ${SmoothingFactor} ]]; then
		export SmoothingFactor="2"
		log_Msg "UPDATE:    Using default smoothing parameter sigma=${SmoothingFactor} during virtual brain transplant."
	fi
fi

if [[ ! -z "$( contains "full")" ]]; then
	export STRUCT="True"
	export STRUCTALL="True"
	export DWI="True"
	export FUNCT="True"
    export TVBREADY="True"
	log_Msg "IMPORTANT:   the pipeline only performs diffusion preprocessing for a single subject. Additional steps require population information. For more information see full documentation."
else
	for s in $Steps; do
		if [[ "${s}" = "functional" ]]; then
			FUNCT="True"
		fi
		if [[ "${s}" = "structural" ]]; then
			STRUCT="True"
		fi
		if [[ "${s}" = "dwi" ]]; then
			DWI="True"
		fi
		if [[ "${s}" = "vbt" ]]; then
			VBT="True"
		fi
		if [[ "${s}" = "tvb" ]]; then
			TVBREADY="True"
		fi
	done
fi


# check for specific stages of structural processing
if [ ! -z ${STRUCT} ]; then
	check="$( contains "prefs")"
	structprefs=${check}
	check="$( contains "fs")"
	structfs=${check}
	check="$( contains "postfs")"
	structpostfs=${check}
	check="$( contains "parcmap")"
	structparc=${check}
# check if processing step is defined
	if [[ -z ${structprefs} ]] && [[ -z ${structfs} ]] && [[ -z ${structpostfs} ]] && [[ -z ${structparc} ]]; then
		log_Msg "UPDATE:    performing full structural processing pipeline."
		STRUCTALL="True"
	fi
fi


#----------------diffusion steps-------------------#

# check for specific stage of dwi processing
if [ ! -z ${DWI} ]; then
	check="$( contains "preproc")"
	dwipreproc=${check}
	check="$( contains "normal")"
	dwinormal=${check}
	check="$( contains "segment")"
	dwisegment=${check}
	check="$( contains "response")"
	dwiresponse=${check}
	check="$( contains "connectome")"
	dwiconnect=${check}
	if [[ -z ${dwipreproc} ]] && [[ -z ${dwinormal} ]] && [[ -z ${dwisegment} ]] && [[ -z ${dwiresponse} ]] && [[ -z ${dwiconnect} ]]; then
		log_Msg "ERROR:    Please specify a processing step for diffusion processing"
		show_usage
		exit 1
	fi
fi

#----------------functional processing-------------------#

#c heck for specific stages of functional processing

if [[ ! -z ${FUNCT} ]]; then
	check="$( contains "preproc")"
	export functpreproc=${check}
	check="$( contains "connectome")"
	export functconnect=${check}
	check="$( contains "onsets")"
	export functonset=${check}
	check="$( contains "all")"
	export FUNCTALL=${check}
	if [[ -z ${functpreproc} ]]; then
		if [[ -z ${functconnect} ]]; then
			if [[ -z ${FUNCTALL} ]]; then
				log_Msg "ERROR:    Please specify a processing step for functional processing"
				show_usage
				exit 1
			fi
		fi
	fi
fi



#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################




#--------------virtual brain transplant------------------#

if [[ ! -z ${VBT} ]]; then
	${LEAPP_STRUCTDIR}/RunVBT.sh \
		--path=${Path} \
		--subject=${SubID} \
		--session=${SesID} \
		--image=${Image} \
		--mask=${CostMask} \
		--nocleanup=${NOCLEANUP}
	
	CheckExit ${LEAPP_STRUCTDIR}/RunVBT.sh
fi


#----------------strucutural processing-------------------#

if [ ! -z ${STRUCT} ]; then
	${LEAPP_STRUCTDIR}/StructuralPipeline.sh \
		--path=${Path} \
		--subject=${SubID} \
		--session=${SesID} \
		--atlas=${Atlas} \
		--allsteps=${STRUCTALL} \
		--prefs=${structprefs} \
		--fs=${structfs} \
		--postfs=${structpostfs} \
		--parcmap=${structparc} \
		--maskspace=${MaskSpace} \
		--lesion=${LESION}
	
	CheckExit ${LEAPP_STRUCTDIR}/StructuralPipeline.sh

fi



#----------------diffusion processing-------------------#

if [ ! -z ${DWI} ]; then
	${LEAPP_DWIDIR}/DiffusionPipeline.sh \
		--path=${Path} \
		--subject=${SubID} \
		--session=${SesID} \
		--atlas=${Atlas} \
		--preproc=${dwipreproc} \
		--normal=${dwinormal} \
		--segment=${dwisegment} \
		--response=${dwiresponse} \
		--connectome=${dwiconnect} \
		--lesion=${LESION} \
		--streams=${Streams}
	
	CheckExit ${LEAPP_DWIDIR}/DiffusionPipeline.sh

fi



#----------------strucutural processing-------------------#

if [ ! -z ${FUNCT} ]; then
	${LEAPP_FUNCTDIR}/FunctionalPipeline.sh \
		--path=${Path} \
		--subject=${SubID} \
		--session=${SesID} \
		--atlas=${Atlas} \
		--allsteps=${FUNCTALL} \
		--preproc=${functpreproc} \
		--connectome=${functconnect} \
		--onsets=${functonset}
	
	CheckExit ${LEAPP_FUNCTDIR}/FunctionalPipeline.sh
fi


# #-----------------tvb file selection---------------------#

if [ ! -z ${TVBREADY} ]; then
	${LEAPP_MISCDIR}/TVBReadyFileSelection.sh \
		--path=${Path} \
		--subject=${SubID} \
		--session=${SesID} \
		--atlas=${Atlas}
	
	CheckExit ${LEAPP_MISCDIR}/TVBReadyFileSelection.sh
fi

log_Msg "FINISHED:    performing following steps: ${Steps} for subject: sub-${SubID} for ${Session}"
