# Radial-tangential_fiber_systems_in_swm

**Cite:**

> *[Hwang, Y.](mailto:youngeun.hwang2@mail.mcgill.ca), Vavassori, L., Bautin, P., Rodriguez-Cruces, R., Gaspar-Martinez, E., Cabalo, DG., Ngo, A., Smith, M., Leech, R., Coronado-Leija, R., Petit, L., Avesani, P., Sarubbo, S., Evans, AC., Concha, L., & [Bernhardt, BC](mailto:boris.bernhardt@mcgill.ca) (2026). Radial and tangential fiber components in human superficial white matter and their associations with macroscale function. ...*

**DOI:** https://doi.org/10.64898/2026.10.02.756249

**Preprint:** available at [bioRxiv](https://doi.org/10.64898/2026.10.02.756249)

**Data repository:** available at [OSF(3T)](https://osf.io/j532r/) and [OSF(7T)](https://osf.io/mhq3f/)

**Keywords:** Superficial white matter (SWM); U-fiber; Magnetic resonance imaging (MRI); Ultra-high field MRI; 7 Tesla MRI; Diffusion MRI; Functional MRI; Spatial variogram; multi-resolution discrete search (MRDS); Photogrammetry

## Overview
This repository contains the code and analysis notebooks for studying radial and tangential fiber components in the superficial white matter (SWI) using *in-vivo* MRI datasets. It includes preprocessing, validation, visualization scripts for assessing SWM intensity profiles across datasets, as well as functional variogram analysis and its relationship with radial-tangential fiber predominance.
- Run the radial-tangential fiber separation framework within the SWM
- Qualify diffusion metrics of radial and tangential fiber components within the SWM
- Validate the radial-tangential framework for SWM fiber separation using *in-vivo* tractography  
- Perform functional variogram analysis and assess its relationship with radial-tangential fiber predominance

## Dataset
### Participants
- Eleven healthy living participants
- Ten *post-mortem* brain specimens

### Imaging Data
- 3T and 7T MRI
  - T1-weighted structural images
  - Diffusion-weighted images
  - Resting state functional images
- Brain dissection photogrammetry

## Repository content
| Directories   | Description                                                                                                                                                                                                                                                                             |
|---------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [`./scripts`]()      | `bash`, and `python` scripts for processing to reproduce the findings.                                                                                                                                                        |
| [`./notebooks`]() | `jupyter notebook` scripts used for the analysis to reproduce the findings.                                                                                                                                                                                                                      |
| [`./figures`]() | figures presented in this paper.                                                                                                                                                                                                                      |

## Abstract
Subcortical U-shaped fibers (U-fibers), which interconnect adjacent cortical gyri within the superficial white matter (SWM), are thought to play a key role in brain organization, plasticity, and function. However, these short-range fibers remain understudied, largely due to the difficulty of disentangling them from long-range fiber systems within the structurally complex SWM. Here, we aimed to dissociate U-fiber systems from long-range fiber populations by distinguishing two distinct fiber components within the human SWM and investigate their potential functional relevance using in-vivo highfield MRI. We implemented a surface-based framework to separate radial and tangential fiber components according to their orientation relative to the Laplacian streamlines within the SWM. These components were quantified using apparent fiber density (AFD), fractional anisotropy (FA), and mean diffusivity (MD). We further contextualized SWM fiber architecture by examining depth-dependent diffusion-derived microstructural profiles and their relationship with normative patterns of cortical organization and hierarchical specialization. The validity of the proposed fiber orientation separation was supported by tractography-based bundle analyses, while the anatomical accuracy of the tractography reconstructions was confirmed through comparison with post-mortem white matter dissection data. To assess their functional relevance, the fiber predominance map derived from radial and tangential AFD was related to spatial patterns of functional variability across the cortex. Regions with greater radially oriented fiber contribution exhibited more gradual changes in functional similarity across geodesic distance, whereas tangentially oriented fiber-enriched regions showed more rapid local functional differentiation. These findings reveal distinct structural and functional signatures of radial and tangential SWM fiber components and provide a framework for investigating their contributions to cortical organization and functional specialization.


## Open Data and Software
This study was conducted using open datasets, listed below:
- MICA-MICS: Multimodal MRI dataset for microstructure-informed connectomics (Royer et al., 2022)
- MICA-PNI: Ultra-high field 7T MRI data (Cabalo et al., 2024)
- BraDiPho: Brain dissection photogrammetry (Vavassori et al., 2025)

We also utilized multiple open-source software packages, as detailed below:
- superficial-white-matter (https://doi.org/10.5281/zenodo.11510179)
- corticalDWI (https://github.com/lconcha/corticalDWI)
- *micapipe* (http://micapipe.readthedocs.io)
- BrainVariograms (https://github.com/ActiveNeuroImaging/BrainVariograms)
