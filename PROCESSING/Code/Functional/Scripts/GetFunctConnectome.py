#!/bin/python
#
#
# # GetFunctConnectome.py
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
# This script computes functional connectomes based on average time series as computed by
# FMRIGetAvgTS.sh in the previous step. It computes correlation based
# FC matrices and plots the adjacency matrix as heatmap.
#





#############################################
#                                           #
#            GET LIBRARIES                  #
#                                           #
#############################################


#---------------load libraries--------------#
import os, numpy, sys, matplotlib.pyplot, argparse


#############################################
#                                           #
#            HELPER FUNCTIONS               #
#                                           #
#############################################

#------------IO----------------#

def save_plot(filename=None):
    '''
    save plot wrapper at provided output directory outdir
    '''
    if filename:
        matplotlib.pyplot.savefig(filename)
    else:
        matplotlib.pyplot.savefig('test.png')
    matplotlib.pyplot.close()

def save_connectome(_matrix,fname = 'FunctionalConnectome.txt'):
    '''
    saving functional connectome
    '''
    numpy.savetxt(fname,_matrix)

def log_msg( _string):
    '''
    logging function printing date, scriptname & input string to stdout
    '''
    import datetime, os, sys
    print(datetime.date.today().strftime("%a %B %d %H:%M:%S %Z %Y") + " " + str(os.path.basename(sys.argv[0])) + ": " + str(_string))


#------------PLOTTING----------------#

def colorbar(mappable):
    from mpl_toolkits.axes_grid1 import make_axes_locatable
    last_axes = matplotlib.pyplot.gca()
    ax = mappable.axes
    fig = ax.figure
    divider = make_axes_locatable(ax)
    cax = divider.append_axes("right", size="5%", pad=0.05)
    cbar = fig.colorbar(mappable, cax=cax)
    matplotlib.pyplot.sca(last_axes)
    return cbar

def rescale(_array, _factor=.95, _norm = True):
    _matrix = _array.copy()
    _th = numpy.nanquantile(_matrix, _factor)
    _matrix = numpy.where(_matrix >= _th, _th, _matrix)
    if _norm:
        _matrix = _matrix / _th
    return(_matrix)

def plot_adjacency(_matrix, _title = ' ', zeromask = True, _rescale = True, _diag_remove = True):
    '''
    plot adjacency matrix
    '''
    import numpy, matplotlib.pyplot
    cc = _matrix.copy()
    if _rescale:
        cc = rescale(cc)
        _title = _title + '_0.95q_rescaled'
    if zeromask:
        cc = numpy.where(cc==0, numpy.nan,cc)
    if _diag_remove:
        cc = cc - numpy.eye(cc.shape[0])
    img = matplotlib.pyplot.imshow(cc, cmap = 'plasma')
    matplotlib.pyplot.title(_title)
    matplotlib.pyplot.xlabel('Region of interests')
    matplotlib.pyplot.ylabel('Region of interests')
    return(img)

#------------DATA MGMT----------------#


def get_connectome(timeseries):
    '''
    compute connectome via correlation coefficient
    '''
    con = numpy.corrcoef(timeseries)
    return(con)




#############################################
#                                           # 
#            PARSE INPUT                    #
#                                           #
#############################################


parser = argparse.ArgumentParser()
parser.add_argument("--path", help="Define study folder.")
parser.add_argument("--subject", help="Define subject ID.")
parser.add_argument("--session", help="Define session ID.")
parser.add_argument("--taskname", help="Define fmri task name.")
args = parser.parse_args()


# define local variables
WD = os.path.join(args.path,args.subject,args.session,args.taskname)
OutDir = os.path.join(args.path, args.subject, args.session, 'connectome')

# define filename for average time series txt file
filename = os.path.join(WD,f'{args.subject}_task-{args.taskname}_avg_ts.txt')

#-----------set local variables-----------#

# define connectome output directory

if not os.path.exists(OutDir):
    os.mkdir(OutDir)
    os.mkdir(os.path.join(OutDir,'Plots'))
    log_msg(f'UPDATE:    creating connectome output directory {OutDir}')


#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################

log_msg(f'START:   Computing functional connectome for {str(args.subject)}: {str(args.taskname)}')

# load average time series as computed during FMRIGetAvgTS.sh
avg_ts = numpy.loadtxt(filename).T

Conn = get_connectome(avg_ts)
save_connectome(Conn, os.path.join(OutDir,f'{args.subject}_task-{args.taskname}_FC.txt'))
p = plot_adjacency(Conn, _rescale = False, _title = f'FunctionalConnectome_{str(args.taskname)}')
colorbar(p)
save_plot(os.path.join(OutDir,'Plots',f'FunctionalConnectome_{str(args.taskname)}.PNG'))

log_msg(f'FINISHED:   Computing functional connectome for {str(args.subject)}: {str(args.taskname)}')
