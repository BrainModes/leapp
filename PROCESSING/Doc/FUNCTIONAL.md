# *Le*sion *A*ware *P*rocessing *P*ipeline - Functional Pipeline
modul for automated functional neuroimaging processing.


## ABOUT

This code has been developed by the [brainsimulation section](www.brainsimulation.org) at the [Berlin Institute of Health at Charité](www.bihealth.org).



## DESCRIPTIONS

The functional processing pipeline of *LeAPP* <sup>1</sup> is build in two parts. The first part is build around the HCP minimal processing functional pipeline<sup>2</sup> for volume based processing. In the second part we implemented new methods to create ROI based average time series and functional connectomes (FC) for a given time seris. 

It is subdivided into three distinct steps:

1. General preprocessing including motion correction, distortion correction, ...
2. Creating ROI based average time series in high resolution individual T1w space
3. Creation of functional connectomes.


### REQUIREMENTS

To run the functional processing pipeline *LeAPP* requires the output of the previously run structural processing pipeline.

### INPUT

The required mininmal input to run the functions processing pipeline consists of the following files in *BIDS* standard file formatting:

```
/StudyFolder
    /Sub-$SubID/
        /ses-$SesID/
            /func
                sub-${SubID}_task-{fmriname}_bold.json                 # fMRI task meta data
                sub-${SubID}_task-{fmriname}_bold.nii.gz               # fMRI task 4D image volume
            /fmap
                sub-${SubID}_task-{fmriname}_part-1-mag_bold.json      # fMRI task fieldmap magnitude 1 meta data
                sub-${SubID}_task-{fmriname}_part-1-mag_bold.nii.gz    # fMRI task fieldmap magnitude 1 image volume
                sub-${SubID}_task-{fmriname}_part-2-mag_bold.json      # fMRI task fieldmap magnitude 2 meta data
                sub-${SubID}_task-{fmriname}_part-2-mag_bold.nii.gz    # fMRI task fieldmap magnitude 2 image volume
                sub-${SubID}_task-{fmriname}_part-phase_bold.json      # fMRI task filedmap phase difference meta data
                sub-${SubID}_task-{fmriname}_part-phase_bold.nii.gz    # fMRI task filedmap phase difference image volume
            /T1w
                T1w_acpc_dc_restore_brain.nii.gz                       # fully processed T1w image
            /lesion
                T1w_acpc_dc_resotre_mask_invert.nii.gz                 # inverted binary lesion mask in final T1w space
            /parcellation
                sub-${SubID}_HCPMMP1_resample.nii.gz                   # individual brain parcellation iamge volume

```


### INSTRUCTIONS

Running the functional processing pipeline follows the above mentioned modular approach. The main parameter value required is described below:

```bash
docker run \
    -e Steps="functional ..."
```

Within the steps variable we can define the specific substep as listed here.

```bash
# Steps variable options:
1. "preproc" = running the LeAPP specific fMRIVolume processing step
2. "connectome" = running the LeAPP specific creation of average timeseries and FC matrices
3. "all" = running all functional processing steps.
```

__ADDITIONAL PARAMETER OPTIONS [WIP]__
```bash
-e FMRIFiles = single timeseries filename to process. [optional, default: process all fMRI timeseries found in /func]
-e Onsets = provide onset files for task absed FC creation
```


## REFERENCES

<sup>1</sup> Bey et al. (in prep), Lesion aware automated processing pipeline for multimodal neuroimaging stroke data and TheVirtualBrain (TVB).\
<sup>2</sup> [Glasser et al. 2013, The minimal preprocessing pipelines for the Human Connectome Project](http://dx.doi.org/10.1016/j.neuroimage.2013.04.127) \
