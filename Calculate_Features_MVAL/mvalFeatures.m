function [names, features] = mvalFeatures(I, M, S)
% features is a 1xN cell array of scalars
% names is a 1xN cell array of strings, formatted for table() compatibility
% Arguments are 3D image I and 3D contigous mask M.
% Assumes M is binary, I is type double (integer I might work too). 

%--- Pre-processing
% Author states that volume should be isotropic, so scaling is done.
if nargin < 3
    S = loadSettings("mval", []);
    S = S.mvalradiomics;
end
param = S.parameters;

GROI = prepareVolume(I, M, 'CT',  param.planeRes, param.sliceRes,1, param.tgtIsoRes, 'Global');
[ROIonly,levels] = prepareVolume(I, M, 'CT', param.planeRes, param.sliceRes, 1, param.tgtIsoRes, 'Matrix', param.quantization, param.bincount);
GLCM  = getGLCM(ROIonly, levels); 
GLRLM = getGLRLM(ROIonly, levels);
GLSZM = getGLSZM(ROIonly, levels); 
[NGTDM, countValid] = getNGTDM(ROIonly, levels); 

%--- Feature extraction
% Each category function returns a unique struct with features. 
% Would have been smarter to have a struct array with fname/value fields?
globalTextures = getGlobalTextures(GROI, param.bincount);
glcmTextures   = getGLCMtextures(GLCM);
glrlmTextures  = getGLRLMtextures(GLRLM);
glszmTextures  = getGLSZMtextures(GLSZM);
ngtdmTextures  = getNGTDMtextures(NGTDM, countValid);

nonTexture.AUCCSH = getAUCCSH(GROI);
nonTexture.Eccentricity = getEccentricity(GROI,param.planeRes ,param.sliceRes);
[nonTexture.SUVmax, nonTexture.SUVpeak, nonTexture.SUVmean, ~] = getSUVmetrics(GROI);
nonTexture.Size = getSize(GROI,param.planeRes ,param.sliceRes);
nonTexture.Solidity = getSolidity(GROI,param.planeRes ,param.sliceRes);
nonTexture.Volume = getVolume(GROI,param.planeRes ,param.sliceRes);
nonTexture.PecentInactive = getPercentInactive(GROI, 0.1);
%--- Convert structs to table-friendly output format
% Rules for valid variable names: 
% 1. Can only have letters, number and underscores in a variable name. Nothing else is allowed.
% 2. Variable names have to start with a letter.
% 3. Variable names can be up to 63 characters long.
% 4. To avoid duplicate feature names: category name appended

names = [strcat('Nontexture_',fieldnames(nonTexture));...
    strcat('Global_',fieldnames(globalTextures));...
    strcat('GLCM_',fieldnames(glcmTextures));...
    strcat('GLRLM_',fieldnames(glrlmTextures));...
    strcat('GLSZM_',fieldnames(glszmTextures));...
    strcat('NGTDM_',fieldnames(ngtdmTextures))];

features = [struct2cell(nonTexture);...
    struct2cell(globalTextures);...
    struct2cell(glcmTextures);...
    struct2cell(glrlmTextures);...
    struct2cell(glszmTextures);...
    struct2cell(ngtdmTextures)];

names       = transpose(names);
features    = transpose(features);
assert(all(cellfun(@isscalar,features)),'Features has non-scalars?!'); %sanity check

%-----------------------------------------
%-----------------------------------------
    


end
