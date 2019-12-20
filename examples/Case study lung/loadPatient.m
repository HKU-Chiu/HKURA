function [image, mask] = loadPatient(patient)
% Load the 3D image matrices denoted by the patient roi and image fields. 
%
% [image, mask] = loadPatient(patient)
%
% patient is a struct with image and roi fields (see load_lungradiomics).
%
% There are currently two loading methods based on github code by Vallieres
% and Geurts. Each loader produces matching image-mask orientations, but
% the two loaders are flipped & rotated with respect to eachother.
%
% Function will error if a patient with a roi has a blank or wrong sized
% mask

skiproi = isempty(patient.roi);

try %mvalloader
    if ~skiproi
        imcells = readDICOMdir(patient.image, patient.roi);
        mask = imcells{2}.scan.contour.Mask;
        image = imcells{2}.scan.volume;
    else
        image = squeeze(dicomreadVolume(patient.image)); %assuming: no color
    end
catch %geurtsloader
    imstruct = loadRThelper(patient.image, true); %true flag: uses Geurts loading implementation (flipped and rotated w.r.t. MATLAB loader), false: no data
    image = imstruct.data;
    if ~skiproi
        roistruct = loadRT(patient.roi, imstruct);
        mask = roistruct{1}.mask; %assuming single roi
    end
end

if ~skiproi
    assert(any(mask(:)),'CUSTOM:loadfail', 'Empty mask not expected');
	assert(isequal(size(image), size(mask)),'CUSTOM:loadfail','Mask size unequal to image');
end

if (nargout == 2) && skiproi % if two outputs are expected from a patient without a roi, a blank mask is returned.
	mask = zeros(size(image));
end

end



