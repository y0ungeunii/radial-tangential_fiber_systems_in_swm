# SWM radial-tangential fiber component analysis workflow 

## Directory file content
| File                                                                                                                                                                      | Description                                                                   |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------|
| [`1-1_tutorial_csd.sh`](https://github.com/y0ungeunii/radial-tangential_fiber_systems_in_swm/blob/main/notebooks/1-1_tutorial_csd.sh)             | [Laplacian streamlines and AFD estimation](#1-1-laplacian-streamlines-and-afd-estimation)                                                      |
| [`1-2_tutorial_mrds.sh`](https://github.com/y0ungeunii/radial-tangential_fiber_systems_in_swm/blob/main/notebooks/1-2_tutorial_mrds.sh)             | [Multi-tensor FA and MD microstructural profiling](#1-2-multi-tensor-fa-and-md-microstructural-profiling)                                                                      |
| [`1-3_tutorial_tractography.sh`](https://github.com/y0ungeunii/radial-tangential_fiber_systems_in_swm/blob/main/notebooks/1-3_tutorial_tractography.sh) | [Radial and tangential fiber tractography](#1-3-radial-and-tangential-fiber-tractography)                                                                      |
| [`2-1_intensity-profiles_AFD.ipynb`](https://github.com/y0ungeunii/radial-tangential_fiber_systems_in_swm/blob/main/notebooks/2-1_intensity-profiles_AFD.ipynb)                         | [AFD profile processing and visualization](#2-1-afd-profile-processing-and-visualization)                                                  |
| [`2-2_intensity-profiles_MRDS.ipynb`](https://github.com/y0ungeunii/radial-tangential_fiber_systems_in_swm/blob/main/notebooks/2-2_intensity-profiles_MRDS.ipynb)                       | [FA and MD profile processing and visualization](#2-2-fa-and-md-profile-processing-and-visualization)  |
| [`2-3_neuralcontext_cyto.ipynb`](https://github.com/y0ungeunii/radial-tangential_fiber_systems_in_swm/blob/main/notebooks/2-3_neuralcontext_cyto.ipynb)                                                                       | [Laminar differentiation across SWM depths](#2-3-laminar-differentiation-across-swm-depths) |
| [`3_validation_tractography.ipynb`](https://github.com/y0ungeunii/radial-tangential_fiber_systems_in_swm/blob/main/notebooks/3_validation_tratography.ipynb)                                                                       | [Validation](#3-validation) |
| [`4_grp-variogram.ipynb`](https://github.com/y0ungeunii/radial-tangential_fiber_systems_in_swm/blob/main/notebooks/4_grp-variogram.ipynb)                                                                       | [Functional organization](#4-functional-organization) |

## [1-1. Laplacian streamlines and AFD estimation](https://github.com/y0ungeunii/radial-tangential_fiber_systems_in_swm/blob/main/notebooks/1-1_tutorial_csd.sh)
### Diffusion analysis of the SWM using constrained spherical deconvolution (CSD)
* Compute Laplacian streamlines and transform them into diffusion space.
* Estimate the fiber orientation distribution (FOD) from diffusion-weighted MRI data using CSD.
* Sample apparent fiber density (AFD) along Laplacian streamlines for each radial and tangential fiber component.

## [1-2. Multi-tensor FA and MD microstructural profiling](https://github.com/y0ungeunii/radial-tangential_fiber_systems_in_swm/blob/main/notebooks/1-2_tutorial_mrds.sh)
### Diffusion analysis of the SWM using multi-resolution discrete search (MRDS)
* Apply MRDS to estimate fiber-specific diffusion properties within the SWM.
* Compute microstructural measures, including fractional anisotropy (FA) and mean diffusivity (MD), along Laplacian streamlines for each radial and tangential fiber component.
   
## [1-3. Radial and tangential fiber tractography](https://github.com/y0ungeunii/radial-tangential_fiber_systems_in_swm/blob/main/notebooks/1-3_tutorial_tractography.sh)
### Tractography of radially and tangentially oriented fiber pathways
* Perform diffusion MRI-based tractography to reconstruct short-range U-fibers and long-range white matter pathways.
* Define seed, inclusion, and exclusion regions to constrain streamline reconstruction and identify anatomically relevant fiber pathways.
* Transform reconstructed streamlines between diffusion and template spaces for anatomical comparison and validation.
   
## [2-1. AFD profile processing and visualization](https://github.com/y0ungeunii/radial-tangential_fiber_systems_in_swm/blob/main/notebooks/2-1_intensity-profiles_AFD.ipynb)
### Processing AFD intensity profiles
* **Surface-based smoothing and processing:** Smooth intensity profiles at each surface to reduce noise and improve spatial continuity, then concatenate the profiles across surfaces into a unified dataset.
* **Outlier correction:** Identify and correct outliers in the intensity data to improve robustness.
* **Visualization:** Plot intensity profiles and their distributions for visual inspection and analysis.

## [2-2. FA and MD profile processing and visualization](https://github.com/y0ungeunii/radial-tangential_fiber_systems_in_swm/blob/main/notebooks/2-2_intensity-profiles_MRDS.ipynb) 
### Processing multi-tensor FA and MD intensity profiles
* **Surface-based smoothing and processing:** Smooth intensity profiles at each surface to reduce noise and improve spatial continuity, then concatenate the profiles across surfaces into a unified dataset.
* **Outlier correction:** Identify and correct outliers in the intensity data to improve robustness.
* **Visualization:** Plot intensity profiles and their distributions for visual inspection and analysis.

## [2-3. Laminar Differentiation across SWM depths](https://github.com/y0ungeunii/radial-tangential_fiber_systems_in_swm/blob/main/notebooks/2-3_neuralcontext_cyto.ipynb)
### Laminar differentiation of intensity profiles across SWM depths
* Plot smoothed intensity profiles across SWM depths using filtered intensity maps to characterize laminar differentiation.
* Classify cortical regions according to Mesulam's classical scheme of cortical laminar differentiation.
  
## [3. Validation](https://github.com/y0ungeunii/radial-tangential_fiber_systems_in_swm/blob/main/notebooks/3_validation_tratography.ipynb)
### Anatomical validation of the surface-based framework for SWM fiber separation
* Compute the angles between Laplacian streamlines and radially or tangentially oriented fiber pathways reconstructed using tractography at different SWM depths.
* Analyze angular differences separately in gyral and sulcal regions to assess the anatomical validity of the surface-based fiber separation framework.

## [4. Functional organization](https://github.com/y0ungeunii/radial-tangential_fiber_systems_in_swm/blob/main/notebooks/4_grp-variogram.ipynb)
### Variogram analysis of functional organization and radial-tangential fiber predominance
* Compute whole-brain variograms to characterize the spatial organization of functional similarity.
* Perform vertex-wise variogram analysis and generate maps of the variogram sill and range.
* Compute a radial-tangential fiber predominance map and investigate its relationship with variogram metrics.

