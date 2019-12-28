[im, mask] = loadPatient(patient);

settings64 = loadSettings("all");

%Derive new settings from default struct, ensuring feature QQQQ has 128
%bins, all other settings same.
settings128 = settings64;
settings128.cgita.parameters.digitization_bins = 128;
settings128.ibex.parameters.FeatureSetsInfo(4).CategoryStore.Value.NumLevels = 128; %note the settings in ibex are more granular: per category.
settings128.cerr.parameters.textureParamS.numGrLevels = 128;
settings128.pyradiomics.parameters.bincount = 128;
settings128.mvalradiomics.parameters.bincount = 128;

%--- Radiomics
[names, features] = allFeatures(im, mask, settings64); %row 1
[names2, features2] = allFeatures(im, mask, settings128); %row 2

%--- Write to file
assert(all(string(names) == string(names2)), "Sanity check failed, settings produce incomparible names?");
t = cell2table([features; features2], "Variablenames", names); %if names error due to length, use names V1:Vn and copy paste 'names' into excel
writetable(t, "singlepatient2settings.xlsx",'FileType','spreadsheet');