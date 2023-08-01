# *Le*sion *A*ware *P*rocessing *P*ipeline - Diffusion Pipeline
modul for automated diffusion weighted processing.


## ABOUT

This code has been developed by the [brainsimulation section](www.brainsimulation.org) at the [Berlin Institute of Health at Charité](www.bihealth.org).


## DESCRIPTIONS

The diffusion processing pipeline of *LeAPP* <sup>1</sup> is build as a comprehensive pipeline for structural connectome creation. All steps have been implemented using MRtrix3 <sup>2</sup> and FSL based registration procedures.

It is subdivided into sixe distinct steps:

1. General preprocessing including eddy current correction, (limited - see below) distortion correction, ...
2. population based intensity normalization
3. Tissue segmentation 
4. population based response function averaging
5. Anatomically constrained tractography
6. Connectome creation

### REQUIREMENTS

To run the diffusion processing pipeline *LeAPP* requires the output of the previously run structural processing pipeline.


### INPUT

The required mininmal input to run the diffusion processing pipeline consists of the following files in *BIDS* standard file formatting:

```
/StudyFolder
    /Sub-$SubID/
        /ses-$SesID/
            /dwi
                sub-${SubID}_dwi.json                                  # DWI meta data
                sub-${SubID}_dwi.nii.gz                                # DWI image volume
            /T1w
                T1w_acpc_dc_restore_brain.nii.gz                       # fully processed T1w image
            /lesion
                T1w_acpc_dc_resotre_mask.nii.gz                        # binary lesion mask in final T1w space
                T1w_acpc_dc_resotre_mask_invert.nii.gz                 # inverted binary lesion mask in final T1w space
            /parcellation
                sub-${SubID}_HCPMMP1_resample.nii.gz                   # individual brain parcellation iamge volume
```



### INSTRUCTIONS

Running the diffusion processing pipeline follows the above mentioned modular approach. The main parameter value required is described below:

```bash
docker run \
    -e Steps="dwi ..."
```

Within the steps variable we can define the specific substep as listed here.

```bash
# Steps variable options:
1. "preproc" = running general preprocessing
2. "normal" = running population based intensity normalization
3. "segment" = running five type tissue segmentation of the T1w image
4. "response" = running population based response function averaging
5. "connectome" = running tractography and connectome creation
3. "all" = running all functional processing steps.
```


__ADDITIONAL PARAMETER OPTIONS__
```bash
-e Streams = number of tractography streams to create [optional, default: 100Mio.]
-e LesionEmbed = type of lesion embedding in 5tt segmentation [optional, default: mrtrix][WIP]

```

__DISTORTION CORRECTION__
Due to the lack of reverse phase encoding direction data the implemented approach for distortion correction follows the approach of registering the EPI diffusion image volume to the undistorted high resolution T1w reference created during structural processing pipeline. 

__LESION EMBEDDING__
Two different approaches for lesion embedding during tissue segmentation are currently implemented:
*mrtrix*: using MRTrix3 5ttedit function to update all tissue type to remove the lesion mask as pathological tissue
*experimental*: only define lesion mask within tissue type five "pathological tissue" to enable comparison studies

## REFERENCES

<sup>1</sup> Bey et al. (in prep), Lesion aware automated processing pipeline for multimodal neuroimaging stroke data and TheVirtualBrain (TVB).\
<sup>2</sup> [Tournier et al. 2019, MRtrix3: A fast, flexible and open software framework for medical image processing and visualisation](https://doi.org/10.1016/j.neuroimage.2019.116137)

