#!/bin/python
#
#
# # PlotStructConnectome.py
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
# * last update: 2022.12.12
#
#
#
# ## Description
#
# This script creates visualization of the structural connectomes created during DWITractography.sh




#############################################
#                                           #
#            GET LIBRARIES                  #
#                                           #
#############################################


#---------------load libraries--------------#
import os, numpy, sys, matplotlib.pyplot, argparse, glob


#############################################
#                                           #
#            HELPER FUNCTIONS               #
#                                           #
#############################################

#------------IO----------------#

def get_connectome(filename):
    '''
    load connectonme into numnpy array
    '''
    import numpy
    return(numpy.genfromtxt(filename, delimiter=','))

def save_plot(filename=None):
    '''
    save plot wrapper at provided output directory outdir
    '''
    if filename:
        matplotlib.pyplot.savefig(filename)
    else:
        matplotlib.pyplot.savefig('test.png')
    matplotlib.pyplot.close()

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

def plot_adjacency(_matrix, _title = ' ', zeromask = False, _rescale = True, _diag_remove = True):
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
        numpy.fill_diagonal(cc,0)
    img = matplotlib.pyplot.imshow(cc, cmap = 'plasma')
    matplotlib.pyplot.title(_title)
    matplotlib.pyplot.xlabel('Region of interests')
    matplotlib.pyplot.ylabel('Region of interests')
    return(img)


#############################################
#                                           # 
#            PARSE INPUT                    #
#                                           #
#############################################


parser = argparse.ArgumentParser()
parser.add_argument("--path", help="Define study folder.", default='/data')
parser.add_argument("--subject", help="Define subject ID.", default='sub-P009')
parser.add_argument("--session", help="Define session ID.", default='ses-01')
args = parser.parse_args()

WD = os.path.join(args.path,args.subject,args.session,'connectome')

OutDir = os.path.join(WD, 'Plots')

if not os.path.isdir(OutDir):
    os.makedirs(OutDir)

#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################

log_msg(f'START:   Plotting structural connectomes for {str(args.subject)}')

ConnectomeFiles = glob.glob(os.path.join(WD,'StructuralConnectome*'))


for sc in ConnectomeFiles:
    log_msg(f'UPDATE:    plotting adjacency matrix for {sc}')
    matrix = get_connectome(sc)
    p = plot_adjacency(matrix, _rescale=True, _title = os.path.basename(sc[:-4]))
    colorbar(p)
    save_plot(os.path.join(OutDir,f'{os.path.basename(sc)[:-4]}.PNG'))


log_msg(f'FINISHED:   Plotting structural connectomes for {str(args.subject)}')
