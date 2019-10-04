function [names, features] = cerrFeatures(I,M)
% features is a 1xN cell array of scalars
% names is a 1xN cell array of strings, formatted for table() compatibility
% Arguments are 3D image I and 3D contigous mask M.
% Assumes M is binary, I is type double (integer I might work too). 

%--- Return dummy data
%     load('cerr_dummy_features'); warning('Using dummy data'); return

%--- Load settings
paramFileName = 'all_features_quantized.json'; %not using structurename
paramS      = getRadiomicsParamTemplate(paramFileName); 
paramS.toQuantizeFlag = true;

%--- CERR Feature extraction
[volToEval, maskBoundingBox3M, gridS] =  preProcessForRadiomics(I, M);
features = calcRadiomicsForImgType(volToEval,maskBoundingBox3M,paramS,gridS);
%features.Original is a struct with 9 fields:
% 1 firstOrderS
% 2 shapeS
% 3 glcmFeatS
% 4 rlmFeatS
% 5 ngtdmFeatS
% 6 ngldmFeatS
% 7 szmFeatS
% 8 peakValleyFeatureS
% 9 ivhFeaturesS


%--- Parse CERR feature struct
% Rules for valid variable names: 
% 1. Can only have letters, number and underscores in a variable name. Nothing else is allowed.
% 2. Variable names have to start with a letter.
% 3. Variable names can be up to 63 characters long.
% 4. Duplicate feature names: all except first get category name appended e.g. entropy_ngldmFeatS
%       (Consider appending category to all names instead?)
features    = struct_flatten(features); %recursively flatten into 100+ feature fields
features    = rmfield(features,{'radius','radiusUnit'}); %not scalars
names       = transpose(fieldnames(features));
features    = transpose(struct2cell(features));

%-----------------------------------------
%-----------------------------------------
    


end
