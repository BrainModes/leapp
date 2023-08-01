#!/bin/bash
#
#
# GetFiles.sh
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
# This script select the DWI files to use in diffusion processing pipeline.
# In the clinical context DWI acquisition often needs to restart resulting in multiple DWI 
# images with only partial data. To avoid this the largest .nii.gz file and the corresponding
# meta files are selected.

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
Path=`getopt1 "--path" $@`  # "$1"
Subject=`opts_GetOpt1 "--sub" $@` # "$2"
Session=`getopt1 "--session" $@`  # "$3" session ID (e.g. 01)

# check if files already defined in dwi_preprocessed folder
if [[ -f "${Path}/${Subject}/${Session}/dwi_preprocessed/${Subject}_DWI_raw.mif" ]]; then
    log_Msg "ERROR:    DWI raw image already present in dwi_preprocessed directory."
    exit 1
fi

log_Msg "START:    Finding valid DWI image files for ${Subject}"

filestrings="bvec bval json"
files=( ${Path}/${Subject}/${Session}/dwi/*dwi.nii* )

filelist=()

for f in ${files[@]}; do
    temp=${f: :-6}
    if [[ -f ${temp}'bvec' && -f ${temp}'bval' && -f ${temp}'json' ]]; then
        filelist+=( ${f} )
    fi
done

if [ -z ${filelist} ]; then
    log_Msg "ERROR:    No corresponding json/bvec/bval volumes found."
    exit 1
fi

nrniifiles="$( echo ${#filelist[@]} )"

if [ ${nrniifiles} -gt 0 ]; then
    niifinal="$( echo ${filelist[0]})"
    for f in ${filelist[@]}; do
        temp="$( stat --format=%s ${f} )"
        tempfinal="$( stat --format=%s ${niifinal} )"
        if [ "${temp}" -gt "${tempfinal}" ]; then
            niifinal=${f}
        fi
    done
fi

log_Msg "selecting ${niifinal} as valid DWI image file"

# creating relevant folder structure
if [[ ! -d "${Path}/${Subject}/${Session}/dwi_preprocessed" ]]; then
    mkdir "${Path}/${Subject}/${Session}/dwi_preprocessed"
fi

# selecting corresponding bvec / bval files
bvec="${niifinal: :-6}bvec"
bval="${niifinal: :-6}bval"
json="${niifinal: :-6}json"

#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################

# convert valid files into single .mif file
${MRTRIXDIR}/bin/mrconvert -force -fslgrad \
    ${bvec} \
    ${bval} \
    ${niifinal} \
    "${niifinal: :-6}mif" \
    -quiet

# move and rename files into dwi_preprocessed folder
mv "${niifinal: :-6}mif" "${Path}/${Subject}/${Session}/dwi_preprocessed/${Subject}_DWI_raw.mif"
cp ${json} "${Path}/${Subject}/${Session}/dwi_preprocessed/${Subject}_meta.json"


log_Msg "FINISHED:    Finding valid DWI image files for ${Subject}"
