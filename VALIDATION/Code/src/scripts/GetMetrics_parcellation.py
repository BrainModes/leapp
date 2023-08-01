#!/bin/python
#
# # GetMetrics_parcellation.py
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
    create dictionary containing both group images for given subject ID
    '''
    import glob
    data = dict()
    for l in labels:
        data[l] = io.get_nii(os.path.join(path,l, _filename)).get_data().astype(int)
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
        _list[l] = [ os.path.basename(item) for item in glob.glob(os.path.join(path, str(l)+'/*'+str(_mode)+'.nii.gz')) ]
    if _list[_labels[0]] != _list[_labels[1]]:
        mismatch = list(set(_list[_labels[0]]) - set(_list[_labels[1]]))
        mismatch.append( list(set(_list[_labels[1]]) - set(_list[_labels[0]])))
        helper.log_msg("ERROR:    unequal subjects in both groups. Please check before continuing.")
        helper.log_msg('ERROR:    files not present in both lists: '+str(mismatch))
        sys.exit()
    else:
        return(_list[_labels[0]])

def get_measures(_dict, _subject, _measures=['dice','volume_difference']):
    '''
    function to compute ROI based measures for given subject
    to parallelize subject computations
    
    ---
    input:
        _dict data dictionary with subject keys
        _subject ID as key for data dictionary
        _measures list to compute from agreement class object
    output:
        numpy array for each measure
    '''
    import numpy
    from utils.AgreementMetrics import agreement
    _data = _dict[_subject]
    _keys = list(_data.keys())
    _rois = numpy.unique(_data[_keys[0]][_data[_keys[0]] != 0]).astype(int)
    _output = dict()
    for m in _measures:
        _output[m] = []
    for r in _rois:
        temp_x = numpy.where(_data[_keys[0]]==r,1,0)
        temp_y = numpy.where(_data[_keys[1]]==r,1,0)
        for m in _measures:
            _output[m].append(getattr(agreement,m)(temp_x, temp_y))
    return(_output)




#############################################
#                                           #
#              PARSE INPUT                  #
#                                           #
#############################################

parser = argparse.ArgumentParser()
parser.add_argument("--path", help="Define input directory", default='/data')
parser.add_argument("--labels", help="Define group labels for comparison")
parser.add_argument("--atlas", help="Define atlas parcellation used")
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

if not args.atlas:
    helper.log_msg('ERROR:    no parcellation atlas provided.')
    sys.exit()
else:
    Atlas = args.atlas

if not args.outdir:
    helper.log_msg('UPDATE:    no output directory provided. Using default <<Path>> variable')
    OutDir = Path
else:
    OutDir = args.outdir



#############################################
#                                           #
#         DEFINE LOCAL VARIABLES            #
#                                           #
#############################################

SubjectList = get_subjectlist(Path, Labels, Atlas)

Data = get_data(Path, Labels, SubjectList)

pool = multiprocessing.Pool(multiprocessing.cpu_count())

measure_list = ['dice','volume_difference', 'measure_euclid_distance']
#############################################
#                                           #
#         PERFORM COMPUTATIONS              #
#                                           #
#############################################

helper.log_msg("START:    Computing parcellation based agreement measures.")

Measures =  [ pool.apply(get_measures,args=(Data, s, measure_list)) for s in SubjectList ]

Output = dict()
for m in measure_list:
    Output[m] = numpy.zeros([len(SubjectList),len(Measures[0][m])])

for s in SubjectList:
    for m in measure_list:
        Output[m][SubjectList.index(s),:] = numpy.array(Measures[SubjectList.index(s)][m]).reshape([1,len(Measures[0][m])])


for m in measure_list:
    numpy.savetxt(os.path.join(OutDir, str(m)+'_'+str(Atlas)+'.txt'),Output[m], header = str([str(x) for x in range(len(Measures[0][m]) + 1)]), delimiter = ',')

 
helper.log_msg("FINISHED:    Computing parcellation based agreement measures.")