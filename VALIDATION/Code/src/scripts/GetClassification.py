#!/bin/python
#
# # GetClassifcation.py
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
# This script is a wrapper for classification with
# feature importance extraction for the CFM Validation container
# as used in (Bey, Dhindsa et al., https://figshare.com/s/52d844dde062f5b75c9e )
#
#
#

#############################################
#                                           #
#        NETWORK METRICS WRAPPER            #
#                                           #
#############################################


from utils.Utility import *
from utils.StatisticsLearning import *
import os, sys, numpy, matplotlib.pyplot, nibabel, argparse, glob, multiprocessing

#############################################
#                                           #
#              PARSE INPUT                  #
#                                           #
#############################################

parser = argparse.ArgumentParser()
parser.add_argument("--path", help="Define input directory")
parser.add_argument("--files", help="Define filenames input feature matrices")
parser.add_argument("--cvsplit", help="Define cross-validation split")
parser.add_argument("--labels", help="Define group labels for comparison")
parser.add_argument("--outfile", help="Define output filename")
args = parser.parse_args()

####
# TO DO: add parameter key=value pair input optio
# comma seperated list, str.split(','), for item in list, dict(split[0]) = split[1]



if not args.path:
    helper.log_msg('ERROR:    no input directory provided.')
    sys.exit()
else:
    Path = args.path

if not args.files:
    helper.log_msg('ERROR:    no feature input files provided.')
    sys.exit()
else:
    if ',' in args.files:
        Files = args.files.split(',')
    elif ';' in args.files:
        Files = args.files.split(';')
    else:
        Files = args.files.split(' ')


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

if not args.cvsplit:
    helper.log_msg('UPDATE:    no cv split provided, using default 10%.')
    Split = 0.1
else:
    Split = float(args.cvsplit)

if not args.outfile:
    helper.log_msg('UPDATE:    no output filename prefix provided. Using default <<Files>> variable.')
    OutFile = os.path.join(Path,'OutPut_'+str(Files))
else:
    OutFile = args.outfile



# Files=['NetworkMetricsFCunmaskeddegree.txt','NetworkMetricsFCmaskeddegree.txt']
# Path="/data/Registration/"
# Labels="masked,unmasked".split(',')
# Split='loocv'
# Runs=10

helper.log_msg("START:    Random Forest classification")


Data = learning.get_dict(Path,Files,Labels)

ClassLabels = learning.get_class_labels(Data)

Features = learning.get_data_matrix(Data)

pool = multiprocessing.Pool(multiprocessing.cpu_count())

SplitGen = learning.get_split(_split=Split,_runs = 100)

helper.log_msg("UPDATE:    Starting cross validation ")
helper.log_msg("UPDATE:    Using default value of runs=100 ")

Predictions = [ pool.apply(getattr(algorithms,'run_randomforest'), args=(Features,ClassLabels,train_idx, test_idx)) for train_idx, test_idx in SplitGen.split(Features, ClassLabels) ]

helper.log_msg("UPDATE:    Extracting performance measures")
Performance = learning.get_performance(Predictions)
numpy.savetxt(os.path.join(Path,OutFile + '_Accuracy.txt'),Performance, header = str('Accuracy'), delimiter = ',')
# numpy.savetxt(os.path.join(Path,OutFile + '_F1Score.txt'),Performance, header = str('F1Score'), delimiter = ',')

Importance = learning.get_importance(Predictions)
numpy.savetxt(os.path.join(Path, OutFile+ '_FeatureImportance.txt'),Importance, header = str('Importance'), delimiter = ',')

helper.log_msg("FINISHED:    Random Forest classification")
