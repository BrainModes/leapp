#!/bin/python
#
# GetParcellationCenters.py
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
# This script extracts center of gravity coordinates for each ROI
# in a given parcellation image and the corresponding look-up table
#
#
#
#############################################
#                                           #
#            CLASS DEFINTIONS               #
#                                           #
#############################################

class helper:
    '''
    Class object for helper functions includding progressbars, logging etc.
    '''
    import datetime, os, sys, numpy
    def __init__(self):
        '''
        initializing class object
        '''
    def log_msg(_string):
        '''
        logging function printing date, scriptname & input string to stdout
        '''
        import datetime, sys
        print(datetime.date.today().strftime("%b-%d-%Y") + " - " + str(sys.argv[0]) + ": " + str(_string))

class io:
    '''
    input/output helper class
    '''
    def __init__(self):
        '''
        initializing class object
        '''
    def load_table( _path, _del = None):
        '''
        load space seperated .txt file into numpy array
        '''
        import numpy
        if not _del:
            _del = ';'
        return(numpy.genfromtxt(_path, delimiter= _del, skip_header=0, dtype = str))
    def get_image(name):
        '''
        load ifit image
        '''
        import nibabel
        return(nibabel.load(name))

def get_center(_array, _index):
    '''
    extract center of gravity coordinates for given parcellation index (e.g. ROI)
    '''
    import numpy
    return(numpy.mean(numpy.where(_array==_index),axis = 1).astype(int))


#############################################
#                                           #
#            CHECK INPUT                    #
#                                           #
#############################################
import os, numpy, argparse, nibabel
import warnings
warnings.filterwarnings("ignore")

parser = argparse.ArgumentParser()
parser.add_argument("--path", help="Define study folder.",default='/data/TVBReady')
parser.add_argument("--subject", help="Define subject")
parser.add_argument("--session", help="Define subject")
parser.add_argument("--parcellation", help="Define parcellation name used.", default='HCPMMP1')
args = parser.parse_args()

#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################

helper.log_msg(f'START:    Creating ROI center of gravity file for {args.subject}.')


parcimage = os.path.join(args.path,'T1w',f'{args.subject}_LeAPP_parcellation.nii.gz')
lut = os.path.join(os.environ.get('LEAPP_TEMPLATES'),f'{args.parcellation}_LUT_mrtrix.txt')

Img = io.get_image(parcimage).get_fdata().astype(int)
Lut = io.load_table(lut, _del = '\t')

center_idx = numpy.array([ get_center(Img,int(r)) for r in Lut[:,0] ])

Centers = numpy.concatenate([Lut[:,1].reshape(-1,1),center_idx], axis = 1)

CenterCheck = numpy.where(numpy.sum(center_idx, axis =1)<=0)[0]

if CenterCheck.any():
    helper.log_msg(f'WARNING:    empty ROIs found in parcellation image. ROIs: {Lut[CenterCheck,:]}')


numpy.savetxt(os.path.join(args.path,'coords',f'{args.subject}_centers.txt'), Centers, delimiter = ' ', fmt="%s")


helper.log_msg(f'FINISHED:    Creating ROI center of gravity file for {args.subject}.')
