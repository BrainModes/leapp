#!/bin/python
#
# # NetworkMetrics.py
#
# * Brain Simulation Section
# * Charité Berlin Universitätsmedizin
# * Berlin Institute of Health
#
# ## Author(s)
# * Bey, Patrik, Charité Universitätsmedizin Berlin, Berlin Institute of Health
# * Dhindsa, Kiret, Charité Universitätsmedizin Berlin, Berlin Institute of Health
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
#            METHOD FUNCTIONS               #
#                                           #
#############################################




class network:
    '''
    class for network metric computations for a given adjacency matrix

    ---
    Input:
        numpy.array symmetrical adjacency matrix
    Output:

    '''
    def __init__(self, _matrix, _threshold = None):
        '''
        initialization of graph metric object
        '''
        import networkx, numpy
        if _threshold:
            _matrix[abs(_matrix) < _threshold] = 0
        _cleanmatrix=numpy.where(_matrix!=_matrix,0,_matrix)
        self._graph = networkx.convert_matrix.from_numpy_matrix(_cleanmatrix)





class Global(network):
    '''
    global network functions

    ---
    input:
        network class object

    '''
    def __functions__(self):
        return([name for name in dir(self) if name[0] != '_'])
    def degree(self):
        '''
        get global graph node strength
        '''
        import numpy
        return(numpy.mean(self._graph.degree(weight='weight')))
    def cluster_coeff(self):
        '''
        return global cluster coefficient
        '''
        import networkx.algorithms.approximation
        return(networkx.algorithms.approximation.clustering_coefficient.average_clustering(self._graph, trials = 100))
    def between_cent(self):
        '''
        compute normalized betweenness centrality
        '''
        import networkx, numpy
        return(numpy.mean(list(networkx.centrality.betweenness_centrality(self._graph,
            k = None, normalized = True, weight = 'weight', endpoints = False, seed = None).values())))
    def smallworldness(self):
        '''
        compute small worldness of graph
        '''
        import networkx
        omega = networkx.smallworld.omega(self._graph, niter=100, nrand=10, seed=None)
        return(omega)
    def short_path(self):
        '''
        compute average shortest path
        '''
        import networkx
        sp = networkx.shortest_paths.average_shortest_path_length(self._graph, weight='weight', method=None)
        return(sp)


class Local(network):
    '''
    local network functions

    ---
    input:
        network class object

    '''
    def __functions__(self):
        return([name for name in dir(self) if name[0] != '_'])
    def degree(self):
        '''
        get local graph node strength
        '''
        import numpy
        return(numpy.array(self._graph.degree(weight='weight'))[:,1])
    def between_cent(self):
        '''
        compute normalized betweenness centrality
        '''
        import networkx, numpy
        return(numpy.array(list(networkx.centrality.betweenness_centrality(self._graph,
            k = None, normalized = True, weight = 'weight', endpoints = False, seed = None).values())))