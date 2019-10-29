# HKURA: The Hong Kong University Radiomics Archive v0.9

## Extract radiomic featuresets from multiples software projects
Compute features from images and region-of-interest masks using feature implemented in PyRadiomics, CGITA, IBEX and more.

### Current featuresets:
- [CERR](https://github.com/cerr/CERR)
- [CGITA](https://code.google.com/archive/p/cgita/)
- [IBEX](https://www.dropbox.com/sh/50npygy8q8nbn98/AABbtciEvb7fSO_ZhNIQt3jXa?dl=0)
- [Radiomics toolbox (by M.Vallieres et al.)](https://github.com/mvallieres/radiomics)
- [Pyradiomics](https://github.com/Radiomics/pyradiomics)

Reproduce analyses using their original settings files, or combine multiple libraries to generate new high-dimensional radiomics.

## Features defined with respect to a common standard
Our meta-documentation annotates each feature by referencing the International Biomarker Standardization Initiative (IBSI). This information is available in the form of excel spreadsheets and an R package. Just call `library(chiu.hku.hkura)` in R, after installing the source package, to start reporting your analyses using IBSI standard terminology. 

Note that some features may not have an IBSI definition. In non-obvious cases we will record the reason. The tables are available in the ["IBSI"](../../tree/master/IBSI) folder.

## Installation
To use MATLAB functions, their m-files and dependencies must be on the MATLAB path. Simply add the folder named HKURA (and subfolders) to your path and the functions will be available.

An extra requirement is needed to make PyRadiomics features work: Python and pyradiomics need to be installed (see their respective instructions). 
To test if your MATLAB program can find your Python interpreter, type `pyenv` in the MATLAB console. 
If it can't find Python try `pyenv('Version',exepath)` where `exepath` is the string path to the Python interpreter (see relevant MATLAB documentation [here](https://www.mathworks.com/help/matlab/matlab_external/install-supported-python-implementation.html)). 

The code is structured to have one folder per platform featureset, so a user may opt to install only selected platform folders.
 

## Usage
Features can be generated using the function `[X]Features` where `[X]` is the name of the platform, e.g. `ibexFeatures(image, mask)`  takes a single image and/or mask, and optional settings. See the function documentation (`help hkuradiomics`) and the examples in the ["examples"](../../tree/master/examples) folder.

## Developers
- [Jurgen van Lunenburg](https://github.com/jvanlunenburg)<sup>1</sup>
- Collaborators are welcome

<sup>1</sup>Department of Diagnostic Radiology, The University of Hong Kong, Hong Kong SAR.

## Contact
Please contact the corresponding author from the linked publication or open an issue in the appropriate Github panel.

