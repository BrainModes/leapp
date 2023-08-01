#!/bin/python
#
# # StatisticsLearnings.py
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


# from Utility import *

class stats:
    '''
    statistical group level analysis class
    '''
    def __init__(self):
        '''
        intialization of statistics class
        '''
    def stats(_x1, _x2, _test = None):
        '''
        computing statistical group comparison
        '''
        import scipy.stats
        _cleanx1 = _x1[_x1 == _x1].copy()
        _cleanx2 = _x2[_x2 == _x2].copy()
        return(getattr(scipy.stats,_test)(_cleanx1, _cleanx2))


class learning:
    '''
    statistical learning utility function class object
    for statistical learning tasks
    '''
    def __init__(self):
        '''
        intialization of learning utility class
        '''
    def get_dict(path,files,labels):
        '''
        create dictionary containing both group feature matrices
        '''
        import os
        from utils.Utility import io
        data = dict()
        for f in files:
            data[labels[files.index(f)]] = io.load_table(os.path.join(path,f))
        return(data)
    def get_class_labels(_dict):
        '''
        create numpy array with class labels based on
        Data dictionary
        '''
        import numpy, sklearn.preprocessing
        labels = numpy.array([])
        for label in _dict.keys():
            labels = numpy.concatenate([labels,numpy.repeat(label, _dict[label].shape[0])])
        encoder = sklearn.preprocessing.LabelEncoder().fit(labels)
        return(encoder.transform(labels))
    def get_data_matrix(_dict):
        '''
        create numpy array with feature values for both classes
        '''
        import numpy
        keys = list(_dict.keys())
        return(numpy.concatenate([_dict[keys[0]],_dict[keys[1]]], axis = 0 ))
    def get_split(_split = .1, _runs = 100):
        '''
        get cross validation subset generator object for indexing
        '''
        import sklearn.model_selection
        return(sklearn.model_selection.StratifiedShuffleSplit(n_splits=_runs,test_size=_split))
    def get_performance(_predictions):
        '''
        compute classification accuracy / F1 score
        '''
        import numpy, sklearn.metrics
        runs = numpy.arange(len(_predictions))
        performance = numpy.zeros([len(runs)])
        for r in runs:
            performance[r] = sklearn.metrics.accuracy_score(_predictions[r]['labels'], _predictions[r]['prediction'])
            # performance[r] = sklearn.metrics.f1_score(_predictions[r]['labels'], _predictions[r]['prediction'])
        return(performance)
    def get_importance(_predictions):
        '''
        extract feature importance across cross validation runs
        '''
        import numpy
        runs = numpy.arange(len(_predictions))
        importance = numpy.zeros([len(runs),len(_predictions[0]['importance'])])
        for r in runs:
            importance[r,:] = _predictions[r]['importance']
        return(importance)






class algorithms:
    '''
    class object containing wrapper functions
    for classification algorithms
    '''
    def __init__(self):
        '''
        intialization of learning algorithm class
        '''
    def run_randomforest(_data,_labels, _train_idx, _test_idx, _metric = 'gini'):
        '''
        performing classification for given data and labels using random forest

        ---
        input:
            training data and corresponding training labels, test data to predict
            [optional] = feature importance metric, default = "gini index"
        output:
            prediction for provided test set & feature importance
        '''
        import sklearn.ensemble, numpy
        output=dict()
        model = sklearn.ensemble.RandomForestClassifier(
            n_estimators = 300,
            max_features ='sqrt',
            criterion = _metric,
            class_weight='balanced_subsample',
            n_jobs = None)
        model.fit(_data[_train_idx,:],_labels[_train_idx])
        output['prediction'] = model.predict(_data[_test_idx,:])
        output['importance'] = model.feature_importances_
        output['labels'] = _labels[_test_idx]
        return(output)
    def run_svm(_data,_labels, _train_idx, _test_idx, _cost = .1, _kernel = 'linear'):
        '''
        performing classification for given data and labels using support vector machines
        
        ---
        input:
            training data and corresponding training labels, test data to predict
            [optional]: C _costm , kernel function _kernel
        output:
            prediction for provided test set & model coefficients
        '''
        import sklearn.svm, numpy
        output = dict()
        model = sklearn.svm.SVC(
            C = _cost,
            gamma = 'scale',
            kernel = _kernel,
            class_weight = 'balanced'
            )
        model.fit(_data[_train_idx,:],_labels[_train_idx])
        output['prediction'] = model.predict(_data[_test_idx,:])
        output['importance'] = model.coef_
        output['labels'] = _labels[_test_idx]
        return(output)





# def run_loocv(data,labels, algo = 'SVM',verbose = False):
#     '''
#      performing leave one out cross validation for all subjects

#      input: full data set, full label list
#      output: prediction for each subject, array of feature importances within each cross validation run
#     '''
#     subjects = data.index
#     prediction = labels.copy()
#     importances = pandas.DataFrame(numpy.zeros(data.shape), index = subjects)
#     if verbose:
#         print('START: running LOOCV classification')
#         bar = init_statusbar(len(subjects))
#         i = 0
#         bar.start()
#     for s in subjects:
#         x_train = data.drop(s, axis = 0).values
#         y_train = labels.drop(s, axis = 0).values.ravel()
#         x_test = data.loc[s,:].values.reshape(1,-1)
#         if algo == 'RF':
#             prediction.loc[s], importances.loc[s,:]= run_randomforest(x_train,y_train,x_test)
#         if algo == 'SVM':
#             prediction.loc[s], importances.loc[s,:]= run_svm(x_train,y_train,x_test)
#         if verbose:
#             bar.update(i+1)
#             i+=1
#     if verbose:
#         print('\n FNISHED: running LOOCV random forest classification')
#     performance = sklearn.metrics.f1_score(labels,prediction)
#     return(performance, importances)







# def balance_classes(data,labels):
#     '''
#     rebalance classes to equal size by randomly selecting subset of larger class equal to class size of smaller class
#     makes multiple runs necessary to esure all data is used!
#     '''
#     data_r = data.copy()
#     labels_r = labels.copy()
#     groups = numpy.unique(labels, return_counts=True)
#     greater_class = groups[0][groups[1].argmax()]
#     gc_idx = numpy.where(labels['Label']==greater_class)[0]
#     numpy.random.shuffle(gc_idx)
#     redux_idx = gc_idx[:groups[1][groups[1].argmin()]]
#     data_r = data_r.drop(data_r.index[redux_idx],axis =0)
#     labels_r = labels_r.drop(labels_r.index[redux_idx],axis =0)
#     return(data_r,labels_r)

