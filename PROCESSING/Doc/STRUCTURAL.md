# *Le*sion *A*ware *P*rocessing *P*ipeline - Structural Pipeline
modul for automated structural neuroimaging processing.


## ABOUT

This code has been developed by the [brainsimulation section](www.brainsimulation.org) at the [Berlin Institute of Health at Charité](www.bihealth.org).


## DESCRIPTIONS

The structural processing pipeline of *LeAPP* <sup>1</sup> is build around the HCP minimal processing structural pipeline<sup>2</sup>. 

It is subdivided into five distinct steps:

1. Lesion mask preparation and virtual brain transplant
2. Adjusted HCP - PeeFreeSurfer
3. Adjusted HCP - FreeSurfer
4. HCP - PostFreeSurfer
5. Parcellation mapping

### INPUT

The required mininmal input to run the structural processing pipeline consists of the following files in *BIDS* standard file formatting:

```
/StudyFolder
    /Sub-${SubID}/
        /ses-${SesID}/
            /anat
                sub-${SubID}_T1w.json                 # T1w MPRAGE image metadata
                sub-${SubID}_T1w.nii.gz               # T1w MPRAGE image nifti volume
                sub-${SubID}_FLAIR.json               # FLAIR or T2 image metadata
                sub-${SubID}_FLAIR.nii.gz             # FLAIR or T2 image nifti volume
                sub-${SubID}_T1w_lesion_mask.nii.gz   # Binary lesion mask in T1w space (space can vary but must then be defined via $MaskSpace variable)
```

### INSTRUCTIONS

Running the structural processing pipeline follows the above mentioned modular approach. The main parameter value required is described below:

```bash
docker run \
    -e Steps="structural ..."
```

Within the steps variable we can define the specific substep as listed here.

```bash
# Steps variable options:
1. "prefs" = running the LeAPP specific PreFreeSurfer step.
2. "fs" = running the LeAPP specific FreeSurfer step.
3. "postfs" = running the PostFreeSurfer step.
4. "all" = running all structural processing steps.
```

__ADDITIONAL PARAMETER OPTIONS__
```bash
-e MaskSpace = base image used during lesion mask creation. Defines naming of lesion file in /anat folder [optional, default: T1w]
-e SmoothingFactor = integer to use for Gaussian smoothing of lesion mask during virtual brain transplant [optional, default: 2]
```

## REFERENCES

<sup>1</sup> Bey et al. (in prep), Lesion aware automated processing pipeline for multimodal neuroimaging stroke data and TheVirtualBrain (TVB).\
<sup>2</sup> [Glasser et al. 2013, The minimal preprocessing pipelines for the Human Connectome Project](http://dx.doi.org/10.1016/j.neuroimage.2013.04.127) \
