#!/bin/python
#
# # GetNetworkMetrics.py
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
#        NETWORK METRICS WRAPPER            #
#                                           #
#############################################

from utils.Utility import *
from utils.NetworkMetrics import *
import os, sys, numpy, matplotlib.pyplot, nibabel, argparse, glob, multiprocessing


#############################################
#                                           #
#           HELPER FUNCTIONS                #
#                                           #
#############################################

def get_dict(path,labels,_filename):
    '''
    create dictionary containing both group images for given subject ID
    '''
    import glob
    data = dict()
    for l in labels:
        data[l] = io.get_connectome(os.path.join(path,l,_filename))
    return(data)

def get_data(path,labels,subjectlist):
    '''
    create dictionary for all subjects
    '''
    data = dict()
    for s in subjectlist:
        data[s] = get_dict(path,labels,s)
    return(data)

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
        _list[l] = [ os.path.basename(item) for item in glob.glob(os.path.join(path, str(l)+'/*'+str(_mode)+'.txt')) ]
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
parser.add_argument("--level", help="Define level of metrics")
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

if not args.level:
    helper.log_msg('ERROR:    no analysis level provided.')
    sys.exit()
else:
    Level = args.level

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


if os.path.isfile(os.path.join(Path,'SubjectList.txt')):
    SubjectList = io.load_table(os.path.join(Path,'SubjectList.txt'))
else:
    helper.log_msg("UPDATE:    no subjectlist found, using all overlapping subjects in "+str(Labels))
    SubjectList = get_subjectlist(Path,Labels,Connectome)


#############################################
#                                           #
#         PERFORM COMPUTATIONS              #
#                                           #
#############################################

helper.log_msg("START:    Computing connectome network "+str(Level)+" metrics.")

Data = get_data(Path, Labels, SubjectList)



if Level == "global":
    MetricsList = [ 'degree', 'cluster_coeff', 'between_cent' ]
    for lab in Labels:
        Metrics = numpy.zeros([len(SubjectList),len(MetricsList)])
        for s in SubjectList: 
            cc = network(Data[s][lab], _threshold = 0.3)
            for metric in MetricsList:
                Metrics[SubjectList.index(s),MetricsList.index(metric)] = getattr(Global,metric)(cc)
        numpy.savetxt(os.path.join(OutDir,'NetworkMetrics'+str(Connectome)+str(lab)+'Global.txt'), Metrics, header = str(MetricsList), delimiter = ',')

if Level == "local":
    MetricsList = [ 'degree', 'between_cent' ]
    for lab in Labels:
        Metrics = numpy.zeros([len(SubjectList),Data[SubjectList[0]][lab].shape[0]])
        for metric in MetricsList:
            helper.log_msg("UPDATE:    Computing "+str(metric)+" metric for "+str(lab))
            for s in SubjectList:
                cc = network(Data[s][lab], _threshold = 0.3)           
                print('processing: '+str(s))
                Metrics[SubjectList.index(s),:] = getattr(Local,metric)(cc)
            numpy.savetxt(os.path.join(OutDir,'NetworkMetrics_th03_'+str(Connectome)+str(lab)+str(metric)+'.txt'), Metrics, header = str([ 'ROI_'+str(r) for r in numpy.arange(1,Metrics.shape[1]+1)]), delimiter = ',')


helper.log_msg("FINISHED:    Computing connectome network "+str(Level)+" metrics.")
