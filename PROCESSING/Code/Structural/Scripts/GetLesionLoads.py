#!/bin/python
#

# # GetLesionROIs.py
#
#
# * Brain Simulation Section
# * Charite Berlin Universitaetsmedizin
# * Berlin Institute of Health
#
# ## Author(s)
# * Bey, Patrik, Charite Universitaetsmedizin Berlin, Berlin Institute of Health
# 
#
# * last update: 2022.11.01
#
#
#
# ## Description
#
# This script computes 'lesion load' for all affected ROIs based on
# final T1w lesion mask and parcellation volume.
#




#############################################
#                                           #
#            LOAD LIBRARIES                 #
#                                           #
#############################################


import nibabel , os, numpy, sys, argparse

#############################################
#                                           #
#            HELPER FUNCTIONS               #
#                                           #
#############################################

def get_nii(filename):
    '''
    loading nifti image and extracting numpy array
    '''
    nii = nibabel.load(filename)
    image = nii.get_fdata()
    return(nii,image)

def get_lookup(_filename):
    '''
    loading look up table into dictionary
    '''
    lut = dict(numpy.genfromtxt(_filename, dtype='str'))
    return(lut)

def get_lesion_rois(_maskimg, _parcimg):
    '''
    extract lesion affected rois as image matrix
    '''
    _roiimg = _maskimg.copy()
    # idx = numpy.where(_roiimg>=1)
    # _roiimg[idx] = _parcimg[idx]
    _roiimg = _roiimg * _parcimg
    # _rois = numpy.unique(_roiimg)[1:]
    return(_roiimg)

def check_cluster(_roiimg):
    '''
    check extracted ROIs for continuity and size. Disregard single voxels within different neighbouring voxels.
    Single voxels might represent false voxel classification during parcellation mapping.
    '''
    _roiimg_reduced = _roiimg.copy()
    rois = numpy.unique(_roiimg)[1:].astype(int)
    for i in rois:
        _idx = numpy.where(_roiimg == i)
        _size = len(_idx[0])
        if _size <= 5:
            if len(_idx[0]) == 1:
                log_msg("UPDATE:    Discarding single voxel lesion affected ROI "+str(i)+".")
                _roiimg_reduced[_idx] = 0
            else:
                _spread = 0
                for loc in numpy.arange(_size-1):
                    _spread = _spread + abs(_idx[0][loc] - _idx[0][loc+1])
                _spread = _spread / (_size-1)
                if _spread >=2:
                    log_msg("UPDATE:    Discarding non-continuous ROI "+str(i)+" with size "+str(_size)+" voxels.")
                    _roiimg_reduced[_idx] = 0
    return(_roiimg_reduced)


def get_size(id,img):
    '''
    extract size of roi <<id>> in img
    '''
    return(numpy.where(img==id)[0].shape[0])

def get_overview( _roiimg, _parcimg, _lut):
    '''
    extract lesion load for all ROIs
    '''
    import numpy
    _roilist=numpy.unique(_roiimg[_roiimg>0]).astype(int)
    _roiload = numpy.array([ get_size(r,_roiimg)/get_size(r,_parcimg) for r in _roilist]).reshape(-1,1)
    _roilabels = numpy.array([ _lut[str(r)] for r in _roilist]).reshape(-1,1)
    return(numpy.concatenate([_roilabels, _roiload], axis = 1))



def log_msg( _string):
    '''
    logging function printing date, scriptname & input string to stdout
    '''
    import datetime, os, sys
    print(datetime.date.today().strftime("%a %B %d %H:%M:%S %Z %Y") + " " + str(os.path.basename(sys.argv[0])) + ": " + str(_string))


#############################################
#                                           #
#              PARSE INPUT                  #
#                                           #
#############################################

parser = argparse.ArgumentParser()
parser.add_argument("--parcimage", help="Define parcellation image.")
parser.add_argument("--subject", help="Define subject ID.")
parser.add_argument("--maskimage", help="Define final T1w mask image")
parser.add_argument("--lut", help="Define lookup table.", default='/opt/LeAPP-Templates/HCPMMP1_LUT_mrtrix.txt')
args = parser.parse_args()


#############################################
#                                           #
#      CHECK INPUT / SET VARIABLES          #
#                                           #
#############################################


if not os.path.isfile(args.maskimage):
    log_msg("ERROR:    <<LesionImage>> not found. Please specify lesion mask to use.")
    sys.exit(1)


if not os.path.isfile(args.parcimage):
    log_msg("ERROR:    Parcellation image not found. Did you run MapParcellation.sh?")
    sys.exit(1)

if not os.path.isfile(args.lut):
    log_msg("ERROR:    Parcellation look up table not found.")
    sys.exit(1)


#-----------set local variables-----------#

OutputDir = os.path.dirname(args.maskimage)

LesionNii, LesionImg = get_nii(args.maskimage)
ParcNii, ParcImg = get_nii(args.parcimage)
Lut = get_lookup(args.lut)

#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################

log_msg('START:    Extracting lesion affected ROIs for '+ str(args.subject) )


# get lesion affected ROIs
roiimg = get_lesion_rois(LesionImg, ParcImg)

roiimg_check = check_cluster(roiimg)

Overview = get_overview(roiimg_check,ParcImg,Lut)


# save labels as .txt file
numpy.savetxt(os.path.join(OutputDir,'LesionAffectedROIs.txt'),
    Overview, fmt='%s', delimiter=',', newline='\n', header='ROI-label, Lesion load')

log_msg('FINISHED:    Extracting lesion affected ROIs for    '+ str(args.subject) )

