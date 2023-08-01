#!/bin/python
#
# # AgreementMetrics.py
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
#         AGREEMENT FUNCTIONS               #
#                                           #
#############################################


# from utils.Utility import *

class transform:
    '''
    transformation helper functions
    '''
    def __init__(self, _path, _string):
        '''
        initializing class object
        '''
    def vectorize(_array):
        '''
        given a symmetric matrix , return entries of upper triangle
        matrix as flattened vector
        '''
        import numpy
        vec = _array[numpy.triu_indices(_array.shape[0])]
        return(numpy.asarray(vec))
    def binarize(_array):
        '''
        binarize input array

        ---
        input:
            numpy.array
        output:
            returning binarized array
        '''
        _binarray = _array.copy()
        _binarray[_binarray != 0] = 1
        return(_binarray)

class agreement:
    '''
    class objects containing functions to compute
    a range of agreement metrics for neuroimaging volumes
    '''
    import scipy, numpy
    def __init__(self):
        '''
        intialization of agreement measure class
        '''
    def get_output(self, _mo):
        '''
        returning the results of mapping object within numpy array
        '''
        import numpy
        return(numpy.asarray(list(_mo)))
    def measure_euclid(_array1, _array2):
        '''
        compute euclidean distance between vectorized matrices
        e.g. SCs
        '''
        import numpy
        # return(numpy.linalg.norm(self.utils.get_vector(_array1) - self.utils.get_vector(_array2)))
        if _array1.ndim < 2:
            return(numpy.linalg.norm(_array1[1:] - _array2[1:]))
        else:
            return(numpy.linalg.norm(_array1[:,1:] - _array2[:,1:]))
    def measure_difference(_array1, _array2):
        '''
        compute simple difference between arrays
        e.g. ROI sizes
        '''
        if _array1.ndim < 2:
            return(_array1[1:] - _array2[1:])
        else:
            return(_array1[:,1:] - _array2[:,1:])
    def measure_jaccard( _array1, _array2):
        '''
        compute jaccard score 
        '''
        import sklearn.metrics
        return(sklearn.metrics.jaccard_score(_array1.flatten(), _array2.flatten(), average='binary'))
    def measure_dice( _array1, _array2):
        '''
        compute dice coefficient 

        output:
            0 = perfect agreement
        '''
        import scipy.spatial
        return(scipy.spatial.distance.dice(_array1.flatten(), _array2.flatten(), w=None))
    def dice(gt,pred):
        '''
        compute dice dissimilarity]

        ---
        input:
            numpy arrays of same dimensions
        output:
            1 = perfrect agreement
        '''
        import numpy
        return(numpy.sum(pred[gt==1])*2.0 / (numpy.sum(pred) + numpy.sum(gt)))
    def measure_pearson( _array1, _array2):
        '''
        compute pearson correlation between arrays
        '''
        import scipy.stats
        if _array1.ndim >=2:
            _array1 = transform.vectorize(_array1.copy())
            _array2 = transform.vectorize(_array2.copy())
        return(scipy.stats.pearsonr(_array1, _array2)[0])
    def measure_hausdorff( _array1, _array2):
        '''
        compute directed hausdorff distance between arrays
        '''
        import scipy.spatial.distance
        return(scipy.spatial.distance.directed_hausdorff(_array1, _array2)[0])
    def volume_difference( _array1, _array2):
        '''
        compute volume difference between arrays 
        as defined as difference in nonzero elements divided by volume of _array1
        '''
        import numpy
        return( (numpy.sum(_array1) - numpy.sum(_array2)) / numpy.sum(_array1) )
    def measure_euclid_distance(_array1, _array2):
        '''
        compute euclidean distance between center-of-gravities
        '''
        import numpy
        cog_1 = numpy.mean(numpy.array(numpy.where(_array1!=0)), axis = 1).reshape(1,3)
        cog_2 = numpy.mean(numpy.array(numpy.where(_array2!=0)), axis = 1).reshape(1,3)
        return(numpy.linalg.norm(cog_1 - cog_2))

    # def measure_geodist( _array1, _array2, _lowereigenthresh = 10**(-3)):
    #     ############### NEEDS VALIDATION FOR IMPLEMENTATION ###################
    #     '''
    #     compute the geodesic distance between input SCs
    #     following (Venkatesh et al 2020, NeuroImage) using single value decompostion for factorization
    #     of SCs to compute reciprocal sqrts

    #     ---
    #     input:
    #         numpy arrays of identical size representing adjacency matrices
    #     output:
    #         distance value float
    #     '''
    #     import numpy
    #     u, s, vh = numpy.linalg.svd(_array1, full_matrices=True)
    #     ## lift very small eigen values to lower threshold
    #     for ii, s_ii in enumerate(s):
    #         if s_ii < _lowereigenthresh:
    #             s[ii] = _lowereigenthresh
    #     _array1_mod = u @ numpy.diag(s**(-1/2)) @ numpy.transpose(u)
    #     M = _array1_mod @ _array2 @ _array1_mod
    #     u, s, vh = numpy.linalg.svd(M, full_matrices=True)
    #     return(numpy.sqrt(numpy.sum(numpy.log(s)**2)))
