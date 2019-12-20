function [names, features] = cerrFeatures(I, M, S)
% Get radiomics features matching the cerr application featureset 
%
% [names, features] = cerrFeatures(I, M, S)
%
% features is a 1xN cell array of scalars
% names is a 1xN cell array of strings, formatted for table() compatibility
% Arguments are 3D image I and 3D contigous mask M.
% Assumes M is binary, I is type float or integer.
% S is an optional settings parameter that defaults to "default"
% S has to be either: 1) a struct with a "parameters" field containing valid cerr settings
% or 2) a string "default" or containing the path to a cerr json file).

M = logical(M);

if nargin < 3
    S = "default";
end
 
%--- Load settings if S is a string
if isstring(S)
    S = struct("file", S);
    if strcmpi(S.file, "default")
        S.file = "default_cerrsettings.json";
    end
    S.parameters       = getRadiomicsParamTemplate(S.file); 
    S.parameters .toQuantizeFlag = true;
end

%--- CERR Feature extraction
[volToEval, maskBoundingBox3M, gridS] =  preProcessForRadiomics(I, M);
features = calcRadiomicsForImgType(volToEval, maskBoundingBox3M, S.parameters , gridS);
%features.Original is a nested struct with 9 fields:
% 1 firstOrderS
% 2 shapeS
% 3 glcmFeatS
% 4 rlmFeatS
% 5 ngtdmFeatS
% 6 ngldmFeatS
% 7 szmFeatS
% 8 peakValleyFeatureS
% 9 ivhFeaturesS


%--- Parse CERR feature struct into two 1xn cell rows
% Rules for valid variable names: 
% 1. Can only have letters, number and underscores in a variable name. Nothing else is allowed.
% 2. Variable names have to start with a letter.
% 3. Variable names can be up to 63 characters long.
% 4. Duplicate feature names: all except first get category name appended e.g. entropy -> entropy_ngldmFeatS
%       (Consider appending category to all names instead?)
features    = struct_flatten(features); %recursively flatten into 100+ feature fields
features    = rmfield(features,{'radius','radiusUnit'}); %not scalars
names       = transpose(fieldnames(features));
features    = transpose(struct2cell(features));

%-----------------------------------------
%-----------------------------------------
    


end
