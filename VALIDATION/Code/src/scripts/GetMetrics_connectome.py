#!/bin/python
#
# # GetMetrics_connectome.py
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

def get_dict(path,labels,_filename):
    '''
    create dictionary containing both group images for given filename
    '''
    import glob
    data = dict()
    for l in labels:
        data[l] = io.get_connectome(os.path.join(path,l,_filename))
        # data[l] = io.get_connectome(glob.glob(os.path.join(path,l,id)+'/'+str(id)+'*'+str(mode)+'.*')[0])
    return(data)

def get_data(path,labels,subjectlist):
    '''
    create dictionary for all subjects
    '''
    data = dict()
    for s in subjectlist:
        data[s] = get_dict(path,labels,s)
    return(data)

def get_subjectlist(path, _labels, _connectome):
    '''
    extracting subject list for both groups and compare.

    ---
    input:
        path to group directories
        _labels to select groups
        _connectome naming to load for computations (e.g. 'FC')
    output:
        subjectlist of elements in both groups.
        Error if not same elements
    '''
    import glob, os, sys
    from utils.Utility import helper
    _list = dict()
    for l in _labels:
        _list[l] = [ os.path.basename(item) for item in glob.glob(os.path.join(path, str(l)+'/*'+str(_connectome)+'.*')) ]
    if not bool(_list[l]):
        helper.log_msg("ERROR:    No files found. Please check naming.")
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

parser = argparse.ArgumentParser()
parser.add_argument("--path", help="Define input directory")
parser.add_argument("--labels", help="Define group labels for comparison")
parser.add_argument("--connectome", help="Define connectome name")
parser.add_argument("--outdir", help="Define output directory")
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


if not args.connectome:
    helper.log_msg('UPDATE:    no connectome name provided. Using default "FC"') 
    Connectome = "FC"
else:
    Connectome = args.connectome

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

SubjectList = get_subjectlist(Path, Labels, Connectome)



MeasureList = ['measure_hausdorff','measure_pearson']


#############################################
#                                           #
#         PERFORM COMPUTATIONS              #
#                                           #
#############################################

helper.log_msg("START:    Computing network based agreement measures.")



Data = get_data(Path, Labels, SubjectList)


Metrics = numpy.zeros([len(SubjectList),len(MeasureList)])

for s in SubjectList:
    for method in MeasureList:
        Metrics[SubjectList.index(s),MeasureList.index(method)] = getattr(agreement,method)(Data[s][Labels[0]],Data[s][Labels[1]])


numpy.savetxt(os.path.join(OutDir,'NetworkAgreementMeasures_'+str(args.labels)+'_'+str(Connectome)+'.txt'), Metrics, header = str(MeasureList), delimiter = ',')


helper.log_msg("FINISHED:    Computing network based agreement measures.")

