function [sData] = readDICOMdir(imagepath, roipath)
% -------------------------------------------------------------------------
% function [sData] = readDICOMdir(imagepath, roipath)
% -------------------------------------------------------------------------
% DESCRIPTION: 
% This function reads the DICOM content of a single directory. It then 
% organizes the data it in a cell of structures called 'sData', and 
% computes the region of interest (ROI) defined by a given RTstruct (if 
% present in the directory).
% -------------------------------------------------------------------------
% INPUTS:
% - imagepath: Full path to *folder* where the DICOM files to read are located.
% - roipath: Full path to *file* where the RTSTRUCT dcm file is located.
% -------------------------------------------------------------------------
% OUTPUTS:
% - sData: Cell of structures organizing the content of the volume data, 
%          DICOM headers, DICOM RTstruct* (used to compute the ROI) and 
%          DICOM REGstruct* (used to register a MRI volume to a PET volume)
%          * If present in the directory
%    --> sData{1}: Explanation of cell content
%    --> sData{2}: Imaging data and ROI defintion (if applicable)
%    --> sData{3}: DICOM headers of imaging data
%    --> sData{4}: DICOM RTstruct (if applicable)
%    --> sData{5}: DICOM REGstruct (if applicable)
% -------------------------------------------------------------------------
% AUTHOR(S): 
% - Martin Vallieres <mart.vallieres@gmail.com>
% - Sebastien Laberge <sebastien.laberge.3000@gmail.com>
% - Edited by: J.T.J. van Lunenburg (jurgen@hku.hk)
%--------------------------------------------------------------------------
% STATEMENT:
% This file is part of <https://github.com/mvallieres/radiomics/>, 
% a package providing MATLAB programming tools for radiomics analysis.
% --> Copyright (C) 2015  Martin Vallieres, Sebastien Laberge
%
%    This package is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    This package is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this package.  If not, see <http://www.gnu.org/licenses/>.
% -------------------------------------------------------------------------


% INITIALIZATION
elements = dir(imagepath);
nElements = length(elements);
volume = cell(1,1,nElements);
dicomHeaders = [];
RTstruct = dicominfo(roipath);
assert(strcmp(RTstruct.Modality, 'RTSTRUCT'), "roi file is not an rtstruct dicom");
REG = [];


% READING DIRECTORY CONTENT
sliceNumber = 0;
for elementNumber = 1:nElements
    elementName = elements(elementNumber).name;
    if ~strcmp(elementName,'.') && ~strcmp(elementName,'..') % Good enough for Linux, add conditions for MAC and Windows.
        elementFullFile = fullfile(imagepath,elementName);
        if isdicom(elementFullFile)
            tmp = dicominfo(elementFullFile);
            if strcmp(tmp.Modality,'REG')
                REG = tmp;
            elseif strcmp(tmp.Modality,'MR') || strcmp(tmp.Modality,'PT') || strcmp(tmp.Modality,'CT')
                sliceNumber = sliceNumber + 1;
                volume{sliceNumber} = double(dicomread(elementFullFile));
                dicomHeaders = appendStruct(dicomHeaders,tmp);
            end
        end
    end
end
nSlices = sliceNumber; % Total number of slices
volume = volume(1:nSlices); % Suppress empty cells in images


% DETERMINE THE SCAN ORIENTATION
dist = [abs(dicomHeaders(2).ImagePositionPatient(1) - dicomHeaders(1).ImagePositionPatient(1)), ...
        abs(dicomHeaders(2).ImagePositionPatient(2) - dicomHeaders(1).ImagePositionPatient(2)), ...
        abs(dicomHeaders(2).ImagePositionPatient(3) - dicomHeaders(1).ImagePositionPatient(3))];
[~,index] = max(dist);
if index == 1
    orientation = 'Sagittal';
elseif index == 2
    orientation = 'Coronal';
else
    orientation = 'Axial';
end


% SORT THE IMAGES AND DICOM HEADERS
slicePositions = zeros(1,nSlices);
for sliceNumber = 1:nSlices
    slicePositions(sliceNumber) = dicomHeaders(sliceNumber).ImagePositionPatient(index);
end
[~,indices] = sort(slicePositions);
volume = cell2mat(volume(indices));
dicomHeaders = dicomHeaders(indices);


% FILL sData
sData = cell(1,5);
type = dicomHeaders(1).Modality;
if strcmp(type,'PT') || strcmp(type,'CT')
    if strcmp(type,'PT')
        type = 'PET';
    end
    for i=1:size(volume,3)
        volume(:,:,i)=volume(:,:,i)*dicomHeaders(i).RescaleSlope + dicomHeaders(i).RescaleIntercept;
    end
end
type = [type,'scan'];
sData{1} = struct('Cell_1','Explanation of cell content', ...
                  'Cell_2','Imaging data and ROI defintion (if applicable)', ...
                  'Cell_3','DICOM headers of imaging data', ...
                  'Cell_4','DICOM RTstruct (if applicable)', ...
                  'Cell_5','DICOM REGstruct (if applicable)');

sData{2}.scan.volume = volume;
sData{2}.scan.orientation = orientation;
try sData{2}.scan.pixelW = dicomHeaders(1).PixelSpacing(1); catch, sData{2}.scan.pixelW = []; end % Pixel Width
try sData{2}.scan.sliceT = dicomHeaders(1).SliceThickness; catch, sData{2}.scan.sliceT = []; end % Slice Thickness
s1 = round(0.5*nSlices); s2 = round(0.5*nSlices) + 1; % Slices selected to calculate slice spacing
sData{2}.scan.sliceS = sqrt(sum((dicomHeaders(s1).ImagePositionPatient - dicomHeaders(s2).ImagePositionPatient).^2)); % Slice Spacing
sData{2}.type = type;
sData{3} = dicomHeaders;
sData{4} = RTstruct;
sData{5} = REG;


% COMPUTE TUMOR DELINEATION USING RTstruct
if ~isempty(sData{4})
    [sData] = computeROI(sData);
end


end


% UTILITY FUNCTION
function [structureArray] = appendStruct(structureArray,newStructure)

if isempty(structureArray)
    structureArray = newStructure;
    return
end

structLength = length(structureArray);
fields = fieldnames(structureArray(1));
nFields = length(fields);

for i = 1:nFields
    try
        structureArray(structLength + 1).(fields{i}) = newStructure.(fields{i});
    catch
        structureArray(structLength + 1).(fields{i}) = 'FIELD NOT PRESENT';
    end
end

end

function [sData] = computeROI(sData)
% -------------------------------------------------------------------------
% function [sData] = computeROI(sData)
% -------------------------------------------------------------------------
% DESCRIPTION: 
% This function computes the region of interest (ROI) defined by a given 
% RTstruct in a 'sData' file.
% -------------------------------------------------------------------------
% INPUTS: 'sData' file
% -------------------------------------------------------------------------
% OUTPUTS: 'sData' file with ROI definition
% -------------------------------------------------------------------------
% AUTHOR(S): Martin Vallieres <mart.vallieres@gmail.com>
% -------------------------------------------------------------------------
% HISTORY:
% - Creation: May 2015
%--------------------------------------------------------------------------
% STATEMENT:
% This file is part of <https://github.com/mvallieres/radiomics/>, 
% a package providing MATLAB programming tools for radiomics analysis.
% --> Copyright (C) 2015  Martin Vallieres
% 
%    This package is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    This package is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this package.  If not, see <http://www.gnu.org/licenses/>.
% -------------------------------------------------------------------------


% INITIALIZATION
sizeScan = size(sData{2}.scan.volume);
sData{2}.scan.contour.name     = [];
sData{2}.scan.contour.boxBound = [];
sData{2}.scan.contour.boxMask  = [];
if strcmp(sData{2}.scan.orientation,'Sagittal') 
    a = 2;
    b = 3;
elseif strcmp(sData{2}.scan.orientation,'Coronal')
    a = 1;
    b = 3;
else 
    a = 1;
    b = 2;
end


% ROI COMPUTATION
nContours = length(fieldnames(sData{4}.ROIContourSequence));
for contourNumber = 1:nContours
    
    % Initialization
    mask = zeros(sizeScan);
    itemContour = ['Item_',num2str(contourNumber)];
    sData{2}.scan.contour(contourNumber).name = sData{4}.StructureSetROISequence.(itemContour).ROIName;
    nSlices = length(fieldnames(sData{4}.ROIContourSequence.(itemContour).ContourSequence));
    
    for sliceNumber = 1:nSlices
        
        % Find slice correspondence between volume and RTstruct
        itemSlice = ['Item_',num2str(sliceNumber)];
        UIDrt = sData{4}.ROIContourSequence.(itemContour).ContourSequence.(itemSlice).ContourImageSequence.Item_1.ReferencedSOPInstanceUID;
        for i = 1:sizeScan(3)
            UIDslice = sData{3}(i).SOPInstanceUID;
            if strcmp(UIDrt,UIDslice)
                sliceOK = i;
                break
            end
        end
        
        pts_temp = sData{4}.ROIContourSequence.(itemContour).ContourSequence.(itemSlice).ContourData; % points stored in the RTstruct file
        if ~isempty(pts_temp)
            
            % Get XYZ points in the reference frame coordinates
            ind = 1:numel(pts_temp)/3;
            pts = zeros([numel(pts_temp)/3,3]);
            pts(:,1) = pts_temp(ind*3-2); pts(:,2) = pts_temp(ind*3-1); pts(:,3) = pts_temp(ind*3);
            pts(:,1) = pts(:,1) - sData{3}(sliceOK).ImagePositionPatient(1);
            pts(:,2) = pts(:,2) - sData{3}(sliceOK).ImagePositionPatient(2);
            pts(:,3) = pts(:,3) - sData{3}(sliceOK).ImagePositionPatient(3);

            % Get transformation matrix
            p1 = sData{3}(sliceOK).PixelSpacing(1);
            p2 = sData{3}(sliceOK).PixelSpacing(2);
            m = [sData{3}(sliceOK).ImageOrientationPatient(a)*p1 sData{3}(sliceOK).ImageOrientationPatient(a+3)*p2; ...
            sData{3}(sliceOK).ImageOrientationPatient(b)*p1 sData{3}(sliceOK).ImageOrientationPatient(b+3)*p2];

            % Transform points from reference frame to image coordinates
            pts = ((m^-1)*pts(:,[a,b])')' + 1; % +1 for MATLAB image coordinates

            % Obtain mask using set of image points
            mask(:,:,sliceOK) = or(mask(:,:,sliceOK),poly2mask(pts(:,1),pts(:,2),sizeScan(1),sizeScan(2)));
        else
            mask(:,:,sliceOK) = zeros(sizeScan(1),sizeScan(2));
        end
    end
    
    % Compute the smallest box containing the whole tumor (and its associated bounds)
    [boxBound] = computeBoundingBox(mask);
    bbmask = mask(boxBound(1,1):boxBound(1,2),boxBound(2,1):boxBound(2,2),boxBound(3,1):boxBound(3,2));
    sData{2}.scan.contour(contourNumber).boxBound = boxBound;
    sData{2}.scan.contour(contourNumber).boxMask = bbmask;
    sData{2}.scan.contour(contourNumber).Mask = mask;
end

end

function [boxBound] = computeBoundingBox(mask)
% -------------------------------------------------------------------------
% function [boxBound] = computeBoundingBox(mask)
% -------------------------------------------------------------------------
% DESCRIPTION: 
% This function computes the smallest box containing the whole region of 
% interest (ROI). It is adapted from the function compute_boundingbox.m
% of CERR <http://www.cerr.info/>.
% -------------------------------------------------------------------------
% INPUTS:
% - mask: 3D array, with 1's inside the ROI, and 0's outside the ROI.
% -------------------------------------------------------------------------
% OUTPUTS:
% - boxBound: Bounds of the smallest box containing the ROI. 
%             Format: [minRow, maxRow;
%                      minColumn, maxColumns;
%                      minSlice, maxSlice]
% -------------------------------------------------------------------------
% AUTHOR(S): 
% - Martin Vallieres <mart.vallieres@gmail.com>
% - CERR development team <http://www.cerr.info/>
% -------------------------------------------------------------------------
% HISTORY:
% - Creation: May 2015
%--------------------------------------------------------------------------
% STATEMENT:
% This file is part of <https://github.com/mvallieres/radiomics/>, 
% a package providing MATLAB programming tools for radiomics analysis.
% --> Copyright (C) 2015  Martin Vallieres
% --> Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team
% 
%    This package is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    This package is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this package.  If not, see <http://www.gnu.org/licenses/>.
% -------------------------------------------------------------------------

[iV,jV,kV] = find3d(mask);
boxBound(1,1) = min(iV);
boxBound(1,2) = max(iV);
boxBound(2,1) = min(jV);
boxBound(2,2) = max(jV);
boxBound(3,1) = min(kV);
boxBound(3,2) = max(kV);

end


% CERR UTILITY FUNCTIONS (can be found at: https://github.com/adityaapte/CERR)
function [iV,jV,kV] = find3d(mask3M)
indV = find(mask3M(:));
[iV,jV,kV] = fastind2sub(size(mask3M),indV);
iV = iV';
jV = jV';
kV = kV';
end

function varargout = fastind2sub(siz,ndx)
nout = max(nargout,1);
if length(siz)<=nout,
  siz = [siz ones(1,nout-length(siz))];
else
  siz = [siz(1:nout-1) prod(siz(nout:end))];
end
n = length(siz);
k = [1 cumprod(siz(1:end-1))];
ndx = ndx - 1;
for i = n:-1:1,
  varargout{i} = floor(ndx/k(i)) + 1;
  ndx = ndx - (varargout{i}-1) * k(i);
end
end