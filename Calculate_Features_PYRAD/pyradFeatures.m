function [names, values] = pyradiomicsFeatures(im, mask, S)
% Usage: [names, values] = pyradiomicsFeatures(im, mask, S)
% values is a 1xN cell array of scalars
% names is a 1xN array of strings
% Arguments are 3D image, 3D contigous mask, settings datastructure.
% Assumes M is binary, I is type double (integer I might work too). 
%
% This function requires a working python/pyradiomics installation
% accessible from MATLAB. Writes temporary files to pwd.
if nargin < 3
    S = "default";
end
if isstring(S)
    S = loadSettings("pyradiomics", S).pyradiomics;
end


%--- save im and mask to simpleITK compatible filetypes.  
%avoid DICOM. Try nifti.or nrrd
imageName = fullfile(pwd, "tempimg.nii");
maskName = fullfile(pwd, "tempmask.nii");
niftiwrite(im, imageName);
niftiwrite(uint8(mask), maskName); %must be numeric

%--- Create extractor and execute with filenames
extractor = py.radiomics.featureextractor.RadiomicsFeatureExtractor(S.parameters.kwa);
featureVector = extractor.execute(imageName, maskName); 

%--- Parse output dictionary
firstidx = 23; %addProvenance(provenance_on=True)
allnames = string(cell(py.list(featureVector.keys))); %may contain hyphens, spaces and dots?
names = allnames(firstidx:end); 

allvalues = cell(py.list(featureVector.values));
values = allvalues(firstidx:end);
values = cellfun(@double, values, 'Uni', false); %works in 2020a, not in 2018b
%values = cellfun(@(x) double(py.array.array('d', py.numpy.nditer(x))), values, 'Uni', false); %convert to matlab doubles


assert(all(cellfun(@isscalar, values)),'Features has non-scalars?!'); %sanity check


end

