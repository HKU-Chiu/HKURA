function [names, features] = allFeatures(im, mask, settings)
%Concatenated output of all HKURA featuresets
%   Order: cgita, cerr, ibex, mval, pyrad
[cgitanames, cgitafeatures] = cgitaFeatures(im, mask, settings.cgita);
[cerrnames, cerrfeatures] = cerrFeatures(im, mask, settings.cerr);
[ibexnames, ibexfeatures] = ibexFeatures(im, mask, settings.ibex);
[mvalnames, mvalfeatures] = mvalFeatures(im, mask, settings.mvalradiomics);
[pyradnames, pyradfeatures] = pyradFeatures(im, mask, settings.pyradiomics);

names = ["cgita_" + cgitanames, "cerr_" + cerrnames, "ibex_" + ibexnames, "mval_" + mvalnames, "pyrad_" + pyradnames];
features = [cgitafeatures, cerrfeatures, ibexfeatures, mvalfeatures, pyradfeatures];
end

