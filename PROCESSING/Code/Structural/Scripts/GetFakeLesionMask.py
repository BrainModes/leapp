#!/bin/python
#
# # GetFakeLesionMask.py
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
# This script creates fake lesion masks for healthy brain volumes
# to enable group level comparison while avoiding asymemtrical application of
# cost function masking (See CFM validation, FENS Forum 2022, Abstract, Bey et al.)
#
#

#############################################
#                                           #
#        WORKSPACE PERPARATION              #
#                                           #
#############################################

import os, sys, numpy, matplotlib.pyplot, nibabel, argparse, glob


#############################################
#                                           #
#           HELPER FUNCTIONS                #
#                                           #
#############################################

def log_msg( _string):
    '''
    logging function printing date, scriptname & input string to stdout
    '''
    import datetime, os, sys
    print(datetime.date.today().strftime("%a %B %d %H:%M:%S %Z %Y") + " " + str(os.path.basename(sys.argv[0])) + ": " + str(_string))

def get_fake_masks(_img, _filename):
    '''
    create fake lesion mask for all reference images used during registration
    '''
    import nibabel, numpy
    _nii = nibabel.load(_img)
    _fakemask = numpy.zeros(_nii.get_fdata().shape)
    _fakemask[:10,:10,:10] = 1
    _fakemasknii = nibabel.Nifti1Image(_fakemask, _nii.affine)
    _fakeinvert = numpy.ones(_fakemask.shape)
    _fakeinvert = _fakeinvert - _fakemask
    _fakeinvertnii = nibabel.Nifti1Image(_fakeinvert, _nii.affine)
    nibabel.save(_fakemasknii, f"{_filename}.nii.gz")
    nibabel.save(_fakeinvertnii, f"{_filename}_invert.nii.gz")

#############################################
#                                           #
#              PARSE INPUT                  #
#                                           #
#############################################

parser = argparse.ArgumentParser()
parser.add_argument("--path", help="Define input directory.", default='/data')
parser.add_argument("--subject", help="Define subject ID.")
parser.add_argument("--maskspace", help="Define mask space for input images.")
parser.add_argument("--templatedir", help="Define dorectory containing FSL templates.", default='/opt/HCP-Pipelines/global/templates/')
args = parser.parse_args()

Range = 10 #define search range from center inwards hemisphere for fake lesion idetnfication


log_msg("START:    creating fake lesion masks.")

if not args.path:
    log_msg('ERROR:    no input directory provided.')
    sys.exit()
else:
    Path = args.path

WD=os.path.join(args.path, args.subject, 'lesion')
if not os.path.isdir(WD):
    os.mkdir(WD)

if not os.path.isfile(os.path.join(os.path.join(args.path, args.subject, 'anat'),f'{args.maskspace}_lesion_mask.nii.gz')):
    log_msg('UPDATE:    no lesion mask found, creating fake lesion mask for CFM.')
else:
    log_msg('ERROR:    lesion mask found, preceeding as normal.')
    sys.exit()    



# Define base images for lesion mask creation
T1wInputImage=glob.glob(os.path.join(args.path, args.subject, 'anat',f"{args.subject}_*_T1w.nii.gz"))[0]
T2wInputImage=glob.glob(os.path.join(args.path, args.subject, 'anat',f"{args.subject}_*_T2*.nii.gz"))[0]
MNITemplate=os.path.join(args.templatedir,"MNI152_T1_1mm.nii.gz")
MNITemplate2mm=os.path.join(args.templatedir,"MNI152_T1_2mm.nii.gz")



log_msg("UPDATE:    creating T1w fake lesion mask")
get_fake_masks(T1wInputImage, os.path.join(WD,'T1w_lesion_mask'))

log_msg("UPDATE:    creating T2 fake lesion mask")
get_fake_masks(T2wInputImage, os.path.join(WD,'T2w_lesion_mask'))

log_msg("UPDATE:    creating MNI fake lesion masks")
get_fake_masks(MNITemplate, os.path.join(WD,'MNI_lesion_mask'))
get_fake_masks(MNITemplate2mm, os.path.join(WD,'MNI2mm_lesion_mask'))

log_msg("FINISHED:    creating fake lesion masks.")

