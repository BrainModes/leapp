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


## FUNDING

> This work was supported by the Virtual Research Environment at the Charité Berlin—a node of EBRAINS Health Data Cloud. Part of computation has been performed on the HPC for Research cluster of the Berlin Institute of Health. 
> PR acknowledges support by EU Horizon Europe program Horizon EBRAINS2.0 (101147319), Virtual Brain Twin (101137289), EBRAINS-PREP 101079717, AISN—101057655, EBRAIN-Health 101058516, Digital Europe TEF-Health 101100700, EU H2020 Virtual Brain Cloud 826421, Human Brain Project SGA2 785907; Human Brain Project SGA3 945539, ERC Consolidator 683049; German Research Foundation SFB 1436 (project ID 425899996); SFB 1315 (project ID 327654276); SFB 936 (project ID 178316478); SFB-TRR 295 (project ID 424778381); SPP Computational Connectomics RI 2073/6-1, RI 2073/10-2, RI 2073/9-1; DFG Clinical Research Group BECAUSE-Y 504745852, PHRASE Horizon EIC grant 101058240; Berlin Institute of Health & Foundation Charité, Johanna Quandt Excellence Initiative; ERAPerMed Pattern-Cog 2522FSB904. 
> BC, GT, and CG acknowledge the following funding sources: German Research Foundation (178316478, project C1, 178316478, project C2).