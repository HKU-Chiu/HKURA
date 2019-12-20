function [names, values] = pyradiomicsFeatures(im, mask, S)
% features is a 1xN cell array of scalars
% names is a 1xN cell array of strings, formatted for table() compatibility
% Arguments are 3D image I and 3D contigous mask M.
% Assumes M is binary, I is type double (integer I might work too). 


%--- save im and mask to simpleITK compatible filetypes.  
%avoid DICOM. Try nifti.or nrrd
imageName = fullfile(pwd, "tempimg.nii");
maskName = fullfile(pwd, "tempmask.nii");
niftiwrite(im, imageName);
niftiwrite(uint8(mask), maskName); %must be numeric
% imageName = 'C:\\Users\\Jurgen\\AppData\\Local\\Temp\\pyradiomics\\data\\brain1_image.nrrd';
% maskName = 'C:\\Users\\Jurgen\\AppData\\Local\\Temp\\pyradiomics\\data\\brain1_label.nrrd';

%--- Create extractor and execute with filenames
kwa = pyargs('binCount', uint8(S.parameters.bincount));
extractor = py.radiomics.featureextractor.RadiomicsFeatureExtractor(kwa);
featureVector = extractor.execute(imageName, maskName); 

%--- Parse output dictionary
firstidx = 23; %fixed? or does preamble change, relative to input?

allvalues = cell(py.list(featureVector.values));
values = allvalues(firstidx:end);
values = cellfun(@(x) double(py.array.array('d', py.numpy.nditer(x))), values, 'Uni', false); %convert to matlab doubles

% Rules for valid variable names: 
% 1. Can only have letters, number and underscores in a variable name. Nothing else is allowed.
% 2. Variable names have to start with a letter.
% 3. Variable names can be up to 63 characters long.
allnames = string(cell(py.list(featureVector.keys))); %may contain hyphens, spaces and dots?
names = allnames(firstidx:end); 
names = replace(names, [" ","-","."], ["_", "", ""]);

assert(all(cellfun(@isscalar, values)),'Features has non-scalars?!'); %sanity check


end

