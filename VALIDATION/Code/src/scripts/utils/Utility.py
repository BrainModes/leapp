#!/bin/python
#
# # Utility.py
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
#            HELPER FUNCTIONS               #
#                                           #
#############################################


class helper:
    '''
    Class object for helper functions includding progressbars, logging etc.
    '''
    import datetime, os, sys, numpy
    def __init__(self):
        import datetime, os, sys
    def log_msg( _string):
        '''
        logging function printing date, scriptname & input string to stdout
        '''
        import datetime, os, sys
        print(datetime.date.today().strftime("%a %B %d %H:%M:%S %Z %Y") + " " + str(os.path.basename(sys.argv[0])) + ": " + str(_string))
    def init_statusbar(_length):
        '''
        initializing status bar for progress display in terminal
        '''
        import progressbar
        statusbar = progressbar.ProgressBar(maxval=_length, \
        widgets=[progressbar.Bar('=', '[', ']'), ' ', progressbar.Percentage()])
        return(statusbar)
    def show_usage(_text=None):
        '''
        print usage of script in case of empty input or error message thrown.
        '''
        import sys
        if not _text:
            _text="""
            No usage message defined. 
            Please refer to source code for:
            """
            print(_text + str(sys.argv[0]))
        else:
            print(_text)


class io:
    '''
    input/output helper class
    '''
    def __init__(self, _path, _string):
        '''
        initializing class object
        '''
        # self._dict = self.get_dict(_path, _string)
        # self.helper = helper()
        # self.LUT = self.get_lookup(os.path.join(os.getcwd(),'LesionLoads','HCPMMP1_LUT_mrtrix.txt'))
        # # self.check_input()
    def load_table(_path):
        '''
        load space seperated .txt file into numpy array
        '''
        import numpy
        return(numpy.genfromtxt(_path, delimiter= ",", skip_header=1))
    def get_connectome(_filename):
        '''
        loading connectome file as created by MRtrix pipeline.
        '''
        import numpy
        return(numpy.genfromtxt(_filename, delimiter= " "))
    def get_nii(_filename):
        '''
        loading nifti image (.nii, .nii.gz)
        output: nibabel nifti object
        '''
        import nibabel
        return(nibabel.load(_filename))
    # def get_dict(self, _path, _string):
    #     '''
    #     create dictionary containing tables in _path
    #     '''
    #     import glob
    #     _ids = list(glob.glob(os.path.join(_path, "*"+str(_string)+"*" )))
    #     _ids.reverse()
    #     _dict = dict()
    #     for i in _ids:
    #         _key = i.split("/")[-1][:-(17+len(_string))]
    #         _dict[_key] = self.load_table(i)
    #     return(_dict)
    # def check_input(self):
    #     '''
    #     check if dimensions of input arrays identical
    #     '''
    #     import numpy
    #     _keys = list(self._dict.keys())
    #     for k in numpy.arange(len(_keys)):
    #         if self._dict[_keys[k]].shape != self._dict[_keys[k+1]]:
    #             self.helper.log_msg("ERROR:    input dimensionalities do not match.")
    #             exit(1)
    def get_lesionload(self, _path):
        '''
        loading the lesion affected ROI file created during parcellation mapping of lesion2TVB pipeline
        '''
        import numpy
        _ll = numpy.loadtxt(_path, delimiter= ",", dtype = str)
        if _ll.ndim == 1:
            _ll = _ll.reshape(1,2)
        self.lesionload = _ll
    def get_lookup(self, _path):
        '''
        load the corresponding lookup table for ROI IDs
        '''
        import numpy
        _table = numpy.loadtxt(_path, delimiter= "\t", dtype = str)
        return(dict(_table[:,[1,0]]))
    def get_lesionrois(self):
        '''
        reduced the given ROI list to lesion affected ROIs
        '''
        rid = []
        for r in list(self.lesionload[:,0]):
            rid.append(int(self.LUT[str(r)+'.label'])-1)
        self.lesion_dict = dict()
        self.lesion_rois = rid #[ i+1 for i in rid ]
        for k in self._dict.keys():
            self.lesion_dict[k] = self._dict[k][rid,:]

    # def fractional_rescale(_matrix):
    #     '''
    #     applying fractional rescaling of connectivity matrix
    #     following Rosen and Halgren 2021 eNeuro
    #     F(DTI(i,j)) := DTI(i,j) / sum(DTI(i,x))+sum(DTI(y,j)) with x!=i,y!=j
    #     '''
    #     import numpy
    #     colsum = numpy.nansum(_matrix, axis = 0)
    #     _temp1 = numpy.tile(colsum,(colsum.shape[0],1))
    #     colsum = numpy.nansum(_matrix, axis = 1)
    #     _temp2 = numpy.tile(colsum,(colsum.shape[0],1))
    #     return( _matrix / ( (_temp1 + _temp2.T ) - (2*_matrix)) )



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