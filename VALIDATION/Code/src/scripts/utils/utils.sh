#!/bin/bash
#
# # Utils.sh   
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
# This script is wrapper for bash utility functions used within
# Validation framework as used in (Bey et al. in prep.).


log_msg() {
    # print out text for logging
    # adjust color scheme for warnings/error messages
    # usage: log_msg "TYPE:    message"
    _nc='\033[0m' # No Color
    _type=$( echo ${1} | cut -d':' -f1 )
    _message=$( echo ${1} | cut -d':' -f2 )
    if [ ${_type} == "WARNING" ] ; then
        _col='\033[0;33m'
    elif [ ${_type} == "ERROR" ] ; then
        _col='\033[0;31m'
    else
        _col='\033[0;32m'
    fi
    echo -e "$(date) $(basename  -- "$0") : ${_col}${_type}${_nc}${_message}"
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