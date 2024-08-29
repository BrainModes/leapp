#!/bin/python
#
# # GetROIMask.py
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
# * last update: 2024.08.27
#
#
# This script creates ROI nifit volumes for a given list
# of ROIs
#
#

#############################################
#                                           #
#        WORKSPACE PERPARATION              #
#                                           #
#############################################

import os, sys, numpy, nibabel, argparse


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


#############################################
#                                           #
#              PARSE INPUT                  #
#                                           #
#############################################

parser = argparse.ArgumentParser()
parser.add_argument("--rois", help="Define roi comma seperated list.", default='L_V1, L_V2')
parser.add_argument("--parcellation", help="Define parcellation volume.",default='/data/sub-P009/ses-1/parcellation/sub-P009_HCPMMP1_resample.nii.gz')
parser.add_argument("--lut", help="Define parcellation look-up table.", default='/opt/LeAPP-Templates/HCPMMP1_LUT_mrtrix.txt')

args = parser.parse_args()

#############################################
#                                           #
#            DO COMPUTATIONS                #
#                                           #
#############################################
log_msg(f'UPDATE:    Start extracting volume mask for ROIS: {args.rois}.')
LUT = numpy.genfromtxt(args.lut, dtype=str)

roi_list = list(args.rois.replace(" ","").split(','))
label_list = list(LUT[:,1])

subject = os.path.basename(args.parcellation).split('_')[0]

roi_idx = []
for r in roi_list:
    roi_idx.append([label_list.index(l)+1 for l in label_list if r in l])


parc_img = nibabel.load(args.parcellation)
parc_matrix = parc_img.get_fdata()
mask = numpy.zeros(parc_img.shape, dtype=numpy.float64)

for r in roi_idx:
    mask = mask + numpy.where(parc_matrix==r[0],1,0)

mask_nii = nibabel.Nifti1Image(mask, parc_img.affine)

nibabel.save(mask_nii, os.path.join(os.path.dirname(args.parcellation), f'{subject}_ROI-{args.rois}-mask.nii.gz'))

log_msg(f'UPDATE:    Finished extracting volume mask for ROIS: {args.rois}.')