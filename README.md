<p align='center'>
    <img src= 'Doc/images/banner.png'>
</p>

<p align="left">
    <!-- <a href="https://zenodo.org/badge/latestdoi/523258545"><img src="https://zenodo.org/badge/523258545.svg" alt="DOI"></a> -->
    <a href="https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12" alt="License-EUPL-1.2-or-later">
        <img src="https://img.shields.io/badge/license-EUPL--1.2--or--later-green" /></a>
</p>

# *Le*sion *A*ware *P*rocessing *P*ipeline: 
an automated, robust and validated processing pipeline for multimodal neuroimaging data in the presence of ischemic stroke lesions.


## ABOUT

This code has been developed by the [brainsimulation section](www.brainsimulation.org) at the [Berlin Institute of Health at Charité](www.bihealth.org).

Authors: \
Patrik Bey; patrik.bey@bih-charite.de 

## DESCRIPTIONS
Processing ischemic stroke MRI data can be impacted by the lesion-based abnormalities
This repository contains the code and documentation for <sup>1</sup> covering the described processing pipeline as well as the validation framework developed.
Both frameworks are available as dockerized container workflows and can be built following the instruction given in the corresponding sections.
<!--  ADD DOCKER HUB LINK -->



## REQUIREMENTS

The single requirement for the usage of either framework is the docker containerization software ([www.docker.com](https://www.docker.com)).
Storage requirements differ significantly for both frameworks with the processing pipeline demanding high amounts of storage due to the large number of integrated software tool within the container. (See most important software packages in the Pipeline section)

```python
leapp:"processing" = ~27GB
lapp:"validation" = 700MB
```

## INSTRUCTIONS
Documentation on how to run either pipeline can be found in the given chapters [__processing__](PROCESSING/README.md) and [__validation__](VALIDATION/README.md).


### CITATION

Please acknowledge this work by citing <sup>1</sup>.


## REFERENCES

<sup>1</sup> Bey, P., Dhindsa, K., Kashyap, A., Schirner, M., Feldheim, J., Bönstrup, M., Schulz, R., Cheng, B., Thomalla, G., Gerloff, C., & Ritter, P. (2024). A lesion-aware automated processing framework for clinical stroke magnetic resonance imaging. Human Brain Mapping, 45(9), e26701. https://doi.org/10.1002/hbm.26701
