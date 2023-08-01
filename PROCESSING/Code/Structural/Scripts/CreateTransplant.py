#!/bin/python
#
# # CreateTransplant.py
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
# * last update: 2020.12.09
#
#
#
# ## Description
#
# This script creates a transplant given the midline aligned input
# from VirtualBrainTransplant.sh.
# 
# * The following steps are performed:
# * 
# * 1. loading of mask / midline original image / midline mirror image
#
#
# ## Prerequisites
#
# * 1. VirtualBrainTransplant.sh steps must have been completed before running this script.


#############################################
#                                           #
#            LOAD LIBRARIES                 #
#                                           #
#############################################


import nibabel, os, numpy, sys, scipy.ndimage, argparse


#############################################
#                                           #
#            HELPER FUNCTIONS               #
#                                           #
#############################################



def get_nii(filename):
	nii = nibabel.load(filename)
	image = nii.get_fdata()
	return(nii,image)

def save_nii(image,origin,filename):
	Nii = nibabel.Nifti1Image(image, origin)
	Nii.to_filename(filename)

def get_border(img):
	'''
	extract the border of lesion mask via gradient computation
	'''
	grad = numpy.gradient(img)
	mag = numpy.sqrt(grad[0]**2 + grad[1]**2)
	mag[mag!=0] = 1
	return(mag)

def binarize(image):
    '''
    binarize image for more accurate gradient extraction for border plot.
    '''
    bin_image = numpy.where(image!=0,1,0)
    return(bin_image)


def get_smooth_mask(image, smoothing, _save = False):
    '''
    extract smooth mask for transition of healthy to lesioned tissue in VBT
    '''
    smimage = scipy.ndimage.gaussian_filter(image, float(smoothing))
    if _save:
        save_nii(smimage, MaskNii.affine, os.path.join(args.wd,'SmoothBorder.nii.gz'))
    maxvalue = numpy.max(smimage)
    smimage = numpy.where(image!=0,maxvalue,smimage)/maxvalue
    return(numpy.where(smimage<=.1,0,smimage))

def log_msg( _string):
    '''
    logging function printing date, scriptname & input string to stdout
    '''
    import datetime, os, sys
    print(f'{datetime.date.today().strftime("%a %B %d %H:%M:%S %Z %Y")} {str(os.path.basename(sys.argv[0]))}: {str(_string)}')





#############################################
#                                           #
#              PARSE INPUT                  #
#                                           #
#############################################

parser = argparse.ArgumentParser()
parser.add_argument("--wd", help="Define working directory.", default=os.environ.get('TempDir'))
parser.add_argument("--smoothing", help="Define sigma for smoothing kernel", default="2")
args = parser.parse_args()

# load image files
ImgNii, ImgMat = get_nii(os.path.join(args.wd,'OrigMidline.nii.gz'))
MirNii, MirMat = get_nii(os.path.join(args.wd, 'MirrorMidline.nii.gz'))
MaskNii, MaskMat =  get_nii(os.path.join(args.wd,'MaskMidline.nii.gz'))

#############################################
#                                           #
#            DO COMPUTATIONS                #
#                                           #
#############################################

log_msg('START:    create smooth brain transplant')

# log_Msg('UPDATE:    creating anatomically constrained transplant mask')
# EnMask = enhance_lesion_signal(ImgMat,MaskMat,_th=.1)


SmoothMask = get_smooth_mask(MaskMat,int(args.smoothing), _save = False)
# SmoothMask = get_smooth_mask(EnMask,sigma, _save = True)

MaskInverse = numpy.ones(numpy.shape(MaskMat))
MaskInverse = MaskInverse - binarize(SmoothMask)
save_nii(MaskInverse.astype('int32'), MaskNii.affine,os.path.join(args.wd,'VBTMaskInverse.nii.gz'))

SmoothMaskInverse = numpy.ones(numpy.shape(MaskMat))
SmoothMaskInverse = SmoothMaskInverse - SmoothMask
SmoothMaskInverse[SmoothMaskInverse==1] = 0

# save border processing steps
# save_nii(SmoothMask, MaskNii.affine,os.path.join(path,'SmoothMask.nii.gz'))
# save_nii(SmoothMaskInverse, MaskNii.affine,os.path.join(path,'SmoothMaskInverse.nii.gz'))

# define signal to transplant
Signal = (MirMat * SmoothMask)

# remove lesion tissue from image
HealthyBorder = (ImgMat * SmoothMaskInverse)

# save_nii(HealthyBorder.astype('int32'), MaskNii.affine,os.path.join(path,'healthyborder.nii.gz'))



# combine to create transplant image
Transplant = HealthyBorder + Signal

# save_nii(Healthy.astype('int32'), MaskNii.affine,os.path.join(path,'HealthyTissue.nii.gz'))
# save_nii(Signal.astype('int32'), MaskNii.affine,os.path.join(path,'SignalTissue.nii.gz'))

save_nii(Transplant.astype('int32'),MaskNii.affine,os.path.join(args.wd,'Transplant.nii.gz'))

log_msg('FINISHED:    create smooth brain transplant')
