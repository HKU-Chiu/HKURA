function imstruct = loadRThelper(path, varargin)
%
% The following variables are returned upon succesful completion:
%   image: structure containing the image data, dimensions, width, type,
%       start coordinates, and key DICOM header values. The data is a three 
%       dimensional array of image values, while the dimensions, width, and 
%       start fields are three element vectors.  The DICOM header values 
%       are returned as a strings.
%
% Usage: imstruct = loadRThelper(path[, dataflag])
% path is to the folder containing the dcm files
% dataflag is an optional boolean to return the 3D image data.

if nargin > 1
    dataflag = varargin{1};
    assert(islogical(dataflag), "second argument must be a boolean");
else
    dataflag = false;
end

dcmfiles = getFullFiles(path);
info = dicominfo(dcmfiles{1});
N = numel(dcmfiles);

imstruct.classUID = info.SOPClassUID;
imstruct.studyUID = info.StudyInstanceUID;
imstruct.seriesUID = info.SeriesInstanceUID;
imstruct.frameRefUID = info.FrameOfReferenceUID;
imstruct.patientName = robustgetfield(info,"PatientName");
imstruct.patientID = robustgetfield(info,"PatientID");
imstruct.patientBirthDate = robustgetfield(info,"PatientBirthDate");
imstruct.patientSex = robustgetfield(info,"PatientSex");
imstruct.patientAge = robustgetfield(info,"PatientAge");
imstruct.dimensions = double([info.Width, info.Height, N]);
imstruct.width = ([info.PixelSpacing; info.SliceThickness] / 10)'; %mm to cm
imstruct.position = robustgetfield(info, "PatientPosition");
if isempty(imstruct.position)
    imstruct.position = determinePosition(info);
end

% Set image type based on series description (for MVCTs) or DICOM
% header modality tag (for everything else)
if isfield(info, 'SeriesDescription') && ...
        strcmp(info.SeriesDescription, 'CTrue Image Set')
    imstruct.type = 'MVCT';
else
    imstruct.type = info.Modality;
end

% Can't assume slices are evenly spaced and loaded sequentially
sliceLocations = [];
for i = 1:N
    info = dicominfo(dcmfiles{i});
    sliceLocations(length(sliceLocations)+1) = ...
        info.ImagePositionPatient(3); %#ok<*AGROW>
end


% Retrieve start voxel IEC-X coordinate from DICOM header, in cm
imstruct.start(1) = (info.ImagePositionPatient(1) * ...
    info.ImageOrientationPatient(1))/10;

% Adjust IEC-Z to inverted value, in cm
imstruct.start(2) = -(info.ImagePositionPatient(2) * ...
    info.ImageOrientationPatient(5) + info.PixelSpacing(2) * ...
    (double(info.Height) - 1)) / 10; 

%voxel IEC-Y coordinate depends on slicelocations
if any(strcmp(imstruct.position,["HFS", "HFP"]))
    [~, indices] = sort(sliceLocations, 'descend');
    imstruct.start(3) = -max(sliceLocations) / 10;
elseif any(strcmp(imstruct.position,["FFS", "FSP"]))
    [~,indices] = sort(sliceLocations, 'ascend');
    imstruct.start(3) = min(sliceLocations) / 10;
end

% Compute slice location differences
% widths = diff(sliceLocations(indices));
% 
% % Verify that slice locations do not differ significantly (1%)
% if abs(max(widths) - min(widths))/mean(widths) > 0.01
%     error('Slice positions differ by more than 1%, suggesting variable slice spacing. This is not supported.');
% end
%imstruct.width(3) = abs(mean(widths)) / 10;

%--- Concatenate voxel data with magical logic
if dataflag
    images = [];
    for ii = 1:N
        images(size(images,1)+1,:,:) = dicomread(dcmfiles{ii}); %#ok<*AGROW>
    end

    imstruct.data = zeros(size(images, 3), size(images, 2), size(images, 1), 'uint16');

    for i = 1:N
        % Set the image data based on the index value
        imstruct.data(:, :, i) = single(rot90(permute(images(indices(i), :, :), [2 3 1])));
    end

    imstruct.data = max(imstruct.data, 0); %some DICOM images place voxels outside the field of view to negative values
    imstruct.data = flip(imstruct.data, 1); % Flip images in IEC-X direction
end



function v = robustgetfield(s, f)
if isfield(s, f)
    v = s.(f);
else
    v = {};
end

function pos = determinePosition(info)
% If patient is Head First
if isequal(info.ImageOrientationPatient, [1;0;0;0;1;0]) || ...
        isequal(info.ImageOrientationPatient, [-1;0;0;0;-1;0]) 

    if info.ImageOrientationPatient(5) == 1
        pos = 'HFS';

    elseif info.ImageOrientationPatient(5) == -1
        pos = 'HFP';
    end
    
% Otherwise, if the patient is Feet First
elseif isequal(info.ImageOrientationPatient, [-1;0;0;0;1;0]) || ...
        isequal(info.ImageOrientationPatient, [1;0;0;0;-1;0]) 
    
    if info.ImageOrientationPatient(5) == 1
        pos = 'FFS';
        
    elseif info.ImageOrientationPatient(5) == -1
        pos = 'FFP';
    end   

else
    error("Unknown Position Orientation");
end 

