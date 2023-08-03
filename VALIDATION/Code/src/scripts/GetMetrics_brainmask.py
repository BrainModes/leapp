#!/bin/python
#
# # GetMetrics_brainmask.py
#
# * Brain Simulation Section
# * Charité Berlin Universitätsmedizin
# * Berlin Institute of Health
#
# ## Author(s)
# * Bey, Patrik, Charité Universitätsmedizin Berlin, Berlin Institute of Health
# 
# 
#
# * last update: 2023.08.01
#
#
# This script is a wrapper for the functionality within the Validation container
# as used in (Bey et al., in prep.)
#
#
#




#############################################
#                                           #
#          AGREEMENT WRAPPER                #
#                                           #
#############################################

from utils.Utility import helper, io
from utils.AgreementMetrics import agreement
import os, sys, numpy, matplotlib.pyplot, nibabel, argparse, glob, multiprocessing

#############################################
#                                           #
#           HELPER FUNCTIONS                #
#                                           #
#############################################

def get_dict(path,_labels,_filename):
    '''
    create dictionary containing both group images for given subject 
    and corresponding filename for given mode
    '''
    import glob
    data = dict()
    for l in _labels:
        data[l] = io.get_nii(os.path.join(path,l,_filename)).get_fdata()
    return(data)


def get_data(path,labels,subjectlist):
    '''
    create dictionary for all subjects
    '''
    data = dict()
    for s in subjectlist:
        data[s] = get_dict(path,labels,s)
    return(data)

def get_mode_data(_dict):
    '''
    check mode compliange of data dictionary:
    if mode == global > binarize input data
    '''
    _index = list(_dict.keys())
    if len(list(numpy.unique(list( list(_dict.values())[0].values())[0]))) > 2:
        for i in _index:
            _fileidx = _dict[i].keys()
            for f in _fileidx:
                _dict[i][f] = numpy.where(_dict[i][f]!=0,1,0)
    return(_dict)

def get_subjectlist(path, _labels, _mode):
    '''
    extracting subject list for both groups and compare.

    ---
    input:
        path to group directories
        _labels to select groups
        _mode of processing volumes to include (e.g. 'FSL_WM')
    output:
        subjectlist of elements in both groups.
        Error if not same elements
    '''
    import glob, os, sys
    from utils.Utility import helper
    _list = dict()
    for l in _labels:
        # _list[l] = [ os.path.basename(item) for item in glob.glob(os.path.join(path, str(l)+'/*'+str(_mode)+'.nii.gz')) ]
        _list[l] = [ os.path.basename(item) for item in glob.glob(os.path.join(path, str(l)+'/*.nii.gz')) ]
    if _list[_labels[0]] != _list[_labels[1]]:
        mismatch = list(set(_list[_labels[0]]) - set(_list[_labels[1]]))
        mismatch.append( list(set(_list[_labels[1]]) - set(_list[_labels[0]])))
        helper.log_msg("ERROR:    unequal subjects in both groups. Please check before continuing.")
        helper.log_msg('ERROR:    files not present in both lists: '+str(mismatch))
        sys.exit()
    else:
        return(_list[_labels[0]])

#############################################
#                                           #
#              PARSE INPUT                  #
#                                           #
#############################################

parser = argparse.ArgumentParser(description='Performing mask based whole brain metrics computation.')
parser.add_argument("--path", help="Define input directory", type=str)
parser.add_argument("--labels", help="Define group labels for comparison", type = str)
parser.add_argument("--mode", help="Define imaging mode to compare", type = str)
parser.add_argument("--outdir", help="Define output directory", type = str)
args = parser.parse_args()

if not args.path:
    helper.log_msg('ERROR:    no input directory provided.')
    sys.exit()
else:
    Path = args.path

if not args.labels:
    helper.log_msg('ERROR:    no group labels for comparison provided.')
    sys.exit()
else:
    if ',' in args.labels:
        Labels = args.labels.split(',')
    elif ';' in args.labels:
        Labels = args.labels.split(';')
    else:
        Labels = args.labels.split(' ')



if not args.mode:
    helper.log_msg('ERROR:    no imaging mode for comparison provided.')
    sys.exit()
else:
    Mode = args.mode

if not args.outdir:
    helper.log_msg('UPDATE:    no output directory provided. Using default <<Path>> variable')
    OutDir = Path
else:
    OutDir = args.outdir



#############################################
#                                           #
#         DEFINE LOCAL VARIABLE             #
#                                           #
#############################################


SubjectList = get_subjectlist(Path, Labels, Mode)
#############################################
#                                           #
#         PERFORM COMPUTATIONS              #
#                                           #
#############################################

helper.log_msg("START:    Computing brainmask agreement measure.")

Data = get_data(Path, Labels, SubjectList)

if Mode == 'global':
    Data = get_mode_data(Data)

pool = multiprocessing.Pool(multiprocessing.cpu_count())

helper.log_msg("UPDATE:    Computing dice score agreement measure.")
DiceScores = numpy.array([ pool.apply(agreement.dice,args=(Data[s][Labels[0]],Data[s][Labels[1]])) for s in SubjectList ]).reshape([len(SubjectList),1])

helper.log_msg("UPDATE:    Computing jaccard score agreement measure.")
JaccardScores = numpy.array([ pool.apply(agreement.measure_jaccard,args=(Data[s][Labels[0]],Data[s][Labels[1]])) for s in SubjectList ]).reshape([len(SubjectList),1])

helper.log_msg("UPDATE:    Computing volume difference measure.")
VolumeDifference = numpy.array([ (numpy.sum(Data[s][Labels[0]]) - numpy.sum(Data[s][Labels[1]])) / numpy.sum(Data[s][Labels[0]]) for s in SubjectList ]).reshape([len(SubjectList),1])


Agreements = numpy.concatenate([DiceScores, JaccardScores, VolumeDifference], axis = 1)

numpy.savetxt(os.path.join(OutDir,'VolumeAgreementMeasures'+str(Mode)+'.txt'), Agreements, header = 'dice, measure_jaccard, measure_difference', delimiter = ',')
helper.log_msg("FINISHED:    Computing brainmask agreement measure.")
