%Add the library folder for the CERR featureset to the MATLAB path, then:

%load some data
im   = niftiread("sampleimg.nii"); %or any other data. This Nifti file is loaded via the image processing toolbox.
mask = logical(niftiread("samplemask.nii"));

%extract features
[names, features] = cerrFeatures(im, mask);

%Output to xlsx
t = cell2table(features, 'Variablenames', names);
writetable(t, "mydata",'FileType','spreadsheet');

%Merge IBSI meta-labels using your preferred software. In the future the extraction functions will have the option to include this in directly the output.

%ditto for ibexFeatures, cgitaFeatures, mvalFeatures, pyradFeatures